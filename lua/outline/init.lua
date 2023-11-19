local View = require('outline.view')
local cfg = require('outline.config')
local folding = require('outline.folding')
local parser = require('outline.parser')
local providers = require('outline.providers.init')
local ui = require('outline.ui')
local utils = require('outline.utils.init')
local writer = require('outline.writer')

local M = {}

local function setup_global_autocmd()
  if utils.table_has_content(cfg.o.outline_items.auto_update_events.items) then
    vim.api.nvim_create_autocmd(cfg.o.outline_items.auto_update_events.items, {
      pattern = '*',
      callback = M._refresh,
    })
  end
  vim.api.nvim_create_autocmd('WinEnter', {
    pattern = '*',
    callback = require('outline.preview').close,
  })
end

-------------------------
-- STATE
-------------------------
M.state = {
  opened_first_outline = false,
  ---@type outline.SymbolNode[]
  outline_items = {},
  ---@type outline.FlatSymbolNode[]
  flattened_outline_items = {},
  code_win = 0,
  code_buf = 0,
  autocmds = {},
  -- In case unhide_cursor was called before hide_cursor for _some_ reason,
  -- this can still be used as a fallback
  original_cursor = vim.o.guicursor,
}

local function wipe_state()
  for _, code_win in ipairs(M.state.autocmds) do
    if vim.api.nvim_win_is_valid(code_win) and M.state.autocmds[code_win] then
      vim.api.nvim_del_autocmd(M.state.autocmds[code_win])
    end
  end

  M.state = {
    outline_items = {},
    flattened_outline_items = {},
    code_win = 0,
    code_buf = 0,
    autocmds = {},
    opts = {},
  }
end

---Calls writer.make_outline and then calls M.update_cursor_pos if update_cursor is not false
---@param update_cursor boolean?
---@param set_cursor_to_node outline.SymbolNode|outline.FlatSymbolNode?
local function _update_lines(update_cursor, set_cursor_to_node)
  local current
  M.state.flattened_outline_items, current =
    writer.make_outline(M.view.bufnr, M.state.outline_items, M.state.code_win, set_cursor_to_node)
  if update_cursor ~= false then
    M.update_cursor_pos(current)
  end
end

---@param items outline.SymbolNode[]
local function _merge_items(items)
  utils.merge_items_rec({ children = items }, { children = M.state.outline_items })
end

---Setup autocmds for the buffer that the outline attached to
---@param code_win integer Must be valid
---@param code_buf integer Must be valid
local function setup_attached_buffer_autocmd(code_win, code_buf)
  local events = cfg.o.outline_items.auto_update_events
  if cfg.o.outline_items.highlight_hovered_item or cfg.o.symbol_folding.auto_unfold_hover then
    if M.state.autocmds[code_win] then
      vim.api.nvim_del_autocmd(M.state.autocmds[code_win])
      M.state.autocmds[code_win] = nil
    end

    if utils.str_or_nonempty_table(events.follow) then
      M.state.autocmds[code_win] = vim.api.nvim_create_autocmd(events.follow, {
        buffer = code_buf,
        callback = function()
          M._highlight_current_item(code_win, cfg.o.outline_items.auto_set_cursor)
        end,
      })
    end
  end
end

local function __refresh()
  local current_buffer_is_outline = M.view.bufnr == vim.api.nvim_get_current_buf()
  if M.view:is_open() and not current_buffer_is_outline then
    local function refresh_handler(response)
      if response == nil or type(response) ~= 'table' then
        return
      end

      local curwin = vim.api.nvim_get_current_win()
      local curbuf = vim.api.nvim_get_current_buf()
      local newbuf = curbuf ~= M.state.code_buf

      if M.state.code_win ~= curwin then
        if M.state.autocmds[M.state.code_win] then
          vim.api.nvim_del_autocmd(M.state.autocmds[M.state.code_win])
          M.state.autocmds[M.state.code_win] = nil
        end
      end

      M.state.code_win = curwin
      M.state.code_buf = curbuf

      setup_attached_buffer_autocmd(curwin, curbuf)

      local items = parser.parse(response, vim.api.nvim_get_current_buf())
      _merge_items(items)

      local update_cursor = newbuf or cfg.o.outline_items.auto_set_cursor
      _update_lines(update_cursor)
    end

    providers.request_symbols(refresh_handler)
  end
end

M._refresh = utils.debounce(__refresh, 100)

---@return outline.FlatSymbolNode
function M._current_node()
  local current_line = vim.api.nvim_win_get_cursor(M.view.winnr)[1]
  return M.state.flattened_outline_items[current_line]
end

---@param change_focus boolean
function M.__goto_location(change_focus)
  local node = M._current_node()
  vim.api.nvim_win_set_cursor(M.state.code_win, { node.line + 1, node.character })
  if cfg.o.outline_window.center_on_jump then
    vim.fn.win_execute(M.state.code_win, 'normal! zz')
  end

  if vim.fn.hlexists('OutlineJumpHighlight') == 0 then
    vim.api.nvim_set_hl(0, 'OutlineJumpHighlight', { link = 'Visual' })
  end
  utils.flash_highlight(
    M.state.code_win,
    node.line + 1,
    cfg.o.outline_window.jump_highlight_duration,
    'OutlineJumpHighlight'
  )

  if change_focus then
    vim.fn.win_gotoid(M.state.code_win)
  end
end

---Wraps __goto_location and handles auto_close.
---@see __goto_location
---@param change_focus boolean
function M._goto_location(change_focus)
  M.__goto_location(change_focus)
  if change_focus and cfg.o.outline_window.auto_close then
    M.close_outline()
  end
end

function M._goto_and_close()
  M.__goto_location(true)
  M.close_outline()
end

---@param direction "up"|"down"
function M._move_and_jump(direction)
  local move = direction == 'down' and 1 or -1
  local cur = vim.api.nvim_win_get_cursor(0)
  cur[1] = cur[1] + move
  pcall(vim.api.nvim_win_set_cursor, 0, cur)
  M.__goto_location(false)
end

---@param move_cursor boolean
---@param node_index integer Index for M.state.flattened_outline_items
function M._toggle_fold(move_cursor, node_index)
  local node = M.state.flattened_outline_items[node_index] or M._current_node()
  local is_folded = folding.is_folded(node)

  if folding.is_foldable(node) then
    M._set_folded(not is_folded, move_cursor, node_index)
  end
end

local function update_cursor_style()
  local cl = cfg.o.outline_window.show_cursorline
  -- XXX: Still 'hide' cursor if show_cursorline set to false, because we've
  -- already warned the user during setup.
  local hide_cursor = type(cl) ~= 'string'

  if cl == 'focus_in_outline' or cl == 'focus_in_code' then
    vim.api.nvim_win_set_option(0, 'cursorline', cl == 'focus_in_outline')
    hide_cursor = cl == 'focus_in_outline'
  end

  -- Set cursor color to CursorLine in normal mode
  if hide_cursor then
    M.state.original_cursor = vim.o.guicursor
    local cur = vim.o.guicursor:match('n.-:(.-)[-,]')
    vim.opt.guicursor:append('n:' .. cur .. '-Cursorline')
  end
end

local function reset_cursor_style()
  local cl = cfg.o.outline_window.show_cursorline

  if cl == 'focus_in_outline' or cl == 'focus_in_code' then
    vim.api.nvim_win_set_option(0, 'cursorline', cl ~= 'focus_in_outline')
  end
  -- vim.opt doesn't seem to provide a way to remove last item, like a pop()
  -- vim.o.guicursor = vim.o.guicursor:gsub(",n.-:.-$", "")
  vim.o.guicursor = M.state.original_cursor
end

---Autocmds for the (current) outline buffer
local function setup_buffer_autocmd()
  if cfg.o.preview_window.auto_preview then
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = require('outline.preview').show,
    })
  else
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = require('outline.preview').close,
    })
  end
  if cfg.o.outline_window.auto_jump then
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = function()
        -- Don't use _goto_location because we don't want to auto-close
        M.__goto_location(false)
      end,
    })
  end
  if cfg.o.outline_window.hide_cursor or type(cfg.o.outline_window.show_cursorline) == 'string' then
    -- Unfortunately guicursor is a global option, so we have to make sure to
    -- set and unset when cursor leaves the outline window.
    update_cursor_style()
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = 0,
      callback = update_cursor_style,
    })
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = 0,
      callback = reset_cursor_style,
    })
  end
end

---@param folded boolean
---@param move_cursor? boolean
---@param node_index? integer
function M._set_folded(folded, move_cursor, node_index)
  local node = M.state.flattened_outline_items[node_index] or M._current_node()
  local changed = (folded ~= folding.is_folded(node))

  if folding.is_foldable(node) and changed then
    node.folded = folded

    if move_cursor then
      vim.api.nvim_win_set_cursor(M.view.winnr, { node_index, 0 })
    end

    _update_lines(false)
  elseif node.parent then
    local parent_node = M.state.flattened_outline_items[node.parent.line_in_outline]

    if parent_node then
      M._set_folded(folded, not parent_node.folded and folded, parent_node.line_in_outline)
    end
  end
end

---@param nodes outline.SymbolNode[]
function M._toggle_all_fold(nodes)
  nodes = nodes or M.state.outline_items
  local folded = true

  for _, node in ipairs(nodes) do
    if folding.is_foldable(node) and not folding.is_folded(node) then
      folded = false
      break
    end
  end

  M._set_all_folded(not folded, nodes)
end

---@param folded boolean|nil
---@param nodes? outline.SymbolNode[]
function M._set_all_folded(folded, nodes)
  local stack = { nodes or M.state.outline_items }
  local current = M._current_node()

  while #stack > 0 do
    local current_nodes = table.remove(stack, #stack)
    for _, node in ipairs(current_nodes) do
      node.folded = folded
      if node.children then
        stack[#stack + 1] = node.children
      end
    end
  end

  _update_lines(true, current)
end

---@param winnr? integer Window number of code window
---@param update_cursor? boolean
function M._highlight_current_item(winnr, update_cursor)
  local has_provider = M.has_provider()
  local has_outline_open = M.view:is_open()
  local current_buffer_is_outline = M.view.bufnr == vim.api.nvim_get_current_buf()

  if not has_provider then
    return
  end

  if current_buffer_is_outline and not winnr then
    -- Don't update cursor pos and content if they are navigating the outline.
    -- Winnr may be given when user explicitly wants to restore location
    -- (follow_cursor), or through the open handler.
    return
  end

  if not has_outline_open and not winnr then
    -- Outline not open and no code window given
    return
  end

  local valid_code_win = vim.api.nvim_win_is_valid(M.state.code_win)
  local valid_winnr = winnr and vim.api.nvim_win_is_valid(winnr)

  if not valid_code_win then
    -- Definetely don't attempt to update anything if code win is no longer valid
    return
  end

  if not valid_winnr then
    return
  elseif winnr ~= M.state.code_win then
    -- Both valid, but given winnr ~= known code_win.
    -- Best not to handle this situation at all to prevent any unwanted side
    -- effects
    return
  end

  _update_lines(update_cursor)
end

local function setup_keymaps(bufnr)
  local map = function(...)
    utils.nmap(bufnr, ...)
  end
  map(cfg.o.keymaps.goto_location, function()
    M._goto_location(true)
  end)
  map(cfg.o.keymaps.peek_location, function()
    M._goto_location(false)
  end)
  map(cfg.o.keymaps.restore_location, M._map_follow_cursor)
  map(cfg.o.keymaps.goto_and_close, M._goto_and_close)
  map(cfg.o.keymaps.down_and_jump, function()
    M._move_and_jump('down')
  end)
  map(cfg.o.keymaps.up_and_jump, function()
    M._move_and_jump('up')
  end)
  map(cfg.o.keymaps.hover_symbol, require('outline.hover').show_hover)
  map(cfg.o.keymaps.toggle_preview, require('outline.preview').toggle)
  map(cfg.o.keymaps.rename_symbol, require('outline.rename').rename)
  map(cfg.o.keymaps.code_actions, require('outline.code_action').show_code_actions)
  map(cfg.o.keymaps.show_help, require('outline.docs').show_help)
  map(cfg.o.keymaps.close, function()
    M.view:close()
  end)
  map(cfg.o.keymaps.fold_toggle, M._toggle_fold)
  map(cfg.o.keymaps.fold, function()
    M._set_folded(true)
  end)
  map(cfg.o.keymaps.unfold, function()
    M._set_folded(false)
  end)
  map(cfg.o.keymaps.fold_toggle_all, M._toggle_all_fold)
  map(cfg.o.keymaps.fold_all, function()
    M._set_all_folded(true)
  end)
  map(cfg.o.keymaps.unfold_all, function()
    M._set_all_folded(false)
  end)
  map(cfg.o.keymaps.fold_reset, function()
    M._set_all_folded(nil)
  end)
end

---@param current outline.FlatSymbolNode?
function M.update_cursor_pos(current)
  local col = 0
  local buf = vim.api.nvim_win_get_buf(M.state.code_win)
  if cfg.o.outline_items.show_symbol_lineno then
    -- Padding area between lineno column and start of guides
    col = #tostring(vim.api.nvim_buf_line_count(buf) - 1)
  end
  if current then -- Don't attempt to set cursor if the matching node is not found
    vim.api.nvim_win_set_cursor(M.view.winnr, { current.line_in_outline, col })
  end
end

---@param response table?
---@param opts outline.OutlineOpts?
local function handler(response, opts)
  if response == nil or type(response) ~= 'table' or M.view:is_open() then
    return
  end

  if not opts then
    opts = {}
  end

  M.state.code_win = vim.api.nvim_get_current_win()
  M.state.code_buf = vim.api.nvim_get_current_buf()
  M.state.opened_first_outline = true

  local sc = opts.split_command or cfg.get_split_command()
  M.view:setup_view(sc)

  -- clear state when buffer is closed
  vim.api.nvim_buf_attach(M.view.bufnr, false, {
    on_detach = function(_, _)
      wipe_state()
    end,
  })

  setup_keymaps(M.view.bufnr)
  setup_buffer_autocmd()
  setup_attached_buffer_autocmd(M.state.code_win, M.state.code_buf)

  local items = parser.parse(response, M.state.code_buf)

  M.state.outline_items = items
  local current
  M.state.flattened_outline_items, current =
    writer.make_outline(M.view.bufnr, items, M.state.code_win)

  M.update_cursor_pos(current)

  if not cfg.o.outline_window.focus_on_open or not opts.focus_outline then
    vim.fn.win_gotoid(M.state.code_win)
  end
end

---Set position of outline window to match cursor position in code, return
---whether the window is just newly opened (previously not open).
---@param opts outline.OutlineOpts? Field `focus_outline` = `false` or `nil` means don't focus on outline window after following cursor. If opts is not provided, focus will be on outline window after following cursor.
---@return boolean ok Whether it was successful. If ok=false, either the outline window is not open or the code window cannot be found.
function M.follow_cursor(opts)
  if not M.view:is_open() then
    return false
  end

  if require('outline.preview').has_code_win() then
    M._highlight_current_item(M.state.code_win, true)
  else
    return false
  end

  if not opts then
    opts = { focus_outline = true }
  end
  if opts.focus_outline then
    M.focus_outline()
  end

  return true
end

local function _cmd_follow_cursor(opts)
  local fnopts = { focus_outline = true }
  if opts.bang then
    fnopts.focus_outline = false
  end
  M.follow_cursor(fnopts)
end

function M._map_follow_cursor()
  if not M.follow_cursor({ focus_outline = true }) then
    utils.echo('Code window no longer active. Try closing and reopening the outline.')
  end
end

---Toggle the outline window, and return whether the outline window is open
---after this operation.
---@see open_outline
---@param opts outline.OutlineOpts? Table of options
---@return boolean is_open Whether outline window is open
function M.toggle_outline(opts)
  if M.view:is_open() then
    M.close_outline()
    return false
  else
    M.open_outline(opts)
    return true
  end
end

local function _cmd_open_with_mods(fn)
  return function(opts)
    local fnopts = { focus_outline = not opts.bang }
    local sc = opts.smods.split
    if sc ~= '' then
      fnopts.split_command = sc .. ' vsplit'
    end

    fn(fnopts)
  end
end

---Open the outline window.
---@param opts outline.OutlineOpts? Field focus_outline=false means don't focus on outline window after opening. If opts is not provided, focus will be on outline window after opening.
function M.open_outline(opts)
  if not opts then
    opts = { focus_outline = true }
  end
  if not M.view:is_open() then
    local found = providers.request_symbols(handler, opts)
    if not found then
      utils.echo('No providers found for current buffer')
    end
  end
end

---Close the outline window.
function M.close_outline()
  M.view:close()
end

---Set cursor to focus on the outline window, return whether the window is currently open..
---@return boolean is_open Whether the window is open
function M.focus_outline()
  if M.view:is_open() then
    vim.fn.win_gotoid(M.view.winnr)
    return true
  end
  return false
end

---Set cursor to focus on the code window, return whether this operation was successful.
---@return boolean ok Whether it was successful. If unsuccessful, it might mean that the attached code window has been closed or is no longer valid.
function M.focus_code()
  if require('outline.preview').has_code_win() then
    vim.fn.win_gotoid(M.state.code_win)
    return true
  end
  return false
end

---Toggle focus between outline and code window, returns whether it was successful.
---@return boolean ok Whether it was successful. If `ok=false`, either the outline window is not open or the code window is no longer valid.
function M.focus_toggle()
  if M.view:is_open() and require('outline.preview').has_code_win() then
    local winid = vim.fn.win_getid()
    if winid == M.state.code_win then
      vim.fn.win_gotoid(M.view.winnr)
    else
      vim.fn.win_gotoid(M.state.code_win)
    end
    return true
  end
  return false
end

---Whether the outline window is currently open.
---@return boolean is_open
function M.is_open()
  return M.view:is_open()
end

function M.is_focus_in_outline()
  local winid = vim.fn.win_getid()
  if M.view:is_open() and winid == M.view.winnr then
    return true
  end
  return false
end

---Whether there is currently an available provider.
---@return boolean has_provider
function M.has_provider()
  if M.is_focus_in_outline() then
    return _G._outline_current_provider ~= nil
  end
  return providers.has_provider()
end

function M.show_status()
  ---@type outline.StatusContext
  local ctx = { priority = cfg.o.providers.priority }

  if vim.api.nvim_buf_is_valid(M.state.code_buf) then
    ctx.ft = vim.api.nvim_buf_get_option(M.state.code_buf, 'ft')
  end
  ctx.filter = cfg.o.symbols.user_config_filter[ctx.ft]
  ctx.default_filter = cfg.o.symbols.user_config_filter.default

  local p = _G._outline_current_provider
  if not M.view or not M.view:is_open() then
    p = providers.find_provider()
  end

  if p ~= nil then
    ctx.provider = p
    ctx.outline_open = false
    if M.view and M.view:is_open() then
      ctx.outline_open = true
    end
    ctx.code_win_active = false
    if require('outline.preview').has_code_win() then
      ctx.code_win_active = true
    end
  end

  return require('outline.docs').show_status(ctx)
end

---Re-request symbols from the provider and update the outline accordingly
function M.refresh_outline()
  return __refresh()
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
  cmd('Refresh', __refresh, {
    desc = 'Trigger manual outline refresh of items.',
    nargs = 0,
  })
end

---Set up configuration options for outline.
function M.setup(opts)
  cfg.setup(opts)
  ui.setup_highlights()

  M.view = View:new()
  setup_global_autocmd()
  setup_commands()
end

return M
