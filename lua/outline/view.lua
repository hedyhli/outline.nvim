local cfg = require('outline.config')
local highlight = require('outline.highlight')
local utils = require('outline.utils')

---@class outline.View
local View = {}

---@class outline.View
---@field buf integer
---@field win integer

function View:new()
  return setmetatable({ buf = nil, win = nil }, { __index = View })
end

---Creates the outline window and sets it up
---@param split_command string A valid split command that is to be executed in order to create the view.
---@param use_float boolean? Whether to use floating window
function View:setup_view(split_command, use_float)
  -- create a scratch unlisted buffer
  self.buf = vim.api.nvim_create_buf(false, true)

  -- set filetype
  utils.buf_set_option(self.buf, 'filetype', 'Outline')

  -- delete buffer when window is closed / buffer is hidden
  utils.buf_set_option(self.buf, 'bufhidden', 'delete')
  utils.buf_set_option(self.buf, 'buflisted', false)
  utils.buf_set_option(self.buf, 'buftype', 'nofile')
  utils.buf_set_option(self.buf, 'modifiable', false)

  -- Check if using floating window
  if use_float then
    self:setup_float_view()
  else
    self:setup_split_view(split_command)
  end

  -- buffer stuff
  local tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_buf_set_name(self.buf, 'OUTLINE_' .. tostring(tab))
  vim.api.nvim_buf_set_option(self.buf, 'modifiable', false)
end

---Setup split window (traditional behavior)
---@param split_command string
function View:setup_split_view(split_command)
  -- create a split
  vim.cmd(split_command)

  -- get current (outline) window and attach our buffer to it
  self.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.win, self.buf)

  -- resize if split_command not specify width like "25vsplit"
  if split_command:match('%d+') == nil then
    -- resize to a % of the current window size
    vim.cmd('vertical resize ' .. cfg.o.outline_window.width)
  end

  -- window stuff
  utils.win_set_option(self.win, 'spell', false)
  utils.win_set_option(self.win, 'signcolumn', 'no')
  utils.win_set_option(self.win, 'foldcolumn', '0')
  utils.win_set_option(self.win, 'number', false)
  utils.win_set_option(self.win, 'relativenumber', false)
  utils.win_set_option(self.win, 'winfixwidth', true)
  utils.win_set_option(self.win, 'list', false)
  utils.win_set_option(self.win, 'wrap', cfg.o.outline_window.wrap)
  utils.win_set_option(self.win, 'winhl', cfg.o.outline_window.winhl)
  utils.win_set_option(self.win, 'linebreak', true) -- only has effect when wrap=true
  utils.win_set_option(self.win, 'breakindent', true) -- only has effect when wrap=true
  -- this setting pins the window to the buffer not allowing to open any other
  -- buffers, which helps to prevent situation when external pickers (e.g.
  -- telescope) opens file in the outline window sidebar.
  if vim.fn.exists('&winfixbuf') == 1 then
    utils.win_set_option(self.win, 'winfixbuf', true)
  end
  --  Would be nice to use guides.markers.vertical as part of showbreak to keep
  --  continuity of the tree UI, but there's currently no way to style the
  --  color, apart from globally overriding hl-NonText, which will potentially
  --  mess with other theme/user settings. So just use empty spaces for now.
  utils.win_set_option(self.win, 'showbreak', '      ') -- only has effect when wrap=true.
  -- buffer stuff
  local tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_buf_set_name(self.buf, 'OUTLINE_' .. tostring(tab))
  utils.buf_set_option(self.buf, 'modifiable', false)

  if cfg.o.outline_window.show_numbers or cfg.o.outline_window.show_relative_numbers then
    utils.win_set_option(self.win, 'nu', true)
  end

  if cfg.o.outline_window.show_relative_numbers then
    utils.win_set_option(self.win, 'rnu', true)
  end

  local cl = cfg.o.outline_window.show_cursorline
  if cl == true or cl == 'focus_in_outline' then
    utils.win_set_option(self.win, 'cursorline', true)
  end
end

---Setup floating window
function View:setup_float_view()
  local float_config = cfg.o.outline_window.float
  local width = cfg.get_float_window_width()
  local height = cfg.get_float_window_height()

  -- Calculate position based on outline_window.position
  local row = 0
  local col = 0

  if cfg.o.outline_window.position == 'right' then
    col = vim.o.columns - width
  end

  -- Get win_config (can be a table or function)
  local win_config = float_config.win_config
  if type(win_config) == 'function' then
    win_config = win_config({
      width = width,
      height = height,
      row = row,
      col = col,
    })
  end

  -- Cannot be merged into the default settings because some configurations are
  -- difficult to override.
  local final_win_config = vim.tbl_deep_extend('force', {
    width = width,
    height = height,
    row = row,
    col = col,
  }, win_config or {})

  -- Create floating window
  self.win = vim.api.nvim_open_win(self.buf, false, final_win_config)

  -- Set window options
  vim.api.nvim_win_set_option(self.win, 'spell', false)
  vim.api.nvim_win_set_option(self.win, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(self.win, 'foldcolumn', '0')
  vim.api.nvim_win_set_option(self.win, 'number', false)
  vim.api.nvim_win_set_option(self.win, 'relativenumber', false)
  vim.api.nvim_win_set_option(self.win, 'list', false)
  vim.api.nvim_win_set_option(self.win, 'wrap', cfg.o.outline_window.wrap)
  vim.api.nvim_win_set_option(self.win, 'winhl', cfg.o.outline_window.winhl)
  vim.api.nvim_win_set_option(self.win, 'linebreak', true)
  vim.api.nvim_win_set_option(self.win, 'breakindent', true)
  vim.api.nvim_win_set_option(self.win, 'showbreak', '      ')

  if cfg.o.outline_window.show_numbers or cfg.o.outline_window.show_relative_numbers then
    vim.api.nvim_win_set_option(self.win, 'nu', true)
  end

  if cfg.o.outline_window.show_relative_numbers then
    vim.api.nvim_win_set_option(self.win, 'rnu', true)
  end

  local cl = cfg.o.outline_window.show_cursorline
  if cl == true or cl == 'focus_in_outline' then
    vim.api.nvim_win_set_option(self.win, 'cursorline', true)
  end

  -- Apply custom win_options
  if float_config.win_options then
    for opt, val in pairs(float_config.win_options) do
      vim.api.nvim_win_set_option(self.win, opt, val)
    end
  end
end

---Close view window and remove winnr/bufnr fields
function View:close()
  if self.win then
    local windows = vim.api.nvim_list_wins()
    local win_count = #windows
    if win_count == 1 then
      vim.api.nvim_command('q')
    else
      vim.api.nvim_win_close(self.win, true)
      self.win = nil
      self.buf = nil
    end
  end
end

---Return whether view has valid buf and win numbers
function View:is_open()
  return self.win
    and self.buf
    and vim.api.nvim_buf_is_valid(self.buf)
    and vim.api.nvim_win_is_valid(self.win)
end

---Replace all lines in buffer with given new `lines`
---@param lines string[]
function View:rewrite_lines(lines)
  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    utils.buf_set_option(self.buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    utils.buf_set_option(self.buf, 'modifiable', false)
  end
end

function View:clear_all_ns()
  if self.buf then
    highlight.clear_all_ns(self.buf)
  end
end

---Ensure all existing highlights are already cleared before calling!
---@param hl outline.HL[]
---@param nodes outline.FlatSymbol[]
---@param details string[]
---@param linenos string[]
function View:add_hl_and_ns(hl, nodes, details, linenos)
  if not self.buf then
    return
  end

  highlight.items(self.buf, hl)
  if cfg.o.outline_items.highlight_hovered_item then
    highlight.hovers(self.buf, nodes)
  end
  if cfg.o.outline_items.show_symbol_details then
    highlight.details(self.buf, details)
  end

  -- Note on hl_mode:
  -- When hide_cursor + cursorline enabled, we want the lineno to also take on
  -- the cursorline background so wherever the cursor is, it appears blended.
  -- We want 'replace' even for `hide_cursor=false cursorline=true` because
  -- vim's native line numbers do not get highlighted by cursorline.
  if cfg.o.outline_items.show_symbol_lineno then
    -- stylua: ignore start
    highlight.linenos(
      self.buf, linenos,
      (cfg.o.outline_window.hide_cursor and 'combine') or 'replace'
    )
    -- stylua: ignore end
  end
end

return View
