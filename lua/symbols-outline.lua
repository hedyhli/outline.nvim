local parser = require 'symbols-outline.parser'
local providers = require 'symbols-outline.providers.init'
local ui = require 'symbols-outline.ui'
local writer = require 'symbols-outline.writer'
local config = require 'symbols-outline.config'
local utils = require 'symbols-outline.utils.init'
local View = require 'symbols-outline.view'
local folding = require 'symbols-outline.folding'

local M = {}

local function setup_global_autocmd()
  if
    config.options.highlight_hovered_item or config.options.auto_unfold_hover
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
    callback = require('symbols-outline.preview').close,
  })
end

local function setup_buffer_autocmd()
  if config.options.auto_preview then
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = require('symbols-outline.preview').show,
    })
  else
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = require('symbols-outline.preview').close,
    })
  end
end

local function setup_commands()
  local cmd = function(n, c, o) vim.api.nvim_create_user_command('SymbolsOutline'..n, c, o) end
  cmd('', M.toggle_outline, { nargs = 0, bang = true })
  cmd('Open', M.open_outline, { nargs = 0, bang = true })
  cmd('Close', M.close_outline, { nargs = 0 })
  cmd('FocusOutline', M.focus_outline, { nargs = 0 })
  cmd('FocusCode', M.focus_code, { nargs = 0 })
  cmd('Focus', M.focus_toggle, { nargs = 0 })
  cmd('Status', M.show_status, { nargs = 0 })
end

-------------------------
-- STATE
-------------------------
M.state = {
  outline_items = {},
  flattened_outline_items = {},
  code_win = 0,
  opts = {}
}

local function wipe_state()
  M.state = { outline_items = {}, flattened_outline_items = {}, code_win = 0, opts = {} }
end

local function _update_lines()
  M.state.flattened_outline_items = parser.flatten(M.state.outline_items)
  writer.parse_and_write(M.view.bufnr, M.state.flattened_outline_items)
end

local function _merge_items(items)
  utils.merge_items_rec(
    { children = items },
    { children = M.state.outline_items }
  )
end

local function __refresh()
  if M.view:is_open() then
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

function M._current_node()
  local current_line = vim.api.nvim_win_get_cursor(M.view.winnr)[1]
  return M.state.flattened_outline_items[current_line]
end

function M._goto_location(change_focus)
  local node = M._current_node()
  vim.api.nvim_win_set_cursor(
    M.state.code_win,
    { node.line + 1, node.character }
  )
  if change_focus then
    vim.fn.win_gotoid(M.state.code_win)
    if config.options.auto_close then
      M.close_outline()
    end
  end
end

function M._toggle_fold(move_cursor, node_index)
  local node = M.state.flattened_outline_items[node_index] or M._current_node()
  local is_folded = folding.is_folded(node)

  if folding.is_foldable(node) then
    M._set_folded(not is_folded, move_cursor, node_index)
  end
end

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

function M._highlight_current_item(winnr)
  local has_provider = providers.has_provider()

  local is_current_buffer_the_outline = M.view.bufnr
    == vim.api.nvim_get_current_buf()

  local doesnt_have_outline_buf = not M.view.bufnr

  local should_exit = not has_provider
    or doesnt_have_outline_buf
    or is_current_buffer_the_outline

  -- Make a special case if we have a window number
  -- Because we might use this to manually focus so we dont want to quit this
  -- function
  if winnr then
    should_exit = false
  end

  if should_exit then
    return
  end

  local win = winnr or vim.api.nvim_get_current_win()

  local hovered_line = vim.api.nvim_win_get_cursor(win)[1] - 1

  local leaf_node = nil

  local cb = function(value)
    value.hovered = nil

    if
      value.line == hovered_line
      or (hovered_line > value.range_start and hovered_line < value.range_end)
    then
      value.hovered = true
      leaf_node = value
    end
  end

  utils.items_dfs(cb, M.state.outline_items)

  _update_lines()

  if leaf_node then
    for index, node in ipairs(M.state.flattened_outline_items) do
      if node == leaf_node then
        vim.api.nvim_win_set_cursor(M.view.winnr, { index, 1 })
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
  map(config.options.keymaps.goto_location, function()
    M._goto_location(true)
  end)
  -- goto_location of symbol but stay in outline
  map(config.options.keymaps.focus_location, function()
    M._goto_location(false)
  end)
  -- hover symbol
  map(
    config.options.keymaps.hover_symbol,
    require('symbols-outline.hover').show_hover
  )
  -- preview symbol
  map(
    config.options.keymaps.toggle_preview,
    require('symbols-outline.preview').toggle
  )
  -- rename symbol
  map(
    config.options.keymaps.rename_symbol,
    require('symbols-outline.rename').rename
  )
  -- code actions
  map(
    config.options.keymaps.code_actions,
    require('symbols-outline.code_action').show_code_actions
  )
  -- show help
  map(
    config.options.keymaps.show_help,
    require('symbols-outline.config').show_help
  )
  -- close outline
  map(config.options.keymaps.close, function()
    M.view:close()
  end)
  -- toggle fold selection
  map(config.options.keymaps.fold_toggle, M._toggle_fold)
  -- fold selection
  map(config.options.keymaps.fold, function()
    M._set_folded(true)
  end)
  -- unfold selection
  map(config.options.keymaps.unfold, function()
    M._set_folded(false)
  end)
  -- toggle fold all
  map(config.options.keymaps.fold_toggle_all, M._toggle_all_fold)
  -- fold all
  map(config.options.keymaps.fold_all, function()
    M._set_all_folded(true)
  end)
  -- unfold all
  map(config.options.keymaps.unfold_all, function()
    M._set_all_folded(false)
  end)
  -- fold reset
  map(config.options.keymaps.fold_reset, function()
    M._set_all_folded(nil)
  end)
end

local function handler(response)
  if response == nil or type(response) ~= 'table' then
    return
  end

  M.state.code_win = vim.api.nvim_get_current_win()

  M.view:setup_view()
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
  M.state.flattened_outline_items = parser.flatten(items)

  writer.parse_and_write(M.view.bufnr, M.state.flattened_outline_items)

  M._highlight_current_item(M.state.code_win)

  if not config.options.focus_on_open or (M.state.opts and M.state.opts.bang) then
    vim.fn.win_gotoid(M.state.code_win)
  end
end

function M.toggle_outline(opts)
  if M.view:is_open() then
    M.close_outline()
  else
    M.open_outline(opts)
  end
end

function M.open_outline(opts)
  if not M.view:is_open() then
    M.state.opts = opts
    providers.request_symbols(handler)
  end
end

function M.close_outline()
  M.view:close()
end

function M.focus_outline()
  if M.view:is_open() then
    vim.fn.win_gotoid(M.view.winnr)
  end
end

function M.focus_code()
  if require('symbols-outline.preview').has_code_win() then
    vim.fn.win_gotoid(M.state.code_win)
  end
end

function M.focus_toggle()
  if M.view:is_open() and require('symbols-outline.preview').has_code_win() then
    local winid = vim.fn.win_getid()
    if winid == M.state.code_win then
      vim.fn.win_gotoid(M.view.winnr)
    else
      vim.fn.win_gotoid(M.state.code_win)
    end
  end
end

function M.is_open()
  return M.view:is_open()
end

function M.show_status()
  if providers.has_provider() and _G._symbols_outline_current_provider then
    print("Current provider:")
    print(_G._symbols_outline_current_provider.name)
    if M.view:is_open() then
      print("Outline window is open")
    else
      print("Outline window is not open")
    end
  else
    print("No providers")
  end
end

function M.setup(opts)
  config.setup(opts)
  ui.setup_highlights()

  M.view = View:new()
  setup_global_autocmd()
  setup_commands()
end

return M
