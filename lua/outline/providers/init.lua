local M = {}

local providers = {
  'outline/providers/nvim-lsp',
  'outline/providers/coc',
  'outline/providers/markdown',
}

_G._symbols_outline_current_provider = nil

function M.has_provider()
  local ret = false
  for _, value in ipairs(providers) do
    local provider = require(value)
    if provider.should_use_provider(0) then
      ret = true
      break
    end
  end
  return ret
end

---@param on_symbols function
---@return boolean found_provider
function M.request_symbols(on_symbols, opts)
  for _, value in ipairs(providers) do
    local provider = require(value)
    if provider.should_use_provider(0) then
      _G._symbols_outline_current_provider = provider
      _G._symbols_outline_current_provider.name = value
      provider.request_symbols(on_symbols, opts)
      return true
    end
  end
  return false
end

return M
