local M = {}
local cfg = require('outline.config')

---@param node outline.SymbolNode|outline.FlatSymbolNode
function M.is_foldable(node)
  return node.children and #node.children > 0
end

---@param depth integer
local function get_default_folded(depth)
  local fold_past = cfg.o.symbol_folding.autofold_depth
  if not fold_past then
    return false
  else
    return depth >= fold_past
  end
end

---@param node outline.SymbolNode|outline.FlatSymbolNode
function M.is_folded(node)
  if node.folded ~= nil then
    return node.folded
  elseif node.hovered and cfg.o.symbol_folding.auto_unfold_hover then
    return false
  else
    return get_default_folded(node.depth)
  end
end

return M
