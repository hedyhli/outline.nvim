local config = require('outline.config')
local jsx = require('outline.utils.jsx')
local lsp_utils = require('outline.utils.lsp_utils')

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

local function get_params()
  return { textDocument = vim.lsp.util.make_text_document_params() }
end

function M.hover_info(bufnr, params, on_info)
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  local use_client

  for _, client in ipairs(clients) do
    if config.is_client_blacklisted(client) then
      goto continue
    else
      if client.server_capabilities.hoverProvider then
        use_client = client
        M.client = client
        break
      end
    end
    ::continue::
  end

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

function M.should_use_provider(bufnr)
  local clients = vim.lsp.get_active_clients({ bufnr = bufnr })
  local ret = false

  for _, client in ipairs(clients) do
    if config.is_client_blacklisted(client) then
      goto continue
    else
      if client.server_capabilities.documentSymbolProvider then
        M.client = client
        ret = true
        break
      end
    end
    ::continue::
  end

  return ret
end

function M.postprocess_symbols(response)
  local symbols = lsp_utils.flatten_response(response)

  local jsx_symbols = jsx.get_symbols()

  if #jsx_symbols > 0 then
    return lsp_utils.merge_symbols(symbols, jsx_symbols)
  else
    return symbols
  end
end

---@param on_symbols function
function M.request_symbols(on_symbols, opts)
  vim.lsp.buf_request_all(0, 'textDocument/documentSymbol', get_params(), function(response)
    response = M.postprocess_symbols(response)
    on_symbols(response, opts)
  end)
end

return M
