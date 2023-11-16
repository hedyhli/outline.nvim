local parser = require 'outline.parser'
local providers = require 'outline.providers.init'
local ui = require 'outline.ui'
local writer = require 'outline.writer'
local cfg = require 'outline.config'
local utils = require 'outline.utils.init'
local View = require 'outline.view'
local folding = require 'outline.folding'

local M = {}

local function setup_global_autocmd()
  if
    cfg.o.outline_items.highlight_hovered_item or cfg.o.symbol_folding.auto_unfold_hover
  then
    vim.api.nvim_create_autocmd('CursorHold', {
      pattern = '*',
      callback = function()
        M._highlight_current_item(nil)
      end,
    })
  end

  vim.api.nvim_create_autocmd({
    'InsertLeave',
    'WinEnter',
    'BufEnter',
    'BufWinEnter',
    'TabEnter',
    'BufWritePost',
  }, {
    pattern = '*',
    callback = M._refresh,
  })

  vim.api.nvim_create_autocmd('WinEnter', {
    pattern = '*',
    callback = require('outline.preview').close,
  })
end

-------------------------
-- STATE
-------------------------
M.state = {
  ---@type outline.SymbolNode[]
  outline_items = {},
  ---@type outline.FlatSymbolNode[]
  flattened_outline_items = {},
  code_win = 0,
  -- In case unhide_cursor was called before hide_cursor for _some_ reason,
  -- this can still be used as a fallback
  original_cursor = vim.o.guicursor,
}

local function wipe_state()
  M.state = { outline_items = {}, flattened_outline_items = {}, code_win = 0, opts = {} }
end

local function _update_lines()
  M.state.flattened_outline_items = writer.make_outline(M.view.bufnr, M.state.outline_items, M.state.code_win)
end

---@param items outline.SymbolNode[]
local function _merge_items(items)
  utils.merge_items_rec(
    { children = items },
    { children = M.state.outline_items }
  )
end

local function __refresh()
  local current_buffer_is_outline = M.view.bufnr
    == vim.api.nvim_get_current_buf()
  if M.view:is_open() and not current_buffer_is_outline then
    local function refresh_handler(response)
      if response == nil or type(response) ~= 'table' then
        return
      end

      local items = parser.parse(response)
      _merge_items(items)

      M.state.code_win = vim.api.nvim_get_current_win()

      _update_lines()
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
  vim.api.nvim_win_set_cursor(
    M.state.code_win,
    { node.line + 1, node.character }
  )
  utils.flash_highlight(M.state.code_win, node.line + 1, true)
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

local function hide_cursor()
  -- Set cursor color to CursorLine in normal mode
  M.state.original_cursor = vim.o.guicursor
  local cur = vim.o.guicursor:match("n.-:(.-)[-,]")
  vim.opt.guicursor:append("n:"..cur.."-Cursorline")
end

local function unhide_cursor()
  -- vim.opt doesn't seem to provide a way to remove last item, like a pop()
  -- vim.o.guicursor = vim.o.guicursor:gsub(",n.-:.-$", "")
  vim.o.guicursor = M.state.original_cursor
end

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
      end
    })
  end
  if cfg.o.outline_window.hide_cursor then
    -- Unfortunately guicursor is a global option, so we have to make sure to
    -- set and unset when cursor leaves the outline window.
    hide_cursor()
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = 0,
      callback = hide_cursor
    })
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = 0,
      callback = unhide_cursor
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

    _update_lines()
  elseif node.parent then
    local parent_node =
      M.state.flattened_outline_items[node.parent.line_in_outline]

    if parent_node then
      M._set_folded(
        folded,
        not parent_node.folded and folded,
        parent_node.line_in_outline
      )
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

  while #stack > 0 do
    local current_nodes = table.remove(stack, #stack)
    for _, node in ipairs(current_nodes) do
      node.folded = folded
      if node.children then
        stack[#stack + 1] = node.children
      end
    end
  end

  _update_lines()
end

---@param winnr? integer Window number of code window
function M._highlight_current_item(winnr)
  local has_provider = M.has_provider()
  local has_outline_open = M.view:is_open()
  local current_buffer_is_outline = M.view.bufnr
    == vim.api.nvim_get_current_buf()

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

  -- TODO: Find an efficient way to:
  -- 1) Set highlight for all nodes in range (regardless of visibility)
  -- 2) Find the line number of the deepest node in range, that is visible (no
  --    parents folded)
  -- In one go

  local win = winnr or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)

  local hovered_line = vim.api.nvim_win_get_cursor(win)[1] - 1
  local parent_nodes = {}

  -- Must not skip folded nodes so that when user unfolds a parent, they can see the leaf
  -- node highlighted.
  for value in parser.preorder_iter(M.state.outline_items, function() return true end) do
    value.hovered = nil

    if
      value.line == hovered_line
      or (hovered_line >= value.range_start and hovered_line <= value.range_end)
    then
      value.hovered = true
      table.insert(parent_nodes, value)
    end
  end

  if #parent_nodes == 0 then
    return
  end

  -- Probably can't 'just' writer.add_hover_highlights here because we might
  -- want to auto_unfold_hover
  _update_lines()

  -- Put cursor on deepest visible match
  local col = 0
  if cfg.o.outline_items.show_symbol_lineno then
    -- Padding area between lineno column and start of guides
    col = #tostring(vim.api.nvim_buf_line_count(buf) - 1)
  end
  local flats = M.state.flattened_outline_items
  local found = false
  local find_node

  while #parent_nodes > 0 and not found do
    find_node = table.remove(parent_nodes, #parent_nodes)
    -- TODO: Is it feasible to use binary search here?
    for line, node in ipairs(flats) do
      if node == find_node then
        vim.api.nvim_win_set_cursor(M.view.winnr, { line, col })
        found = true
        break
      end
    end
  end
end

local function setup_keymaps(bufnr)
  local map = function(...)
    utils.nmap(bufnr, ...)
  end
  -- goto_location of symbol and focus that window
  map(cfg.o.keymaps.goto_location, function()
    M._goto_location(true)
  end)
  -- goto_location of symbol but stay in outline
  map(cfg.o.keymaps.peek_location, function()
    M._goto_location(false)
  end)
  -- Navigate to corresponding outline location for current code location
  map(cfg.o.keymaps.restore_location, M._map_follow_cursor)
  -- Navigate to corresponding outline location for current code location
  map(cfg.o.keymaps.goto_and_close, M._goto_and_close)
  -- Move down/up in outline and peek that location in code
  map(cfg.o.keymaps.down_and_jump, function()
    M._move_and_jump('down')
  end)
  -- Move down/up in outline and peek that location in code
  map(cfg.o.keymaps.up_and_jump, function()
    M._move_and_jump('up')
  end)
  -- hover symbol
  map(
    cfg.o.keymaps.hover_symbol,
    require('outline.hover').show_hover
  )
  -- preview symbol
  map(
    cfg.o.keymaps.toggle_preview,
    require('outline.preview').toggle
  )
  -- rename symbol
  map(
    cfg.o.keymaps.rename_symbol,
    require('outline.rename').rename
  )
  -- code actions
  map(
    cfg.o.keymaps.code_actions,
    require('outline.code_action').show_code_actions
  )
  -- show help
  map(
    cfg.o.keymaps.show_help,
    require('outline.config').show_help
  )
  -- close outline
  map(cfg.o.keymaps.close, function()
    M.view:close()
  end)
  -- toggle fold selection
  map(cfg.o.keymaps.fold_toggle, M._toggle_fold)
  -- fold selection
  map(cfg.o.keymaps.fold, function()
    M._set_folded(true)
  end)
  -- unfold selection
  map(cfg.o.keymaps.unfold, function()
    M._set_folded(false)
  end)
  -- toggle fold all
  map(cfg.o.keymaps.fold_toggle_all, M._toggle_all_fold)
  -- fold all
  map(cfg.o.keymaps.fold_all, function()
    M._set_all_folded(true)
  end)
  -- unfold all
  map(cfg.o.keymaps.unfold_all, function()
    M._set_all_folded(false)
  end)
  -- fold reset
  map(cfg.o.keymaps.fold_reset, function()
    M._set_all_folded(nil)
  end)
end

---@param response table?
---@param opts outline.OutlineOpts?
local function handler(response, opts)
  if response == nil or type(response) ~= 'table' or M.view:is_open() then
    return
  end

  M.state.code_win = vim.api.nvim_get_current_win()

  if opts and opts.on_symbols then
    opts.on_symbols()
  end

  M.view:setup_view()

  if opts and opts.on_outline_setup then
    opts.on_outline_setup()
  end

  -- clear state when buffer is closed
  vim.api.nvim_buf_attach(M.view.bufnr, false, {
    on_detach = function(_, _)
      wipe_state()
    end,
  })

  setup_keymaps(M.view.bufnr)
  setup_buffer_autocmd()

  local items = parser.parse(response)

  M.state.outline_items = items
  M.state.flattened_outline_items = writer.make_outline(M.view.bufnr, items, M.state.code_win)

  M._highlight_current_item(M.state.code_win)

  if not cfg.o.outline_window.focus_on_open or (opts and not opts.focus_outline) then
    vim.fn.win_gotoid(M.state.code_win)
  end
end

---@class outline.OutlineOpts
---@field focus_outline boolean?
---@field on_symbols function?
---@field on_outline_setup function?

---Set position of outline window to match cursor position in code, return
---whether the window is just newly opened (previously not open).
---@param opts outline.OutlineOpts? Field `focus_outline` = `false` or `nil` means don't focus on outline window after following cursor. If opts is not provided, focus will be on outline window after following cursor.
---@return boolean ok Whether it was successful. If ok=false, either the outline window is not open or the code window cannot be found.
function M.follow_cursor(opts)
  if not M.view:is_open() then
    return false
  end

  if require('outline.preview').has_code_win() then
    M._highlight_current_item(M.state.code_win)
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
    utils.echo(
      "Code window no longer active. Try closing and reopening the outline."
    )
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
    local old_sc, use_old_sc
    local split = opts.smods.split
    if split ~= "" then
      old_sc = cfg.o.outline_window.split_command
      use_old_sc = true
      cfg.o.outline_window.split_command = split .. ' vsplit'
    end

    local function on_outline_setup()
      if use_old_sc then
        cfg.o.outline_window.split_command = old_sc
        -- the old option should already have been resolved during set up
      end
    end

    if opts.bang then
      fn({ focus_outline = false, on_outline_setup = on_outline_setup })
    else
      fn({ focus_outline = true, on_outline_setup = on_outline_setup })
    end

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
      utils.echo("No providers found for current buffer")
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

---Display outline window status in the message area.
function M.show_status()
  -- TODO: Use a floating window instead
  local p = _G._outline_current_provider
  if not M.is_active() then
    p = providers.find_provider()
  end

  if p ~= nil then
    print("Current provider: " .. p.name)
    if p.get_status then
      print(p.get_status())
      print()
    end

    if M.view:is_open() then
      print("Outline window is open.")
    else
      print("Outline window is not open.")
    end

    if require('outline.preview').has_code_win() then
      print("Code window is active.")
    else
      print("Code window is either closed or invalid. Please close and reopen the outline window.")
    end
  else
    print("No providers")
  end
end

function M.is_active()
  local winid = vim.fn.win_getid()
  if M.view:is_open() and winid == M.view.winnr then
    return true
  end
  return false
end

---Whether there is currently an available provider.
---@return boolean has_provider
function M.has_provider()
  if M.is_active() then
    return _G._outline_current_provider ~= nil
  end
  return providers.has_provider()
end

local function setup_commands()
  local cmd = function(n, c, o)
    vim.api.nvim_create_user_command('Outline'..n, c, o)
  end

  cmd('', _cmd_open_with_mods(M.toggle_outline), {
    desc = "Toggle the outline window. \
With bang, keep focus on initial window after opening.",
    nargs = 0,
    bang = true,
  })
  cmd('Open', _cmd_open_with_mods(M.open_outline), {
    desc = "With bang, keep focus on initial window after opening.",
    nargs = 0,
    bang = true,
  })
  cmd('Close', M.close_outline, { nargs = 0 })
  cmd('FocusOutline', M.focus_outline, { nargs = 0 })
  cmd('FocusCode', M.focus_code, { nargs = 0 })
  cmd('Focus', M.focus_toggle, { nargs = 0 })
  cmd('Status', M.show_status, {
    desc = "Show a message about the current status of the outline window.",
    nargs = 0,
  })
  cmd('Follow', _cmd_follow_cursor, {
    desc = "Update position of outline with position of cursor. \
With bang, don't switch cursor focus to outline window.",
    nargs = 0,
    bang = true,
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
