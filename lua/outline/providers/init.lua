local M = {}
local import_prefix = 'outline/providers/'

---@return outline.Provider?
function M.find_provider()
  if not M.providers then
    M.providers = vim.tbl_map(function(p)
      return import_prefix .. p
    end, require('outline.config').get_providers())
  end
  for _, path in ipairs(M.providers) do
    local provider = require(path)
    if provider.supports_buffer(0) then
      return provider
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
    return
  end
  return sidebar.provider[method](unpack(args))
end

return M
