local cfg = require('outline.config')
local folding = require('outline.folding')
local lsp_utils = require('outline.utils.lsp')
local symbols = require('outline.symbols')
local utils = require('outline.utils.init')

local M = {}

local function norm_kind(kind)
  if type(kind) == 'number' then
    return kind
  else
    -- string
    return symbols.str_to_kind[kind] or 21 -- fallback to Null
  end
end

---Parses result from LSP into a reorganized tree of symbols (not flattened,
-- simply reoganized by merging each property table from the arguments into a
-- table for each symbol)
---@param result outline.ProviderSymbol The result from a language server.
---@param depth number? The current depth of the symbol in the hierarchy.
---@param hierarchy table? A table of booleans which tells if a symbols parent was the last in its group.
---@param parent table? A reference to the current symbol's parent in the function's recursion
---@param bufnr integer The buffer number which the result was from
---@return outline.Symbol[]
local function parse_result(result, depth, hierarchy, parent, bufnr)
  local ret = {}

  for index, value in pairs(result) do
    -- FIXME: If a parent was excluded, all children will not be considered
    value.kind = norm_kind(value.kind)
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
        icon = symbols.icon_from_kind(value.kind, bufnr, value),
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
        _i = 1,
      }

      table.insert(ret, node)

      local children = nil
      if value.children ~= nil then
        -- copy by value because we dont want it messing with the hir table
        local child_hir = utils.array_copy(hir)
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
---@return outline.Symbol[]
function M.parse(response, bufnr)
  local sorted = lsp_utils.sort_symbols(response)

  return parse_result(sorted, nil, nil, { is_root = true, child_count = #sorted }, bufnr)
end

---Iterator that traverses the tree parent first before children, returning each node.
-- Essentailly 'flatten' items, but returns an iterator.
---@param items outline.Symbol[] Tree of symbols parsed by parse_result
---@param children_check function? Takes a node and return whether the children should be explored.
---Note that the root node (param items) is always explored regardless of children_check.
function M.preorder_iter(items, children_check)
  local node = { children = items, _i = 1, depth = 1, is_root = true }
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

      if node.children and node._i <= #node.children and (node.is_root or children_check(node)) then
        prev = node
        if node.children[node._i] then
          node.children[node._i].parent_node = node
          node = node.children[node._i]
        end
        prev._i = prev._i + 1
      else
        node._i = 1
        node = node.parent_node
      end
    end
  end
end

---Merges a symbol tree recursively, only replacing nodes
---which have changed. This will maintain the folding
---status of any unchanged nodes.
---@param new_node table New node
---@param old_node table Old node
---@param index? number Index of old_item in parent
---@param parent? table Parent of old_item
function M.merge_items_rec(new_node, old_node, index, parent)
  local failed = false

  if not new_node or not old_node then
    failed = true
  else
    for key, _ in pairs(new_node) do
      if
        vim.tbl_contains({
          'parent',
          'children',
          'folded',
          'hovered',
          'line_in_outline',
          'hierarchy',
        }, key)
      then
        goto continue
      end

      if key == 'name' then
        -- in the case of a rename, just rename the existing node
        old_node['name'] = new_node['name']
      else
        if not vim.deep_equal(new_node[key], old_node[key]) then
          failed = true
          break
        end
      end

      ::continue::
    end
  end

  if failed then
    if parent and index then
      parent[index] = new_node
    end
  else
    local next_new_item = new_node.children or {}

    -- in case new children are created on a node which
    -- previously had no children
    if #next_new_item > 0 and not old_node.children then
      old_node.children = {}
    end

    local next_old_item = old_node.children or {}

    for i = 1, math.max(#next_new_item, #next_old_item) do
      M.merge_items_rec(next_new_item[i], next_old_item[i], i, next_old_item)
    end
  end
end

return M
