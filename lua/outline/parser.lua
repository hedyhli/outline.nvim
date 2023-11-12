local symbols = require 'outline.symbols'
local ui = require 'outline.ui'
local cfg = require 'outline.config'
local t_utils = require 'outline.utils.table'
local lsp_utils = require 'outline.utils.lsp_utils'
local folding = require 'outline.folding'

local M = {}

---Parses result from LSP into a table of symbols
---@param result table The result from a language server.
---@param depth number? The current depth of the symbol in the hierarchy.
---@param hierarchy table? A table of booleans which tells if a symbols parent was the last in its group.
---@param parent table? A reference to the current symbol's parent in the function's recursion
---@return table
local function parse_result(result, depth, hierarchy, parent)
  local ret = {}

  for index, value in pairs(result) do
    if not cfg.is_symbol_blacklisted(symbols.kinds[value.kind]) then
      -- the hierarchy is basically a table of booleans which tells whether
      -- the parent was the last in its group or not
      local hir = hierarchy or {}
      -- how many parents this node has, 1 is the lowest value because its
      -- easier to work it
      local level = depth or 1
      -- whether this node is the last in its group
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
      }

      table.insert(ret, node)

      local children = nil
      if value.children ~= nil then
        -- copy by value because we dont want it messing with the hir table
        local child_hir = t_utils.array_copy(hir)
        table.insert(child_hir, isLast)
        children = parse_result(value.children, level + 1, child_hir, node)
      end

      node.children = children
    end
  end
  return ret
end

---Parses the response from lsp request 'textDocument/documentSymbol' using buf_request_all
---@param response table The result from buf_request_all
---@return table outline items
function M.parse(response)
  local sorted = lsp_utils.sort_symbols(response)

  return parse_result(sorted, nil, nil)
end

function M.flatten(outline_items, ret, depth)
  depth = depth or 1
  ret = ret or {}
  for _, value in ipairs(outline_items) do
    table.insert(ret, value)
    value.line_in_outline = #ret
    if value.children ~= nil and not folding.is_folded(value) then
      M.flatten(value.children, ret, depth + 1)
    end
  end

  -- if depth == 1 then
  --   for index, value in ipairs(ret) do
  --     value.line_in_outline = index
  --   end
  -- end

  return ret
end

function M.get_lines(flattened_outline_items)
  local lines = {}
  local hl_info = {}
  local guide_hl_info = {}
  local lineno_max = 0

  for node_line, node in ipairs(flattened_outline_items) do
    local depth = node.depth
    local marker_space = (cfg.o.symbol_folding.markers and 1) or 0

    local line = t_utils.str_to_table(string.rep(' ', depth + marker_space))
    local running_length = 1

    if node.range_start+1 > lineno_max then
      lineno_max = node.range_start+1
    end

    local function add_guide_hl(from, to)
      table.insert(guide_hl_info, {
        node_line,
        from,
        to,
        'OutlineGuides',
      })
    end

    for index, _ in ipairs(line) do
      if cfg.o.guides.enabled then
        local guide_markers = cfg.o.guides.markers
        if index == 1 then
          line[index] = ''
          -- if index is last, add a bottom marker if current item is last,
          -- else add a middle marker
        elseif index == #line then
          -- add fold markers
          local fold_markers = cfg.o.symbol_folding.markers
          if fold_markers and folding.is_foldable(node) then
            if folding.is_folded(node) then
              line[index] = fold_markers[1]
            else
              line[index] = fold_markers[2]
            end

            add_guide_hl(
              running_length,
              running_length + vim.fn.strlen(line[index]) - 1
            )

            -- the root level has no vertical markers
          elseif depth > 1 then
            if node.isLast then
              line[index] = guide_markers.bottom
              add_guide_hl(
                running_length,
                running_length + vim.fn.strlen(guide_markers.bottom) - 1
              )
            else
              line[index] = guide_markers.middle
              add_guide_hl(
                running_length,
                running_length + vim.fn.strlen(guide_markers.middle) - 1
              )
            end
          end
          -- else if the parent was not the last in its group, add a
          -- vertical marker because there are items under us and we need
          -- to point to those
        elseif not node.hierarchy[index] and depth > 1 then
          line[index + marker_space] = guide_markers.vertical
          add_guide_hl(
            running_length - 1 + 2 * marker_space,
            running_length
              + vim.fn.strlen(guide_markers.vertical)
              - 1
              + 2 * marker_space
          )
        end
      end

      line[index] = line[index] .. ' '

      running_length = running_length + vim.fn.strlen(line[index])
    end

    line[1] = ''
    local final_prefix = line

    local string_prefix = t_utils.table_to_str(final_prefix)

    table.insert(lines, string_prefix .. node.icon .. ' ' .. node.name)

    local hl_start = #string_prefix
    local hl_end = #string_prefix + #node.icon
    local hl_type = cfg.o.symbols.icons[symbols.kinds[node.kind]].hl
    table.insert(hl_info, { node_line, hl_start, hl_end, hl_type })

    node.prefix_length = #string_prefix + #node.icon + 1
  end

  local final_hl = {}
  if cfg.o.outline_items.show_symbol_lineno then
    -- Width of the highest lineno value
    local max_width = #tostring(lineno_max)
    -- Padded prefix to the right of lineno for better readability if linenos
    -- get more than 2 digits.
    local prefix = string.rep(' ', math.max(2, max_width)+1)
    -- Offset to hl_info due to adding lineno on the left of each symbol line
    local total_offset = #prefix
    for i, node in ipairs(flattened_outline_items) do
      lines[i] = prefix .. lines[i]
      table.insert(final_hl, {
        hl_info[i][1],                 -- node_line
        hl_info[i][2] + total_offset,  -- start
        hl_info[i][3] + total_offset,  -- end
        hl_info[i][4]                  -- type
      })
      node.prefix_length = node.prefix_length + total_offset
    end
    if cfg.o.guides.enabled then
      for _, hl in ipairs(guide_hl_info) do
        table.insert(final_hl, {
          hl[1],
          hl[2] + total_offset,
          hl[3] + total_offset,
          hl[4]
        })
      end
    end
  else
    -- Merge lists hl_info and guide_hl_info
    final_hl = hl_info
    if cfg.o.guides.enabled then
      for _, hl in ipairs(guide_hl_info) do
        table.insert(final_hl, hl)
      end
    end
  end
  return lines, final_hl
end

function M.get_details(flattened_outline_items)
  local lines = {}
  for _, value in ipairs(flattened_outline_items) do
    table.insert(lines, value.detail or '')
  end
  return lines
end

function M.get_lineno(flattened_outline_items)
  local lines = {}
  local max = 0
  for _, value in ipairs(flattened_outline_items) do
    local line = value.range_start+1
    if line > max then
      max = line
    end
    -- Not padded here
    table.insert(lines, tostring(line))
  end
  return lines, max
end

return M
