local M = {}
local import_prefix = 'outline/providers/'

---@return outline.Provider?, table?
function M.find_provider()
  local configs = require('outline.config').o.providers

  if not M.providers then
    M.providers = vim.tbl_map(function(p)
      return import_prefix .. p
    end, require('outline.config').get_providers())
  end

  for _, path in ipairs(M.providers) do
    local provider = require(path)
    local ok, info = provider.supports_buffer(0, configs[provider.name])
    if ok then
      return provider, info
    end
  end
end

---@return boolean found_provider
function M.has_provider()
  return M.find_provider() ~= nil
end

---Call `sidebar.provider[method]` with args. NOP if no provider or no defined `method`
---@param sidebar outline.Sidebar
---@param method string
---@param args any[]
function M.action(sidebar, method, args)
  if not sidebar.provider or not sidebar.provider[method] then
    require('outline.utils').echo('No supported providers to perform this action.')
    return
  end
  local ok = sidebar.provider[method](unpack(args))
  if not ok then
    require('outline.utils').echo('The provider could not perform this action successfully.')
  end
end

return M
