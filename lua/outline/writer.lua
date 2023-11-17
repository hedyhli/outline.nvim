local cfg = require('outline.config')
local folding = require('outline.folding')
local parser = require('outline.parser')
local symbols = require('outline.symbols')
local t_utils = require('outline.utils.table')
local ui = require('outline.ui')

local strlen = vim.fn.strlen

local M = {}

local hlns = vim.api.nvim_create_namespace('outline-icon-highlight')
local ns = vim.api.nvim_create_namespace('outline-virt-text')

---@param bufnr integer
---@return boolean
function M.is_buffer_outline(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  return string.match(name, 'OUTLINE') ~= nil and ft == 'Outline'
end

---Apply highlights and hover highlights to bufnr
---@param bufnr integer
---@param nodes outline.FlatSymbolNode[] flattened nodes
function M.add_highlights(bufnr, hl_info, nodes)
  for _, line_hl in ipairs(hl_info) do
    local line, hl_start, hl_end, hl_type = unpack(line_hl)
    vim.api.nvim_buf_add_highlight(bufnr, hlns, hl_type, line - 1, hl_start, hl_end)
  end
  M.add_hover_highlights(bufnr, nodes)
end

---@param bufnr integer
local function clear_virt_text(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
end

---@param bufnr integer
---@param nodes outline.FlatSymbolNode[] flattened nodes
function M.add_hover_highlights(bufnr, nodes)
  if not cfg.o.outline_items.highlight_hovered_item then
    return
  end

  -- clear old highlight
  ui.clear_hover_highlight(bufnr)
  for _, node in ipairs(nodes) do
    if not node.hovered then
      goto continue
    end

    if node.prefix_length then
      ui.add_hover_highlight(bufnr, node.line_in_outline - 1, node.prefix_length)
    end
    ::continue::
  end
end

---The quintessential function of this entire plugin. Clears virtual text,
-- parses each node and replaces old lines with new lines to be written for the
-- outline buffer.
-- Handles highlights, virtual text, and of course lines of outline to write
---@param bufnr integer Nothing is done if is_buffer_outline(bufnr) is not true
---@param items outline.SymbolNode[] Tree of symbols after being parsed by parser.parse_result
---@return outline.FlatSymbolNode[] flattened_items Empty table returned if bufnr is invalid
---@param codewin integer code window
function M.make_outline(bufnr, items, codewin)
  if not M.is_buffer_outline(bufnr) then
    return {}
  end
  local codebuf = vim.api.nvim_win_get_buf(codewin)

  clear_virt_text(bufnr)

  ---@type string[]
  local lines = {}
  ---@type string[]
  local details = {}
  ---@type string[]
  local linenos = {}
  ---@type outline.FlatSymbolNode[]
  local flattened = {}
  local hl = {}

  -- Find the prefix for each line needed for the lineno space
  local lineno_offset = 0
  local lineno_prefix = ''
  local lineno_max_width = #tostring(vim.api.nvim_buf_line_count(codebuf) - 1)
  if cfg.o.outline_items.show_symbol_lineno then
    -- Use max width-1 plus 1 space padding.
    -- -1 because if max_width is a power of ten, don't shift the entire lineno
    -- column by the right just because the last line number requires an extra
    -- digit. If max_width is 1000, the lineno column will take up 3 columns to
    -- fill the digits, and 1 padding on the right. The 1000 can fit perfectly
    -- there.
    lineno_offset = math.max(2, lineno_max_width) + 1
    lineno_prefix = string.rep(' ', lineno_offset)
  end

  -- Closures for convenience
  local function add_guide_hl(from, to)
    table.insert(hl, {
      #flattened,
      from,
      to,
      'OutlineGuides',
    })
  end

  local function add_fold_hl(from, to)
    table.insert(hl, {
      #flattened,
      from,
      to,
      'OutlineFoldMarker',
    })
  end

  local guide_markers = cfg.o.guides.markers
  if not cfg.o.guides.enabled then
    guide_markers = {
      middle = ' ',
      vertical = ' ',
      bottom = ' ',
    }
  end
  local fold_markers = cfg.o.symbol_folding.markers

  for node in parser.preorder_iter(items) do
    table.insert(flattened, node)
    node.line_in_outline = #flattened
    table.insert(details, node.detail or '')
    local lineno = tostring(node.range_start + 1)
    local leftpad = string.rep(' ', lineno_max_width - #lineno)
    table.insert(linenos, leftpad .. lineno)

    -- Make the guides for the line prefix
    local pref = t_utils.str_to_table(string.rep(' ', node.depth))
    local fold_marker_width = 0

    if folding.is_foldable(node) then
      -- Add fold marker
      local marker = fold_markers[2]
      if folding.is_folded(node) then
        marker = fold_markers[1]
      end
      pref[#pref] = marker
      fold_marker_width = strlen(marker)
    else
      -- Rightmost guide for the immediate parent, only added if fold marker is
      -- not added
      if node.depth > 1 then
        local marker = guide_markers.middle
        if node.isLast then
          marker = guide_markers.bottom
        end
        pref[#pref] = marker
      end
    end

    -- Add vertical guides to the left, for all parents that isn't the last
    -- sibling. Iter from first grandparent until second last ancestor (last
    -- ancestor is the entire outline itself, it should not have a vertical
    -- guide).
    local iternode = node
    for i = node.depth - 1, 2, -1 do
      iternode = iternode.parent_node
      if not iternode.isLast then
        pref[i] = guide_markers.vertical
      end
    end

    -- Finished with guide prefix
    -- Join all prefix chars by a space
    local pref_str = table.concat(pref, ' ')
    local total_pref_len = lineno_offset + #pref_str

    -- Guide hl goes from start of prefix till before the fold marker, if any.
    -- Fold hl goes from start of fold marker until before the icon.
    add_guide_hl(lineno_offset, total_pref_len - fold_marker_width)
    if fold_marker_width > 0 then
      add_fold_hl(total_pref_len - fold_marker_width, total_pref_len + 1)
    end

    local line = lineno_prefix .. pref_str
    local icon_pref = 0
    if node.icon ~= '' then
      line = line .. ' ' .. node.icon
      icon_pref = 1
    end
    line = line .. ' ' .. node.name

    -- Highlight for the icon ✨
    -- Start from icon col
    local hl_start = #pref_str + #lineno_prefix + icon_pref
    local hl_end = hl_start + #node.icon -- until after icon
    local hl_type = cfg.o.symbols.icons[symbols.kinds[node.kind]].hl
    table.insert(hl, { #flattened, hl_start, hl_end, hl_type })

    -- Prefix length is from start until the beginning of the node.name, used
    -- for hover highlights.
    node.prefix_length = hl_end + 1

    -- lines passed to nvim_buf_set_lines cannot contain newlines in each line
    line = line:gsub('\n', ' ')
    table.insert(lines, line)
  end

  -- Write the lines 🎉
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)

  -- Unfortunately highlights and extmarks cannot be added to lines that do not
  -- yet exist. Hence this requires another O(n) of iteration.
  M.add_highlights(bufnr, hl, flattened)

  -- Add details and lineno virtual text.
  if cfg.o.outline_items.show_symbol_details then
    for index, value in ipairs(details) do
      vim.api.nvim_buf_set_extmark(bufnr, ns, index - 1, -1, {
        virt_text = { { value, 'OutlineDetails' } },
        virt_text_pos = 'eol',
        hl_mode = 'combine',
      })
    end
  end
  if cfg.o.outline_items.show_symbol_lineno then
    -- Line numbers are left padded, right aligned, positioned at the leftmost
    -- column
    -- TODO: Fix lineno not appearing if text in line is truncated on the right
    -- due to narrow window, after nvim fixes virt_text_hide.
    for index, value in ipairs(linenos) do
      vim.api.nvim_buf_set_extmark(bufnr, ns, index - 1, -1, {
        virt_text = { { value, 'OutlineLineno' } },
        virt_text_pos = 'overlay',
        virt_text_win_col = 0,
        -- When hide_cursor + cursorline enabled, we want the lineno to also
        -- take on the cursorline background so wherever the cursor is, it
        -- appears blended. We want 'replace' even for `hide_cursor=false
        -- cursorline=true` because vim's native line numbers do not get
        -- highlighted by cursorline.
        hl_mode = (cfg.o.outline_window.hide_cursor and 'combine') or 'replace',
      })
    end
  end

  return flattened
end
-- XXX: Is the performance tradeoff of calling `nvim_buf_set_lines` on each
-- iteration worth it in order to put setting of highlights, details, and
-- linenos together with each line?
-- That is,
-- 1.  { call nvim_buf_set_lines once for all lines }
--   + { O(n) for each of highlights, details, and linenos }
--OR
-- 2.  { call nvim_buf_set_lines for each line }
--   + { O(1) for each of highlight/detail/lineno the same iteration }
-- It appears that for highlight/detail/lineno, the number of calls to nvim API
-- is the same, only 3 extra tables in memory for (1). Where as for (2) you
-- have to call nvim_buf_set_lines n times (each line) rather than add lines
-- all at once, saving only the need of 1 extra table (lines table) in memory.

return M
