local cfg = require('outline.config')
local highlight = require('outline.highlight')

local M = {}

local hlns = vim.api.nvim_create_namespace('outline-icon-highlight')
local vtns = vim.api.nvim_create_namespace('outline-virt-text')

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

---@param bufnr integer Outline buffer
function M.clear_icon_hl(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, hlns, 0, -1)
end

---@param bufnr integer Outline buffer
function M.clear_virt_text(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, vtns, 0, -1)
end

---@param bufnr integer Outline buffer
---@param nodes outline.FlatSymbolNode[]
function M.add_hover_highlights(bufnr, nodes)
  if not cfg.o.outline_items.highlight_hovered_item then
    return
  end

  -- clear old highlight
  highlight.clear_hover_highlight(bufnr)
  for _, node in ipairs(nodes) do
    if node.hovered then
      highlight.add_hover_highlight(bufnr, node.line_in_outline - 1, node.prefix_length)
    end
  end
end

---@param bufnr integer Outline buffer
---@param details string[]
function M.add_details(bufnr, details)
  for index, value in ipairs(details) do
    vim.api.nvim_buf_set_extmark(bufnr, vtns, index - 1, -1, {
      virt_text = { { value, 'OutlineDetails' } },
      virt_text_pos = 'eol',
      hl_mode = 'combine',
    })
  end
end

---@param bufnr integer Outline buffer
---@param linenos string[] Must already be padded
function M.add_linenos(bufnr, linenos)
  -- TODO: Fix lineno not appearing if text in line is truncated on the right
  -- due to narrow window, after nvim fixes virt_text_hide.
  for index, value in ipairs(linenos) do
    vim.api.nvim_buf_set_extmark(bufnr, vtns, index - 1, -1, {
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

return M
