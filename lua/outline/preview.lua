local cfg = require('outline.config')
local hover = require('outline.hover')
local outline = require('outline')

local M = {}

local state = {
  preview_buf = nil,
  preview_win = nil,
}

local function is_current_win_outline()
  local curwin = vim.api.nvim_get_current_win()
  return curwin == outline.current.view.win
end

local function has_code_win(winnr)
  if not outline.current then
    return false
  end
  winnr = winnr or outline.current.code.win
  return vim.api.nvim_win_is_valid(winnr) and vim.api.nvim_buf_is_valid(outline.current.code.buf)
end

M.has_code_win = has_code_win

---Get the correct column to place the floating window based on
-- Relative positions of the outline and the code window.
---@param preview_width integer
local function get_col(preview_width)
  ---@type integer
  local outline_winnr = outline.current.view.win
  local outline_col = vim.api.nvim_win_get_position(outline_winnr)[2]
  local outline_width = vim.api.nvim_win_get_width(outline_winnr)
  local code_col = vim.api.nvim_win_get_position(outline.current.code.win)[2]

  -- TODO: What if code win is below/above outline instead?

  local col = outline_col
  if outline_col > code_col then
    col = col - preview_width - 3
  else
    col = col + outline_width + 1
  end

  return col
end

---@param preview_height integer
---@param outline_height integer
local function get_row(preview_height, outline_height)
  local offset = math.floor((outline_height - preview_height) / 2) - 1
  return vim.api.nvim_win_get_position(outline.current.view.win)[1] + offset
end

local function get_height()
  return vim.api.nvim_win_get_height(outline.current.view.win)
end

local function get_hovered_node()
  local hovered_line = vim.api.nvim_win_get_cursor(outline.current.view.win)[1]
  local node = outline.current.flats[hovered_line]
  return node
end

local function update_preview(code_buf)
  code_buf = code_buf or outline.current.code.buf

  local node = get_hovered_node()
  if not node then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(code_buf, 0, -1, false)

  if state.preview_buf ~= nil then
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(state.preview_win, { node.line + 1, node.character })
  end
end

local function setup_preview_buf()
  local code_buf = outline.current.code.buf
  local ft = vim.api.nvim_buf_get_option(code_buf, 'filetype')

  vim.api.nvim_buf_set_option(state.preview_buf, 'syntax', ft)

  local ts_highlight_fn = vim.treesitter.start
  if not _G._outline_nvim_has[8] then
    local ok, ts_highlight = pcall(require, 'nvim-treesitter.highlight')
    if ok then
      ts_highlight_fn = ts_highlight.attach
    end
  end
  pcall(ts_highlight_fn, state.preview_buf, ft)

  vim.api.nvim_buf_set_option(state.preview_buf, 'bufhidden', 'delete')
  vim.api.nvim_win_set_option(state.preview_win, 'cursorline', true)
  update_preview(code_buf)
end

local function set_bg_hl()
  vim.api.nvim_win_set_option(state.preview_win, 'winhl', cfg.o.preview_window.winhl)
  vim.api.nvim_win_set_option(state.preview_win, 'winblend', cfg.o.preview_window.winblend)
end

local function show_preview()
  if state.preview_win == nil and state.preview_buf == nil then
    state.preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_attach(state.preview_buf, false, {
      on_detach = function()
        state.preview_buf = nil
        state.preview_win = nil
      end,
    })
    local height = get_height()
    local width = cfg.get_preview_width()
    local winheight = math.max(math.ceil(height / 2), cfg.o.preview_window.min_height)
    state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
      relative = 'editor',
      height = winheight,
      width = width,
      bufpos = { 0, 0 },
      col = get_col(width),
      -- Position preview window middle-aligned vertically
      row = get_row(winheight, height),
      border = cfg.o.preview_window.border,
    })
    setup_preview_buf()
  else
    update_preview()
  end
end

function M.show()
  if not is_current_win_outline() or #vim.api.nvim_list_wins() < 2 then
    return
  end

  show_preview()
  set_bg_hl()
  if cfg.o.preview_window.open_hover_on_preview then
    hover.show_hover()
  end
end

function M.close()
  if has_code_win() then
    if state.preview_win ~= nil and vim.api.nvim_win_is_valid(state.preview_win) then
      vim.api.nvim_win_close(state.preview_win, true)
    end
    if state.hover_win ~= nil and vim.api.nvim_win_is_valid(state.hover_win) then
      vim.api.nvim_win_close(state.hover_win, true)
    end
  end
end

function M.toggle()
  if state.preview_win ~= nil then
    M.close()
  else
    M.show()
  end
end

return M
