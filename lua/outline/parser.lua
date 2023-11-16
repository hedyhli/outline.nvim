local symbols = require 'outline.symbols'
local ui = require 'outline.ui'
local cfg = require 'outline.config'
local t_utils = require 'outline.utils.table'
local lsp_utils = require 'outline.utils.lsp_utils'
local folding = require 'outline.folding'

local M = {}

---Parses result from LSP into a reorganized tree of symbols (not flattened,
-- simply reoganized by merging each property table from the arguments into a
-- table for each symbol)
---@param result table The result from a language server.
---@param depth number? The current depth of the symbol in the hierarchy.
---@param hierarchy table? A table of booleans which tells if a symbols parent was the last in its group.
---@param parent table? A reference to the current symbol's parent in the function's recursion
---@param bufnr integer The buffer number which the result was from
---@return outline.SymbolNode[]
local function parse_result(result, depth, hierarchy, parent, bufnr)
  local ret = {}

  for index, value in pairs(result) do
    -- FIXME: If a parent was excluded, all children will not be considered
    if cfg.should_include_symbol(symbols.kinds[value.kind], bufnr) then
      -- the hierarchy is basically a table of booleans which
      -- tells whether the parent was the last in its group or
      -- not
      local hir = hierarchy or {}
      -- how many parents this node has, 1 is the lowest value because its
      -- easier to work it
      local level = depth or 1
      -- whether this node is the last (~born~) in its siblings
      local isLast = index == #result

      local selectionRange = lsp_utils.get_selection_range(value)
      local range = lsp_utils.get_range(value)

      local node = {
        deprecated = value.deprecated,
        kind = value.kind,
        icon = symbols.icon_from_kind(value.kind),
        name = value.name or value.text,
        detail = value.detail,
        line = selectionRange.start.line,
        character = selectionRange.start.character,
        range_start = range.start.line,
        range_end = range['end'].line,
        depth = level,
        isLast = isLast,
        hierarchy = hir,
        parent = parent,
        traversal_child = 1,
      }

      table.insert(ret, node)

      local children = nil
      if value.children ~= nil then
        -- copy by value because we dont want it messing with the hir table
        local child_hir = t_utils.array_copy(hir)
        table.insert(child_hir, isLast)
        children = parse_result(value.children, level + 1, child_hir, node, bufnr)
      else
        value.children = {}
      end

      node.children = children
    end
  end
  return ret
end

---Sorts and reorganizes the response from lsp request
--'textDocument/documentSymbol', buf_request_all.
---Used when refreshing and setting up new symbols
---@param response table The result from buf_request_all
---@param bufnr integer
---@return outline.SymbolNode[]
function M.parse(response, bufnr)
  local sorted = lsp_utils.sort_symbols(response)

  return parse_result(sorted, nil, nil, nil, bufnr)
end

---Iterator that traverses the tree parent first before children, returning each node.
-- Essentailly 'flatten' items, but returns an iterator.
---@param items outline.SymbolNode[] Tree of symbols parsed by parse_result
---@param children_check function? Takes a node and return whether the children should be explored.
---Note that the root node (param items) is always explored regardless of children_check.
function M.preorder_iter(items, children_check)
  local node = { children = items, traversal_child = 1, depth = 1, is_root = true }
  local prev
  local visited = {}

  if children_check == nil then
    children_check = function(n)
      return not folding.is_folded(n)
    end
  end

  return function()
    while node do
      if node.name and not visited[node] then
        visited[node] = true
        return node
      end

      if
        node.children and node.traversal_child <= #node.children
        and (node.is_root or children_check(node))
      then
        prev = node
        if node.children[node.traversal_child] then
          node.children[node.traversal_child].parent_node = node
          node = node.children[node.traversal_child]
        end
        prev.traversal_child = prev.traversal_child + 1
      else
        node.traversal_child = 1
        node = node.parent_node
      end
    end
  end
end

return M
