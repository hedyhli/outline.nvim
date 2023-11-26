local config = require('outline.config')
local jsx = require('outline.providers.jsx')
local lsp_utils = require('outline.utils.lsp')

local M = {
  name = 'lsp',
  ---@type vim.lsp.client
  client = nil,
}

function M.get_status()
  if not M.client then
    return { 'No clients' }
  end
  return { 'client: ' .. M.client.name }
end

local function get_appropriate_client(bufnr, capability)
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  local use_client

  for _, client in ipairs(clients) do
    if config.is_client_blacklisted(client) then
      goto continue
    else
      if client.server_capabilities[capability] then
        use_client = client
        M.client = client
        break
      end
    end
    ::continue::
  end
  return use_client
end

---@return boolean
function M.supports_buffer(bufnr)
  local client = get_appropriate_client(bufnr, 'documentSymbolProvider')
  if not client then
    return false
  end
  return true
end

---@param response outline.ProviderSymbol[]
---@return outline.ProviderSymbol[]
local function postprocess_symbols(response)
  local symbols = lsp_utils.flatten_response(response)

  local jsx_symbols = jsx.get_symbols()

  if #jsx_symbols > 0 then
    return lsp_utils.merge_symbols(symbols, jsx_symbols)
  else
    return symbols
  end
end

---@param on_symbols fun(symbols?:outline.ProviderSymbol[], opts?:table)
---@param opts table
function M.request_symbols(on_symbols, opts)
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(),
  }
  vim.lsp.buf_request_all(0, 'textDocument/documentSymbol', params, function(response)
    response = postprocess_symbols(response)
    on_symbols(response, opts)
  end)
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
    vim.lsp.buf.code_action()
  end)
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
  local timeout = 2000
  local status, err = client.request_sync('textDocument/rename', params, timeout, sidebar.code.buf)
  if status == nil or status.err or err or status.result == nil then
    return false
  end

  vim.lsp.util.apply_workspace_edit(status.result, client.offset_encoding)
  node.name = new_name
  sidebar:_update_lines(false)
  return true
end

function M.hover_info(bufnr, params, on_info)
  local use_client = get_appropriate_client(bufnr, 'hoverProvider')

  if not use_client then
    on_info(nil, {
      contents = {
        kind = 'markdown',
        content = { 'No extra information availaible' },
      },
    })
    return
  end

  use_client.request('textDocument/hover', params, on_info, bufnr)
end

return M
