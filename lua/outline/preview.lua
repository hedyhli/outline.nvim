local cfg = require('outline.config')

-- A floating window to preview the location of a symbol from the outline.
-- Classical preview reads entire lines into a new buffer for preview. Live
-- preview sets the buffer of floating window to the code buffer, which allows
-- focusing by pressing the preview keymap again, to edit the buffer at that
-- position.

---@class outline.Preview
local Preview = {}

---@class outline.Preview
---@field buf integer
---@field win integer
---@field height integer
---@field width integer
---@field outline_height integer
---@field s outline.Sidebar
---@field conf table
---@field size_augroup integer

---@class outline.LivePreview
local LivePreview = {}

---@class outline.LivePreview
---@field win integer
---@field codewin integer
---@field codebuf integer
---@field height integer
---@field width integer
---@field outline_height integer
---@field s outline.Sidebar
---@field last_node outline.FlatSymbol
---@field initial_cursorline boolean
---@field conf table
---@field size_augroup integer

---@param conf table
function Preview:new(conf)
  if conf.live == true then
    return setmetatable({
      conf = conf,
      win = nil,
      width = nil,
      height = nil,
    }, { __index = LivePreview })
  else
    return setmetatable({
      conf = conf,
      buf = nil,
      win = nil,
      width = nil,
      height = nil,
    }, { __index = Preview })
  end
end

---Get the correct column to place the floating window based on relative
---positions of the outline and the code window.
---@param self outline.Preview|outline.LivePreview
local function calc_col(self)
  -- TODO: Re-calculate dimensions on update-preview, in case outline window
  -- was resized between last preview and next preview?
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
---@param self outline.Preview|outline.LivePreview
local function calc_row(self)
  local offset = math.floor((self.outline_height - self.height) / 2) - 1
  return vim.api.nvim_win_get_position(self.s.view.win)[1] + offset
end

---@param self outline.Preview|outline.LivePreview
local function update_size(self)
  if self.size_augroup and (not self.win or not vim.api.nvim_win_is_valid(self.win)) then
    vim.api.nvim_del_augroup_by_id(self.size_augroup)
    self.win = nil
    self.buf = nil
    self.size_augroup = nil
    return
  end

  self.outline_height = vim.api.nvim_win_get_height(self.s.view.win)
  self.width = cfg.get_preview_width(self.conf)
  self.height = cfg.get_preview_height(self.conf, self.outline_height)
  local row = calc_row(self)
  local col = calc_col(self)
  vim.api.nvim_win_set_config(self.win, {
    height = self.height,
    width = self.width,
    row = row,
    col = col,
    relative = 'editor',
  })
end

function Preview:create()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_attach(self.buf, false, {
    on_detach = function()
      self.buf = nil
      self.win = nil
    end,
  })
  self.outline_height = vim.api.nvim_win_get_height(self.s.view.win)
  self.width = cfg.get_preview_width(self.conf)
  self.height = cfg.get_preview_height(self.conf, self.outline_height)
  self.win = vim.api.nvim_open_win(self.buf, false, {
    relative = 'editor',
    height = self.height,
    width = self.width,
    bufpos = { 0, 0 },
    col = calc_col(self),
    row = calc_row(self),
    border = self.conf.border,
    focusable = false,
  })
  self:setup()
  self:update()

  if self.conf.auto_preview then
    self.size_augroup = vim.api.nvim_create_augroup('outline_' .. self.s.id .. '_preview_size', {
      clear = true,
    })
    vim.api.nvim_create_autocmd('WinResized', {
      -- XXX: Using view.win doesn't work here?
      pattern = tostring(self.s.code.win),
      group = self.size_augroup,
      callback = function()
        update_size(self)
      end,
    })
  end
end

---Set buf & win options, and setup highlight
function Preview:setup()
  vim.api.nvim_win_set_option(self.win, 'winhl', self.conf.winhl)
  vim.api.nvim_win_set_option(self.win, 'winblend', self.conf.winblend)

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
  vim.api.nvim_buf_set_option(self.buf, 'modifiable', false)
  vim.api.nvim_win_set_option(self.win, 'cursorline', true)
end

function Preview:update()
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

  if not vim.api.nvim_win_is_valid(self.s.code.win) or not self.s.provider then
    return
  end

  if not self.buf or not self.win then
    self:create()
  else
    self:update()
  end
end

function Preview:close()
  if self.win ~= nil and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
  end
end

function Preview:toggle()
  if self.win ~= nil then
    self:close()
  else
    self:show()
  end
end

---Creates new preview window and sets the content. Calls setup and set_lines.
function LivePreview:create()
  self.codewin = self.s.code.win
  self.initial_cursorline = vim.api.nvim_win_get_option(self.s.code.win, 'cursorline')
  self.outline_height = vim.api.nvim_win_get_height(self.s.view.win)
  self.width = cfg.get_preview_width(self.conf)
  self.height = cfg.get_preview_height(self.conf, self.outline_height)
  self.win = vim.api.nvim_open_win(self.s.code.buf, false, {
    relative = 'editor',
    height = self.height,
    width = self.width,
    bufpos = { 0, 0 },
    col = calc_col(self),
    row = calc_row(self),
    border = self.conf.border,
    -- Setting this to disallow using other methods to focus on this window,
    -- because currently the autocmds from setup() isn't triggering if user did
    -- not use close() and focus().
    focusable = false,
  })
  self:setup()
  if self.conf.auto_preview then
    self.size_augroup = vim.api.nvim_create_augroup('outline_' .. self.s.id .. '_preview_size', {
      clear = true,
    })
    vim.api.nvim_create_autocmd('WinResized', {
      -- XXX: Using view.win doesn't work here?
      pattern = tostring(self.s.code.win),
      group = self.size_augroup,
      callback = function()
        update_size(self)
      end,
    })
  end
end

---Set buf & win options, and autocmds
function LivePreview:setup()
  vim.api.nvim_win_set_option(self.win, 'winhl', self.conf.winhl)
  vim.api.nvim_win_set_option(self.win, 'winblend', self.conf.winblend)
  vim.api.nvim_win_set_option(self.win, 'cursorline', true)

  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(self.win),
    once = true,
    callback = function()
      self.s.code.win = self.codewin
      self.win = nil
    end,
  })
  vim.api.nvim_create_autocmd('WinEnter', {
    pattern = tostring(self.win),
    once = true,
    callback = function()
      -- This doesn't work at all?
      vim.api.nvim_win_set_option(self.win, 'cursorline', self.initial_cursorline)
    end,
  })
end

function LivePreview:update(node)
  vim.api.nvim_win_set_buf(self.win, self.s.code.buf)
  vim.api.nvim_win_set_cursor(self.win, { node.line + 1, node.character })
end

function LivePreview:focus()
  vim.api.nvim_set_current_win(self.win)
  -- Remove this when the autocmd for WinEnter works above
  vim.api.nvim_win_set_option(self.win, 'cursorline', self.initial_cursorline)
end

---Create, focus, or update preview
function LivePreview:show()
  if not self.s:has_focus() or #vim.api.nvim_list_wins() < 2 then
    return
  end

  if
    not vim.api.nvim_win_is_valid(self.s.code.win)
    or (self.codewin and not vim.api.nvim_win_is_valid(self.codewin))
    or not self.s.provider
  then
    return
  end

  local node = self.s:_current_node()
  if not node then
    return
  end

  if not self.win then
    self:create()
    vim.api.nvim_win_set_cursor(self.win, { node.line + 1, node.character })
    self.last_node = node
    return
  end

  if node == self.last_node and not self.conf.auto_preview then
    -- Focus is called manually through keybinding from sidebar.lua. This
    -- should only be used on second toggle_preview call in the case of no
    -- auto-preview.
    self:focus()
  else
    self:update(node)
  end

  self.last_node = node
end

function LivePreview:close()
  if self.win ~= nil then
    vim.api.nvim_win_close(self.win, true)
    -- autocmd from setup is not triggered here?
    self.win = nil
    self.s.code.win = self.codewin
  end
end

function LivePreview:toggle()
  self:show()
end

return Preview
