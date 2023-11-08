local so = require 'symbols-outline'
local cfg = require 'symbols-outline.config'
local hover = require 'symbols-outline.hover'

local M = {}

local state = {
  preview_buf = nil,
  preview_win = nil,
}

local function is_current_win_outline()
  local curwin = vim.api.nvim_get_current_win()
  return curwin == so.view.winnr
end

local function has_code_win()
  local isWinValid = vim.api.nvim_win_is_valid(so.state.code_win)
  if not isWinValid then
    return false
  end
  local bufnr = vim.api.nvim_win_get_buf(so.state.code_win)
  local isBufValid = vim.api.nvim_buf_is_valid(bufnr)
  return isBufValid
end

M.has_code_win = has_code_win

local function get_width_offset()
  ---@type integer
  local outline_winnr = so.view.winnr
  local width = cfg.get_preview_width() + 3
  local has_numbers = vim.api.nvim_win_get_option(outline_winnr, "number")
  has_numbers = has_numbers or vim.api.nvim_win_get_option(outline_winnr, "relativenumber")

  if has_numbers then
    width = width + 4
  end

  if cfg.o.outline_window.position == 'right' then
    width = 0 - width
  else
    width = vim.api.nvim_win_get_width(outline_winnr) + 1
  end

  return width
end

local function get_height()
  return vim.api.nvim_list_uis()[1].height
end

local function get_hovered_node()
  local hovered_line = vim.api.nvim_win_get_cursor(so.view.winnr)[1]
  local node = so.state.flattened_outline_items[hovered_line]
  return node
end

local function update_preview(code_buf)
  code_buf = code_buf or vim.api.nvim_win_get_buf(so.state.code_win)

  local node = get_hovered_node()
  if not node then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(code_buf, 0, -1, false)

  if state.preview_buf ~= nil then
    vim.api.nvim_buf_set_lines(state.preview_buf, 0, -1, 0, lines)
    vim.api.nvim_win_set_cursor(
      state.preview_win,
      { node.line + 1, node.character }
    )
  end
end

local function setup_preview_buf()
  local code_buf = vim.api.nvim_win_get_buf(so.state.code_win)
  local ft = vim.api.nvim_buf_get_option(code_buf, 'filetype')

  local function treesitter_attach()
    local ts_highlight = require 'nvim-treesitter.highlight'

    ts_highlight.attach(state.preview_buf, ft)
  end

  -- user might not have tree sitter installed
  pcall(treesitter_attach)

  vim.api.nvim_buf_set_option(state.preview_buf, 'syntax', ft)
  vim.api.nvim_buf_set_option(state.preview_buf, 'bufhidden', 'delete')
  vim.api.nvim_win_set_option(state.preview_win, 'cursorline', true)
  update_preview(code_buf)
end

local function set_bg_hl()
  local winhi = 'Normal:' .. cfg.o.preview_window.bg_hl
  vim.api.nvim_win_set_option(state.preview_win, 'winhighlight', winhi)
  -- vim.api.nvim_win_set_option(state.hover_win, 'winhighlight', winhi)
  local winblend = cfg.o.preview_window.winblend
  vim.api.nvim_win_set_option(state.preview_win, 'winblend', winblend)
  -- vim.api.nvim_win_set_option(state.hover_win, 'winblend', winblend)
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
    local winheight = math.ceil(height / 2)
    state.preview_win = vim.api.nvim_open_win(state.preview_buf, false, {
      relative = 'win',
      height = winheight,
      width = cfg.get_preview_width(),
      bufpos = { 0, 0 },
      col = get_width_offset(),
      -- Position preview window middle-aligned vertically
      row = math.floor((height - winheight) / 2) - 1,
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
    if
      state.preview_win ~= nil and vim.api.nvim_win_is_valid(state.preview_win)
    then
      vim.api.nvim_win_close(state.preview_win, true)
    end
    if
      state.hover_win ~= nil and vim.api.nvim_win_is_valid(state.hover_win)
    then
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
