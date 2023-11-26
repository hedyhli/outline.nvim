local M = {}
local cfg = require('outline.config')

---@param node outline.Symbol|outline.FlatSymbol
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

---@param node outline.Symbol|outline.FlatSymbol
function M.is_folded(node)
  local hover = cfg.o.symbol_folding.auto_unfold_hover
  local only = cfg.o.symbol_folding.auto_unfold.only

  if node.folded ~= nil then
    return node.folded
  elseif node.parent.is_root and node.parent.child_count <= only then
    return false
  elseif node.hovered and hover then
    return false
  else
    return get_default_folded(node.depth)
  end
end

return M
