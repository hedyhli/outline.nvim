local cfg = require('outline.config')
local highlight = require('outline.highlight')

---@class outline.View
local View = {}

---@class outline.View
---@field bufnr integer
---@field winnr integer

function View:new()
  return setmetatable({ bufnr = nil, winnr = nil }, { __index = View })
end

---Creates the outline window and sets it up
---@param split_command string A valid split command that is to be executed in order to create the view.
function View:setup_view(split_command)
  -- create a scratch unlisted buffer
  self.bufnr = vim.api.nvim_create_buf(false, true)

  -- delete buffer when window is closed / buffer is hidden
  vim.api.nvim_buf_set_option(self.bufnr, 'bufhidden', 'delete')
  -- create a split
  vim.cmd(split_command)

  -- resize to a % of the current window size
  vim.cmd('vertical resize ' .. cfg.get_window_width())

  -- get current (outline) window and attach our buffer to it
  self.winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(self.winnr, self.bufnr)

  -- window stuff
  vim.api.nvim_win_set_option(self.winnr, 'spell', false)
  vim.api.nvim_win_set_option(self.winnr, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(self.winnr, 'foldcolumn', '0')
  vim.api.nvim_win_set_option(self.winnr, 'number', false)
  vim.api.nvim_win_set_option(self.winnr, 'relativenumber', false)
  vim.api.nvim_win_set_option(self.winnr, 'winfixwidth', true)
  vim.api.nvim_win_set_option(self.winnr, 'list', false)
  vim.api.nvim_win_set_option(self.winnr, 'wrap', cfg.o.outline_window.wrap)
  vim.api.nvim_win_set_option(self.winnr, 'winhl', cfg.o.outline_window.winhl)
  vim.api.nvim_win_set_option(self.winnr, 'linebreak', true) -- only has effect when wrap=true
  vim.api.nvim_win_set_option(self.winnr, 'breakindent', true) -- only has effect when wrap=true
  --  Would be nice to use guides.markers.vertical as part of showbreak to keep
  --  continuity of the tree UI, but there's currently no way to style the
  --  color, apart from globally overriding hl-NonText, which will potentially
  --  mess with other theme/user settings. So just use empty spaces for now.
  vim.api.nvim_win_set_option(self.winnr, 'showbreak', '      ') -- only has effect when wrap=true.
  -- buffer stuff
  local tab = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_buf_set_name(self.bufnr, 'OUTLINE_' .. tostring(tab))
  vim.api.nvim_buf_set_option(self.bufnr, 'filetype', 'Outline')
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', false)

  if cfg.o.outline_window.show_numbers or cfg.o.outline_window.show_relative_numbers then
    vim.api.nvim_win_set_option(self.winnr, 'nu', true)
  end

  if cfg.o.outline_window.show_relative_numbers then
    vim.api.nvim_win_set_option(self.winnr, 'rnu', true)
  end

  local cl = cfg.o.outline_window.show_cursorline
  if cl == true or cl == 'focus_in_outline' then
    vim.api.nvim_win_set_option(self.winnr, 'cursorline', true)
  end
end

---Close view window and remove winnr/bufnr fields
function View:close()
  if self.winnr then
    vim.api.nvim_win_close(self.winnr, true)
    self.winnr = nil
    self.bufnr = nil
  end
end

---Return whether view has valid buf and win numbers
function View:is_open()
  return self.winnr
    and self.bufnr
    and vim.api.nvim_buf_is_valid(self.bufnr)
    and vim.api.nvim_win_is_valid(self.winnr)
end

---Replace all lines in buffer with given new `lines`
---@param lines string[]
function View:rewrite_lines(lines)
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', false)
end

function View:clear_all_ns()
  highlight.clear_all_ns(self.bufnr)
end

---Ensure all existing highlights are already cleared before calling!
---@param hl outline.HL[]
---@param nodes outline.FlatSymbolNode[]
---@param details string[]
---@param linenos string[]
function View:add_hl_and_ns(hl, nodes, details, linenos)
  highlight.items(self.bufnr, hl)
  if cfg.o.outline_items.highlight_hovered_item then
    highlight.hovers(self.bufnr, nodes)
  end
  if cfg.o.outline_items.show_symbol_details then
    highlight.details(self.bufnr, details)
  end

  -- Note on hl_mode:
  -- When hide_cursor + cursorline enabled, we want the lineno to also take on
  -- the cursorline background so wherever the cursor is, it appears blended.
  -- We want 'replace' even for `hide_cursor=false cursorline=true` because
  -- vim's native line numbers do not get highlighted by cursorline.
  if cfg.o.outline_items.show_symbol_lineno then
    -- stylua: ignore start
    highlight.linenos(
      self.bufnr, linenos,
      (cfg.o.outline_window.hide_cursor and 'combine') or 'replace'
    )
    -- stylua: ignore end
  end
end

return View
