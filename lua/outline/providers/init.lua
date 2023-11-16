local cfg = require "outline.config"

local M = {}
local import_prefix = "outline/providers/"

_G._outline_current_provider = nil


function M.find_provider()
  if not M.providers then
    M.providers = vim.tbl_map(function(p) return import_prefix..p end, cfg.get_providers())
  end
  for _, name in ipairs(M.providers) do
    local provider = require(name)
    if provider.should_use_provider(0) then
      return provider, name
    end
  end
  return nil, nil
end

---@return boolean found_provider
function M.has_provider()
  return M.find_provider() ~= nil
end

---@param on_symbols function
---@param opts outline.OutlineOpts?
---@return boolean found_provider
function M.request_symbols(on_symbols, opts)
  local provider, name = M.find_provider()
  if not provider then
    return false
  end
  _G._outline_current_provider = provider
  if not provider.name then
    _G._outline_current_provider.name = name
  end
  provider.request_symbols(on_symbols, opts)
  return true
end

return M
