local cfg = require('outline.config')
local providers = require('outline.providers')

local conf

---@class outline.Preview
local Preview = {}

---@class outline.Preview
---@field buf integer
---@field win integer
---@field width integer
---@field height integer
---@field outline_height integer
---@field s outline.Sidebar

---@param s outline.Sidebar
function Preview:new(s)
  -- Config must have been setup when calling Preview:new
  conf = cfg.o.preview_window
  return setmetatable({
    buf = nil,
    win = nil,
    s = s,
    width = nil,
    height = nil,
  }, { __index = Preview })
end

---Creates new preview window and sets the content. Calls setup and set_lines.
function Preview:create()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_attach(self.buf, false, {
    on_detach = function()
      self.buf = nil
      self.win = nil
    end,
  })
  -- FIXME: Re-calculate dimensions on update-preview, in case outline window
  -- was resized between last preview and next preview?
  self.outline_height = vim.api.nvim_win_get_height(self.s.view.win)
  self.width = conf.width
  self.height = math.max(math.ceil(self.outline_height / 2), conf.min_height)
  self.win = vim.api.nvim_open_win(self.buf, false, {
    relative = 'editor',
    height = self.height,
    width = self.width,
    bufpos = { 0, 0 },
    col = self:calc_col(),
    row = self:calc_row(),
    border = conf.border,
  })
  self:setup()
  self:set_lines()
end

---Set up highlights, window, and buffer options
function Preview:setup()
  vim.api.nvim_win_set_option(self.win, 'winhl', conf.winhl)
  vim.api.nvim_win_set_option(self.win, 'winblend', conf.winblend)

  local code_buf = self.s.code.buf
  local ft = vim.api.nvim_buf_get_option(code_buf, 'filetype')
  vim.api.nvim_buf_set_option(self.buf, 'syntax', ft)

  local ts_highlight_fn = vim.treesitter.start
  if not _G._outline_nvim_has[8] then
    local ok, ts_highlight = pcall(require, 'nvim-treesitter.highlight')
    if ok then
      ts_highlight_fn = ts_highlight.attach
    end
  end
  pcall(ts_highlight_fn, self.buf, ft)

  vim.api.nvim_buf_set_option(self.buf, 'bufhidden', 'delete')
  vim.api.nvim_win_set_option(self.win, 'cursorline', true)
  vim.api.nvim_buf_set_option(self.buf, 'modifiable', false)
end

---Get the correct column to place the floating window based on relative
---positions of the outline and the code window.
function Preview:calc_col()
  ---@type integer
  local outline_winnr = self.s.view.win
  local outline_col = vim.api.nvim_win_get_position(outline_winnr)[2]
  local outline_width = vim.api.nvim_win_get_width(outline_winnr)
  local code_col = vim.api.nvim_win_get_position(self.s.code.win)[2]

  -- TODO: What if code win is below/above outline instead?

  local col = outline_col
  if outline_col > code_col then
    col = col - self.width - 3
  else
    col = col + outline_width + 1
  end

  return col
end

---Get the vertically center-aligned row for preview window
function Preview:calc_row()
  local offset = math.floor((self.outline_height - self.height) / 2) - 1
  return vim.api.nvim_win_get_position(self.s.view.win)[1] + offset
end

---Set and update preview buffer content
function Preview:set_lines()
  -- TODO: Editable, savable buffer in the preview like VS Code for quick
  -- edits? It can be like LSP. Trigger preview to open, trigger again to focus
  -- (so buffer can be edited).
  -- This can be achieved by simply opening the buffer from inside the preview
  -- window.
  -- This also removes the need of manually setting highlights, treesitter etc.
  -- The preview window will look exactly the same as in the code window.
  local node = self.s:_current_node()
  if not node then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(self.s.code.buf, 0, -1, false)

  if self.buf ~= nil then
    vim.api.nvim_buf_set_option(self.buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(self.buf, 'modifiable', false)
    vim.api.nvim_win_set_cursor(self.win, { node.line + 1, node.character })
  end
end

---Create or update preview
function Preview:show()
  if not self.s:has_focus() or #vim.api.nvim_list_wins() < 2 then
    return
  end

  if self.buf and self.win then
    self:set_lines()
  else
    self:create()
  end

  if conf.open_hover_on_preview then
    providers.action(self.s, 'show_hover', { self.s })
  end
end

function Preview:close()
  -- TODO: Why was this in symbols-outline.nvim?
  -- if self.s:has_code_win() then
  if self.win ~= nil and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
  -- end
end

function Preview:toggle()
  if self.win ~= nil then
    self:close()
  else
    self:show()
  end
end

return Preview
