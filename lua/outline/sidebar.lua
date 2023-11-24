local View = require('outline.view')
local cfg = require('outline.config')
local folding = require('outline.folding')
local parser = require('outline.parser')
local providers = require('outline.providers.init')
local utils = require('outline.utils.init')
local writer = require('outline.writer')

---@class outline.Sidebar
local Sidebar = {}

---@class outline.SidebarCodeState
---@field win integer
---@field buf integer

---@class outline.Sidebar
---@field view outline.View
---@field items outline.SymbolNode[]
---@field flats outline.FlatSymbolNode[]
---@field original_cursor string
---@field code outline.SidebarCodeState
---@field autocmds { [integer]: integer } winnr to autocmd id

function Sidebar:new()
  return setmetatable({
    view = View:new(),
    code = { buf = 0, win = 0 },
    items = {},
    flats = {},
    autocmds = {},
    original_cursor = vim.o.guicursor,
  }, { __index = Sidebar })
end

function Sidebar:delete_autocmds()
  for codewin, au in pairs(self.autocmds) do
    if vim.api.nvim_win_is_valid(codewin) then
      vim.api.nvim_del_autocmd(au)
    end
  end
  self.autocmds = {}
end

function Sidebar:reset_state()
  self.code = { buf = 0, win = 0 }
  self.items = {}
  self.flats = {}
  self.original_cursor = vim.o.guicursor
  self:delete_autocmds()
end

function Sidebar:destroy()
  self:delete_autocmds()
  if self.view:is_open() then
    vim.print('closing')
    self.view:close()
  end
  self.view = nil
  self.items = nil
  self.flats = nil
  self.code = nil
end

---Handler for provider request_symbols when outline is opened for the first time.
---@param response table?
---@param opts outline.OutlineOpts?
function Sidebar:initial_handler(response, opts)
  if response == nil or type(response) ~= 'table' or self.view:is_open() then
    return
  end

  if not opts then
    opts = {}
  end

  self.code.win = vim.api.nvim_get_current_win()
  self.code.buf = vim.api.nvim_get_current_buf()

  local sc = opts.split_command or cfg.get_split_command()
  self.view:setup_view(sc)

  -- clear state when buffer is closed
  vim.api.nvim_buf_attach(self.view.bufnr, false, {
    on_detach = function(_, _)
      self:reset_state()
    end,
  })

  self:setup_keymaps()
  self:setup_buffer_autocmd()
  self:setup_attached_buffer_autocmd()

  local items = parser.parse(response, self.code.buf)
  self.items = items

  local current
  self.flats, current = writer.make_outline(self.view.bufnr, items, self.code.win)

  self:update_cursor_pos(current)

  if not cfg.o.outline_window.focus_on_open or not opts.focus_outline then
    vim.fn.win_gotoid(self.code.win)
  end
end

---Convenience function for setup_keymaps
---@param cfg_name string Field in cfg.o.keymaps
---@param method string|function If string, field in Sidebar
---@param args table Passed to method
function Sidebar:nmap(cfg_name, method, args)
  if type(method) == 'string' then
    utils.nmap(self.view.bufnr, cfg.o.keymaps[cfg_name], function()
      Sidebar[method](self, unpack(args))
    end)
  else
    utils.nmap(self.view.bufnr, cfg.o.keymaps[cfg_name], function()
      method(unpack(args))
    end)
  end
end

function Sidebar:setup_keymaps()
  for name, meth in pairs({
    -- stylua: ignore start
    goto_location = { '_goto_location', { true } },
    peek_location = { '_goto_location', { false } },
    restore_location = { '_map_follow_cursor', {} },
    goto_and_close = { '_goto_and_close', {} },
    down_and_jump = { '_move_and_jump', { 'down' } },
    up_and_jump = { '_move_and_jump', { 'up' } },
    hover_symbol = { require('outline.hover').show_hover, {} },
    toggle_preview = { require('outline.preview').toggle, {} },
    rename_symbol = { require('outline.rename').rename, {} },
    code_actions = { require('outline.code_action').show_code_actions, {} },
    show_help = { require('outline.docs').show_help, {} },
    close = { function() self.view:close() end, {} },
    fold_toggle = { '_toggle_fold', {} },
    fold = { '_set_folded', { true } },
    unfold = { '_set_folded', { false } },
    fold_toggle_all = { '_toggle_all_fold', {} },
    fold_all = { '_set_all_folded', { true } },
    unfold_all = { '_set_all_folded', { false } },
    fold_reset = { '_set_all_folded', {} },
    -- stylua: ignore end
  }) do
    ---@diagnostic disable-next-line param-type-mismatch
    self:nmap(name, meth[1], meth[2])
  end
end

---Autocmds for the (current) outline buffer
function Sidebar:setup_buffer_autocmd()
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
        self:__goto_location(false)
      end,
    })
  end
  if cfg.o.outline_window.hide_cursor or type(cfg.o.outline_window.show_cursorline) == 'string' then
    -- Unfortunately guicursor is a global option, so we have to make sure to
    -- set and unset when cursor leaves the outline window.
    self:update_cursor_style()
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = 0,
      callback = function() self:update_cursor_style() end,
    })
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = 0,
      callback = function() self:reset_cursor_style() end,
    })
  end
end

---Setup autocmds for the code buffer that the outline attached to
function Sidebar:setup_attached_buffer_autocmd()
  local code_win, code_buf = self.code.win, self.code.buf
  local events = cfg.o.outline_items.auto_update_events

  if
    cfg.o.outline_items.highlight_hovered_item
    or cfg.o.symbol_folding.auto_unfold_hover
  then
    if self.autocmds[code_win] then
      vim.api.nvim_del_autocmd(self.autocmds[code_win])
      self.autocmds[code_win] = nil
    end

    if utils.str_or_nonempty_table(events.follow) then
      self.autocmds[code_win] = vim.api.nvim_create_autocmd(events.follow, {
        buffer = code_buf,
        callback = function()
          self:_highlight_current_item(code_win, cfg.o.outline_items.auto_set_cursor)
        end,
      })
    end
  end
end

---Set hide_cursor depending on whether cursorline is 'focus_in_outline'
function Sidebar:update_cursor_style()
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
    self.original_cursor = vim.o.guicursor
    local cur = vim.o.guicursor:match('n.-:(.-)[-,]')
    vim.opt.guicursor:append('n:' .. cur .. '-Cursorline')
  end
end

function Sidebar:reset_cursor_style()
  local cl = cfg.o.outline_window.show_cursorline

  if cl == 'focus_in_outline' or cl == 'focus_in_code' then
    vim.api.nvim_win_set_option(0, 'cursorline', cl ~= 'focus_in_outline')
  end
  -- vim.opt doesn't seem to provide a way to remove last item, like a pop()
  -- vim.o.guicursor = vim.o.guicursor:gsub(",n.-:.-$", "")
  vim.o.guicursor = self.original_cursor
end

---@param current outline.FlatSymbolNode?
function Sidebar:update_cursor_pos(current)
  local col = 0
  local buf = vim.api.nvim_win_get_buf(self.code.win)
  if cfg.o.outline_items.show_symbol_lineno then
    -- Padding area between lineno column and start of guides
    col = #tostring(vim.api.nvim_buf_line_count(buf) - 1)
  end
  if current then -- Don't attempt to set cursor if the matching node is not found
    vim.api.nvim_win_set_cursor(self.view.winnr, { current.line_in_outline, col })
  end
end

---Calls writer.make_outline and then calls M.update_cursor_pos if
-- update_cursor is not false
---@param update_cursor boolean?
---@param set_cursor_to_node outline.SymbolNode|outline.FlatSymbolNode?
function Sidebar:_update_lines(update_cursor, set_cursor_to_node)
  local current
  self.flats, current = writer.make_outline(
    self.view.bufnr,
    self.items,
    self.code.win,
    set_cursor_to_node
  )
  if update_cursor ~= false then
    self:update_cursor_pos(current)
  end
end

---Handler for provider request_symbols for refreshing outline
function Sidebar:refresh_handler(response)
  if response == nil or type(response) ~= 'table' then
    return
  end

  local curwin = vim.api.nvim_get_current_win()
  local curbuf = vim.api.nvim_get_current_buf()
  local newbuf = curbuf ~= self.code.buf

  if self.code.win ~= curwin then
    if self.autocmds[self.code.win] then
      vim.api.nvim_del_autocmd(self.autocmds[self.code.win])
      self.autocmds[self.code.win] = nil
    end
  end

  self.code.win = curwin
  self.code.buf = curbuf

  self:setup_attached_buffer_autocmd()

  local items = parser.parse(response, vim.api.nvim_get_current_buf())
  self:_merge_items(items)

  local update_cursor = newbuf or cfg.o.outline_items.auto_set_cursor
  self:_update_lines(update_cursor)
end

---@param items outline.SymbolNode[]
function Sidebar:_merge_items(items)
  utils.merge_items_rec({ children = items }, { children = self.items })
end

---Re-request symbols from provider
function Sidebar:__refresh()
  local focused_outline = self.view.bufnr == vim.api.nvim_get_current_buf()
  if self.view:is_open() and not focused_outline then
    providers.request_symbols(function(res) self:refresh_handler(res) end)
  end
end

function Sidebar:_refresh()
  (utils.debounce(function() self:__refresh() end, 100))()
end

---@return outline.FlatSymbolNode
function Sidebar:_current_node()
  local current_line = vim.api.nvim_win_get_cursor(self.view.winnr)[1]
  return self.flats[current_line]
end

---@param change_focus boolean Whether to switch to code window after setting cursor
function Sidebar:__goto_location(change_focus)
  local node = self:_current_node()
  vim.api.nvim_win_set_cursor(self.code.win, { node.line + 1, node.character })

  if cfg.o.outline_window.center_on_jump then
    vim.fn.win_execute(self.code.win, 'normal! zz')
  end

  utils.flash_highlight(
    self.code.win,
    node.line + 1,
    cfg.o.outline_window.jump_highlight_duration,
    'OutlineJumpHighlight'
  )

  if change_focus then
    vim.fn.win_gotoid(self.code.win)
  end
end

---Wraps __goto_location and handles auto_close.
---@see __goto_location
---@param change_focus boolean
function Sidebar:_goto_location(change_focus)
  self:__goto_location(change_focus)
  if change_focus and cfg.o.outline_window.auto_close then
    self:close()
  end
end

function Sidebar:_goto_and_close()
  self:__goto_location(true)
  self:close()
end

---@param direction "up"|"down"
function Sidebar:_move_and_jump(direction)
  local move = direction == 'down' and 1 or -1
  local cur = vim.api.nvim_win_get_cursor(0)
  cur[1] = cur[1] + move
  pcall(vim.api.nvim_win_set_cursor, 0, cur)
  self:__goto_location(false)
end

---@param move_cursor boolean
---@param node_index integer Index for self.flats
function Sidebar:_toggle_fold(move_cursor, node_index)
  local node = self.flats[node_index] or self:_current_node()
  local is_folded = folding.is_folded(node)

  if folding.is_foldable(node) then
    self:_set_folded(not is_folded, move_cursor, node_index)
  end
end

---@param folded boolean
---@param move_cursor? boolean
---@param node_index? integer
function Sidebar:_set_folded(folded, move_cursor, node_index)
  local node = self.flats[node_index] or self:_current_node()
  local changed = (folded ~= folding.is_folded(node))

  if folding.is_foldable(node) and changed then
    node.folded = folded

    if move_cursor then
      vim.api.nvim_win_set_cursor(self.view.winnr, { node_index, 0 })
    end

    self:_update_lines(false)
  elseif node.parent then
    local parent_node = self.flats[node.parent.line_in_outline]

    if parent_node then
      self:_set_folded(
        folded,
        not parent_node.folded and folded,
        parent_node.line_in_outline
      )
    end
  end
end

---@param nodes outline.SymbolNode[]
function Sidebar:_toggle_all_fold(nodes)
  nodes = nodes or self.items
  local folded = true

  for _, node in ipairs(nodes) do
    if folding.is_foldable(node) and not folding.is_folded(node) then
      folded = false
      break
    end
  end

  self:_set_all_folded(not folded, nodes)
end

---@param folded boolean?
---@param nodes? outline.SymbolNode[]
function Sidebar:_set_all_folded(folded, nodes)
  local stack = { nodes or self.items }
  local current = self:_current_node()

  while #stack > 0 do
    local current_nodes = table.remove(stack, #stack)
    for _, node in ipairs(current_nodes) do
      node.folded = folded
      if node.children then
        stack[#stack + 1] = node.children
      end
    end
  end

  self:_update_lines(true, current)
end

---@see outline.follow_cursor
---@param opts outline.OutlineOpts?
---@return boolean ok
function Sidebar:follow_cursor(opts)
  if not self.view:is_open() then
    return false
  end

  if require('outline.preview').has_code_win(self.code.win) then
    self:_highlight_current_item(self.code.win, true)
  else
    return false
  end

  if not opts then
    opts = { focus_outline = true }
  end

  if opts.focus_outline then
    self:focus()
  end

  return true
end

function Sidebar:_map_follow_cursor()
  if not self:follow_cursor({ focus_outline = true }) then
    utils.echo('Code window no longer active. Try closing and reopening the outline.')
  end
end

---@param opts outline.OutlineOpts?
---@return boolean is_open
function Sidebar:toggle(opts)
  if self.view:is_open() then
    self:close()
    return false
  else
    self:open(opts)
    return true
  end
end

---@see outline.open_outline
---@param opts outline.OutlineOpts?
function Sidebar:open(opts)
  if not opts then
    opts = { focus_outline = true }
  end

  if not self.view:is_open() then
    local found = providers.request_symbols(
      function(...) self:initial_handler(...) end,
      opts
    )
    if not found then
      utils.echo('No providers found for current buffer')
    end
  end
end

---@see outline.close_outline
function Sidebar:close()
  self.view:close()
end

---@see outline.focus_outline
---@return boolean is_open
function Sidebar:focus()
  if self.view:is_open() then
    vim.fn.win_gotoid(self.view.winnr)
    return true
  end
  return false
end

---@see outline.focus_code
---@return boolean ok
function Sidebar:focus_code()
  if require('outline.preview').has_code_win(self.code.win) then
    vim.fn.win_gotoid(self.code.win)
    return true
  end
  return false
end

---@see outline.focus_toggle
---@return boolean ok
function Sidebar:focus_toggle()
  if self.view:is_open() and require('outline.preview').has_code_win(self.code.win) then
    local winid = vim.fn.win_getid()
    if winid == self.code.win then
      vim.fn.win_gotoid(self.view.winnr)
    else
      vim.fn.win_gotoid(self.code.win)
    end
    return true
  end
  return false
end

---Whether the outline window is currently open.
---@return boolean is_open
function Sidebar:is_open()
  return self.view:is_open()
end

function Sidebar:has_focus()
  local winid = vim.fn.win_getid()
  return self.view:is_open() and winid == self.view.winnr
end

---Whether there is currently an available provider.
---@return boolean has_provider
function Sidebar:has_provider()
  if self:has_focus() then
    return _G._outline_current_provider ~= nil
  end
  return providers.has_provider()
end

function Sidebar:_highlight_current_item(winnr, update_cursor)
  local has_provider = self:has_provider()
  local has_outline_open = self.view:is_open()
  local current_buffer_is_outline = self.view.bufnr == vim.api.nvim_get_current_buf()

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

  local valid_code_win = vim.api.nvim_win_is_valid(self.code.win)
  local valid_winnr = winnr and vim.api.nvim_win_is_valid(winnr)

  if not valid_code_win then
    -- Definetely don't attempt to update anything if code win is no longer valid
    return
  end

  if not valid_winnr then
    return
  elseif winnr ~= self.code.win then
    -- Both valid, but given winnr ~= known code win.
    -- Best not to handle this situation at all to prevent any unwanted side
    -- effects
    return
  end

  self:_update_lines(update_cursor)
end

return Sidebar
