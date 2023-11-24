local Sidebar = require('outline.sidebar')
local cfg = require('outline.config')
local highlight = require('outline.highlight')
local providers = require('outline.providers.init')
local utils = require('outline.utils.init')

local M = {
  ---@type outline.Sidebar[]
  sidebars = {},
  ---@type outline.Sidebar
  current = nil,
}

local function setup_global_autocmd()
  if utils.table_has_content(cfg.o.outline_items.auto_update_events.items) then
    vim.api.nvim_create_autocmd(cfg.o.outline_items.auto_update_events.items, {
      pattern = '*',
      callback = function()
        M._sidebar_do('_refresh')
      end,
    })
  end
  vim.api.nvim_create_autocmd('WinEnter', {
    pattern = '*',
    callback = require('outline.preview').close,
  })
  vim.api.nvim_create_autocmd('TabClosed', {
    pattern = '*',
    callback = function(o)
      local tab = tonumber(o.file)
      local s = M.sidebars[tab]
      if s then
        s:destroy()
      end
      M.sidebars[tab] = nil
    end,
  })
end

---Obtain the sidebar object for current tabpage
---@param set_current boolean? Set to false to disable setting M.current
---@return outline.Sidebar?
function M._get_sidebar(set_current)
  local tab = vim.api.nvim_get_current_tabpage()
  local sidebar = M.sidebars[tab]
  if set_current ~= false then
    M.current = sidebar
  end
  return sidebar
end

---Run a Sidebar method by getting the sidebar of current tabpage, with args
-- NOP if sidebar not found for this tabpage.
---@param method string Must be valid
---@param args table?
---@return any return_of_method Depends on sidebar `method`
function M._sidebar_do(method, args)
  local sidebar = M._get_sidebar()
  if not sidebar then
    return
  end

  args = args or {}
  return sidebar[method](sidebar, unpack(args))
end

---Close the current outline window
function M.close_outline()
  return M._sidebar_do('close')
end

---Toggle the outline window, and return whether the outline window is open
-- after this operation.
---@see open_outline
---@param opts outline.OutlineOpts? Table of options
---@return boolean is_open Whether outline window is now open
function M.toggle_outline(opts)
  local sidebar = M._get_sidebar()
  if not sidebar then
    M.open_outline(opts)
    return true
  end
  return sidebar:toggle(opts)
end

---Set cursor to focus on the outline window, return whether the window is
-- currently open.
---@return boolean is_open Whether the window is open
function M.focus_outline()
  return M._sidebar_do('focus')
end

---Set cursor to focus on the code window, return whether this operation was successful.
---@return boolean ok Whether it was successful. If unsuccessful, it might mean that the attached code window has been closed or is no longer valid.
function M.focus_code()
  return M._sidebar_do('focus_code')
end

---Toggle focus between outline and code window, returns whether it was successful.
---@return boolean ok Whether it was successful. If `ok=false`, either the outline window is not open or the code window is no longer valid.
function M.focus_toggle()
  return M._sidebar_do('focus_toggle')
end

---Set position of outline window to match cursor position in code, return
---whether the window is just newly opened (previously not open).
---@param opts outline.OutlineOpts? Field `focus_outline` = `false` or `nil` means don't focus on outline window after following cursor. If opts is not provided, focus will be on outline window after following cursor.
---@return boolean ok Whether it was successful. If ok=false, either the outline window is not open or the code window cannot be found.
function M.follow_cursor(opts)
  return M._sidebar_do('follow_cursor', { opts })
end

---Trigger re-requesting of symbols from provider
function M.refresh_outline()
  return M._sidebar_do('__refresh')
end

---Open the outline window.
---@param opts outline.OutlineOpts? Field focus_outline=false means don't focus on outline window after opening. If opts is not provided, focus will be on outline window after opening.
function M.open_outline(opts)
  local tab = vim.api.nvim_get_current_tabpage()
  local sidebar = M.sidebars[tab]
  M.current = sidebar

  if not sidebar then
    sidebar = Sidebar:new()
    M.sidebars[tab] = sidebar
  end

  return sidebar:open(opts)
end

---@return boolean? has_focus Nil when no outline opened yet, otherwise returns whether cursor is in outline window.
function M.is_focus_in_outline()
  return M._sidebar_do('has_focus')
end

---Handle follow cursor command with bang
local function _cmd_follow_cursor(opts)
  M.follow_cursor({ focus_outline = not opts.bang })
end

---Handle open/toggle command with mods and bang
local function _cmd_open_with_mods(fn)
  return function(opts)
    local fnopts = { focus_outline = not opts.bang }
    if _G._outline_nvim_has[8] then
      local sc = opts.smods.split
      if sc ~= '' then
        fnopts.split_command = sc .. ' vsplit'
      end
    end

    fn(fnopts)
  end
end

---Open a floating window displaying debug information about outline
function M.show_status()
  local sidebar = M._get_sidebar(false)
  local buf, win = 0, 0
  local is_open

  if sidebar then
    buf = sidebar.code.buf
    win = sidebar.code.win
    is_open = sidebar.view:is_open()
  end

  ---@type outline.StatusContext
  local ctx = {
    priority = cfg.o.providers.priority,
    outline_open = is_open,
  }

  if vim.api.nvim_buf_is_valid(buf) then
    ctx.ft = vim.api.nvim_buf_get_option(buf, 'ft')
    ctx.filter = cfg.o.symbols.user_config_filter[ctx.ft]
    -- 'else' is handled in docs.lua
  end

  ctx.default_filter = cfg.o.symbols.user_config_filter.default

  local p = _G._outline_current_provider
  if not is_open then
    p = providers.find_provider()
  end

  if p ~= nil then
    ctx.provider = p
    -- Just show code window is active when the first outline in this tabpage
    -- has not yet been opened.
    if not sidebar then
      ctx.code_win_active = true
    else
      ctx.code_win_active = require('outline.preview').has_code_win(win)
    end
  end

  return require('outline.docs').show_status(ctx)
end

local function setup_commands()
  local cmd = function(n, c, o)
    vim.api.nvim_create_user_command('Outline' .. n, c, o)
  end

  cmd('', _cmd_open_with_mods(M.toggle_outline), {
    desc = 'Toggle the outline window. \
With bang, keep focus on initial window after opening.',
    nargs = 0,
    bang = true,
  })
  cmd('Open', _cmd_open_with_mods(M.open_outline), {
    desc = 'With bang, keep focus on initial window after opening.',
    nargs = 0,
    bang = true,
  })
  cmd('Close', M.close_outline, { nargs = 0 })
  cmd('FocusOutline', M.focus_outline, { nargs = 0 })
  cmd('FocusCode', M.focus_code, { nargs = 0 })
  cmd('Focus', M.focus_toggle, { nargs = 0 })
  cmd('Status', M.show_status, {
    desc = 'Show a message about the current status of the outline window.',
    nargs = 0,
  })
  cmd('Follow', _cmd_follow_cursor, {
    desc = "Update position of outline with position of cursor. \
With bang, don't switch cursor focus to outline window.",
    nargs = 0,
    bang = true,
  })
  cmd('Refresh', M.refresh_outline, {
    desc = 'Trigger manual outline refresh of items.',
    nargs = 0,
  })
end

---Set up configuration options for outline.
function M.setup(opts)
  local minor = vim.version().minor

  if minor < 7 then
    vim.notify('outline.nvim requires nvim-0.7 or higher!', vim.log.levels.ERROR)
    return
  end

  _G._outline_nvim_has = {
    [8] = minor >= 8,
    [9] = minor >= 9,
  }

  cfg.setup(opts)
  highlight.setup_highlights()

  setup_global_autocmd()
  setup_commands()
end

return M
