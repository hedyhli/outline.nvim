local cfg = require('outline.config')
local jsx = require('outline.providers.jsx')
local lsp_utils = require('outline.utils.lsp')

local l = vim.lsp

local M = {
  name = 'lsp',
}

local request_timeout = 2000

---@param info table? Must be the table received from `supports_buffer`
function M.get_status(info)
  if not info then
    return { 'No clients' }
  end
  return { 'client: ' .. info.client.name }
end

---@param client lsp.client
---@param capability string
---@return boolean
local function _check_client(client, capability)
  if cfg.is_client_blacklisted(client) then
    return false
  end
  return client.server_capabilities[capability]
end

---@param bufnr integer
---@param capability string
---@return lsp.client?
local function get_appropriate_client(bufnr, capability)
  local clients, use_client

  if _G._outline_nvim_has[8] then
    if _G._outline_nvim_has[10] then
      clients = l.get_clients({ bufnr = bufnr })
    else
      clients = l.get_active_clients({ bufnr = bufnr })
    end
    for _, client in ipairs(clients) do
      if _check_client(client, capability) then
        use_client = client
        break
      end
    end
  else
    -- Returns client_id:client pairs
    ---@diagnostic disable-next-line
    clients = l.buf_get_clients(bufnr)
    for _, client in pairs(clients) do
      if _check_client(client, capability) then
        use_client = client
        break
      end
    end
  end

  return use_client
end

---@return boolean, table?
function M.supports_buffer(bufnr)
  local client = get_appropriate_client(bufnr, 'documentSymbolProvider')
  if not client then
    return false
  end
  return true, { client = client }
end

---Include JSX symbols if applicable, and merge it with existing symbols
---@param symbols outline.ProviderSymbol[]
---@return outline.ProviderSymbol[]
local function postprocess_symbols(symbols)
  local jsx_symbols = jsx.get_symbols()

  if #jsx_symbols > 0 then
    return lsp_utils.merge_symbols(symbols, jsx_symbols)
  else
    return symbols
  end
end

-- XXX: Only one LSP client is supported here, to prevent checking blacklisting
-- over again
---@param on_symbols fun(symbols?:outline.ProviderSymbol[], opts?:table)
---@param opts table?
---@param info table? Must be the table received from `supports_buffer`
function M.request_symbols(on_symbols, opts, info)
  if not info then
    return on_symbols(nil, opts)
  end

  local params = {
    textDocument = l.util.make_text_document_params(),
  }
  -- XXX: Is bufnr=0 ok here?
  local status = info.client.request('textDocument/documentSymbol', params, function(err, response)
    if err or not response then
      on_symbols(response, opts)
    else
      response = postprocess_symbols(response)
      on_symbols(response, opts)
    end
  end, 0)
  if not status then
    on_symbols(nil, opts)
  end
end

-- No good way to update outline when LSP action complete for now

---@param sidebar outline.Sidebar
---@return boolean success
function M.code_actions(sidebar)
  local client = get_appropriate_client(sidebar.code.buf, 'codeActionProvider')
  if not client then
    return false
  end
  -- NOTE: Unfortunately the code_action function provided by neovim does a
  -- lot, yet it doesn't let us filter clients. Since handling of code_actions
  -- is beyond the scope of outline.nvim itself, we will not respect
  -- blacklist_clients for code actions for now. Code actions feature would not
  -- actually be included if I were to write this plugin from scratch. However
  -- we still keep it because many people are moving here from
  -- symbols-outline.nvim, which happened to implement this feature.
  sidebar:wrap_goto_location(function()
    l.buf.code_action()
  end)
  return true
end

---@see rename_symbol
---@param sidebar outline.Sidebar
---@param client lsp.client
---@param node outline.FlatSymbol
---@return boolean success
local function legacy_rename(sidebar, client, node)
  -- Using fn.input so it's synchronous
  local new_name = vim.fn.input({ prompt = 'New Name: ', default = node.name })
  if not new_name or new_name == '' or new_name == node.name then
    return true
  end

  local params = {
    textDocument = { uri = 'file://' .. vim.api.nvim_buf_get_name(sidebar.code.buf) },
    position = { line = node.line, character = node.character },
    bufnr = sidebar.code.buf,
    newName = new_name,
  }
  local status, err =
    client.request_sync('textDocument/rename', params, request_timeout, sidebar.code.buf)
  if status == nil or status.err or err or status.result == nil then
    return false
  end

  l.util.apply_workspace_edit(status.result, client.offset_encoding)
  node.name = new_name
  sidebar:_update_lines(false)
  return true
end

---Synchronously request rename from LSP
---@param sidebar outline.Sidebar
---@return boolean success
function M.rename_symbol(sidebar)
  local client = get_appropriate_client(sidebar.code.buf, 'renameProvider')
  if not client then
    return false
  end
  local node = sidebar:_current_node()
  if not node then
    return false
  end

  if _G._outline_nvim_has[8] then
    sidebar:wrap_goto_location(function()
      -- Options table with filter key only added in nvim-0.8
      -- Use vim.lsp's function because it has better support.
      l.buf.rename(nil, {
        filter = function(cl)
          return not cfg.is_client_blacklisted(cl)
        end,
      })
    end)
    return true
  else
    return legacy_rename(sidebar, client, node)
  end
end

---Synchronously request and show hover info from LSP
---@param sidebar outline.Sidebar
---@return boolean success
function M.show_hover(sidebar)
  local client = get_appropriate_client(sidebar.code.buf, 'hoverProvider')
  if not client then
    return false
  end

  local node = sidebar:_current_node()
  if not node then
    return false
  end
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(sidebar.code.buf) },
    position = { line = node.line, character = node.character },
    bufnr = sidebar.code.buf,
  }

  local status, err = client.request_sync('textDocument/hover', params, request_timeout)
  if status == nil or status.err or err or not status.result or not status.result.contents then
    return false
  end

  local md_lines = l.util.convert_input_to_markdown_lines(status.result.contents)
  md_lines = l.util.trim_empty_lines(md_lines)
  if vim.tbl_isempty(md_lines) then
    -- Request was successful, but there is no hover content
    return true
  end
  local code_width = vim.api.nvim_win_get_width(sidebar.code.win)
  local bufnr, winnr = l.util.open_floating_preview(md_lines, 'markdown', {
    border = cfg.o.preview_window.border,
    width = code_width,
  })
  vim.api.nvim_win_set_option(winnr, 'winhighlight', cfg.o.preview_window.winhl)
  return true
end

return M
