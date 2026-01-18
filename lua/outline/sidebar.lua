local Preview = require('outline.preview')
local View = require('outline.view')
local cfg = require('outline.config')
local folding = require('outline.folding')
local parser = require('outline.parser')
local providers = require('outline.providers.init')
local symbols = require('outline.symbols')
local utils = require('outline.utils')

local strlen = vim.fn.strlen

---@class outline.Sidebar
local Sidebar = {}

---@class outline.SidebarCodeState
---@field win integer
---@field buf integer

---@class outline.Sidebar
---@field id integer
---@field view outline.View
---@field items outline.Symbol[]
---@field flats outline.FlatSymbol[]
---@field hovered outline.FlatSymbol[]
---@field original_cursor string
---@field code outline.SidebarCodeState
---@field augroup integer
---@field provider outline.Provider?
---@field provider_info table?
---@field preview outline.Preview|outline.LivePreview

function Sidebar:new(id)
  return setmetatable({
    id = id,
    view = View:new(),
    preview = Preview:new(cfg.o.preview_window),
    code = { buf = 0, win = 0 },
    items = {},
    flats = {},
    hovered = {},
    original_cursor = vim.o.guicursor,
  }, { __index = Sidebar })
end

function Sidebar:delete_autocmds()
  if self.augroup then
    vim.api.nvim_del_augroup_by_id(self.augroup)
  end
  self.augroup = nil
end

function Sidebar:reset_state()
  self.code = { buf = 0, win = 0 }
  self.items = {}
  self.flats = {}
  self.original_cursor = vim.o.guicursor
  self.provider = nil
  self:delete_autocmds()
end

function Sidebar:destroy()
  self:delete_autocmds()
  self.view = nil
  self.preview = nil
  self.items = nil
  self.flats = nil
  self.code = nil
  self.provider = nil
end

---@param opts table
function Sidebar:initial_setup(opts)
  self.code.win = vim.api.nvim_get_current_win()
  self.code.buf = vim.api.nvim_get_current_buf()

  local sc = opts.split_command or cfg.get_split_command()
  self.view:setup_view(sc, opts.use_float)

  -- clear state when buffer is closed
  vim.api.nvim_buf_attach(self.view.buf, false, {
    on_detach = function(_, _)
      self:reset_state()
    end,
  })

  self:setup_keymaps()
  self:setup_buffer_autocmd()
  self:setup_attached_buffer_autocmd()
end

---Handler for provider request_symbols when outline is opened for the first time.
---@param response outline.ProviderSymbol[]?
---@param opts outline.OutlineOpts?
function Sidebar:initial_handler(response, opts)
  if response == nil or type(response) ~= 'table' or self.view:is_open() then
    utils.echo('No response from provider when requesting symbols!')
    return
  end

  if not opts then
    opts = {}
  end

  self:initial_setup(opts)

  local items = parser.parse(response, self.code.buf)
  self.items = items

  self:_update_lines(true)
  if not cfg.o.outline_window.focus_on_open or not opts.focus_outline then
    vim.fn.win_gotoid(self.code.win)
  end
end

-- stylua: ignore start
---Convenience function for setup_keymaps
---@param cfg_name string Field in cfg.o.keymaps
---@param method string|function If string, field in Sidebar
---@param args any[] Passed to method
function Sidebar:nmap(cfg_name, method, args)
  local keys = cfg.o.keymaps[cfg_name]
  local fn

  if type(method) == 'string' then
    fn = function() Sidebar[method](self, unpack(args)) end
  else
    fn = function() method(unpack(args)) end
  end

  for _, key in ipairs(keys) do
    vim.keymap.set( 'n', key, fn,
      { silent = true, noremap = true, buffer = self.view.buf }
    )
  end
end

function Sidebar:setup_keymaps()
  for name, meth in pairs({
    show_help = { require('outline.help').show_keymap_help, {} },
    close = { function() self:close() end, {} },
    goto_location = { '_goto_location', { true } },
    peek_location = { '_goto_location', { false } },
    restore_location = { '_map_follow_cursor', {} },
    goto_and_close = { '_goto_and_close', {} },
    down_and_jump = { '_move_and_jump', { 'down' } },
    up_and_jump = { '_move_and_jump', { 'up' } },
    fold_toggle = { '_toggle_fold', {} },
    fold = { '_set_folded', { true } },
    unfold = { '_set_folded', { false } },
    fold_toggle_all = { '_toggle_all_fold', {} },
    fold_all = { '_set_all_folded', { true } },
    unfold_all = { '_set_all_folded', { false } },
    fold_reset = { '_set_all_folded', {} },
    rename_symbol = {
      providers.action, { self, 'rename_symbol', { self } }
    },
    code_actions = {
      providers.action, { self, 'code_actions', { self } }
    },
    hover_symbol = {
      providers.action, { self, 'show_hover', { self } }
    },
  }) do
    ---@diagnostic disable-next-line param-type-mismatch
    self:nmap(name, meth[1], meth[2])
  end

  local toggle_preview
  if cfg.o.preview_window.auto_preview and cfg.o.preview_window.live then
    toggle_preview = { function() self.preview:focus() end, {} }
  else
    toggle_preview = { function() self.preview:toggle() end, {} }
  end
  self:nmap('toggle_preview', toggle_preview[1], toggle_preview[2])
end
-- stylua: ignore end

---Autocmds for the (current) outline buffer
function Sidebar:setup_buffer_autocmd()
  if cfg.o.preview_window.auto_preview then
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = function()
        self.preview:show()
      end,
    })
  else
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = function()
        self.preview:close()
      end,
    })
  end
  if cfg.o.outline_window.auto_jump then
    vim.api.nvim_create_autocmd('CursorMoved', {
      buffer = 0,
      callback = function()
        if self.provider then
          -- Don't use _goto_location because we don't want to auto-close
          self:__goto_location(false)
        end
      end,
    })
  end
  if cfg.o.outline_window.hide_cursor or type(cfg.o.outline_window.show_cursorline) == 'string' then
    -- Unfortunately guicursor is a global option, so we have to make sure to
    -- set and unset when cursor leaves the outline window.
    self:update_cursor_style()
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = 0,
      callback = function()
        self:update_cursor_style()
      end,
    })
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = 0,
      callback = function()
        self:reset_cursor_style()
      end,
    })
  end
end

---Setup autocmds for the code buffer that the outline attached to
function Sidebar:setup_attached_buffer_autocmd()
  local code_win, code_buf = self.code.win, self.code.buf
  local events = cfg.o.outline_items.auto_update_events

  if cfg.o.outline_items.highlight_hovered_item or cfg.o.symbol_folding.auto_unfold_hover then
    if utils.str_or_nonempty_table(events.follow) then
      self.augroup = vim.api.nvim_create_augroup('outline_' .. self.id, { clear = true })
      vim.api.nvim_create_autocmd(events.follow, {
        group = self.augroup,
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
  -- Still 'hide' cursor if show_cursorline set to false, because we've already
  -- warned the user during setup.
  local hide_cursor = type(cl) ~= 'string'

  if cl == 'focus_in_outline' or cl == 'focus_in_code' then
    utils.win_set_option(0, 'cursorline', cl == 'focus_in_outline')
    hide_cursor = cl == 'focus_in_outline'
  end

  -- Set cursor color to CursorLine in normal mode
  if hide_cursor then
    -- local cur = vim.o.guicursor:match('n.-:(.-)[-,]')
    local cur = vim.o.guicursor:match('n.-:([^,]+)')
    vim.opt.guicursor:append('n:' .. cur .. '-Cursorline')
  end
end

function Sidebar:reset_cursor_style()
  local cl = cfg.o.outline_window.show_cursorline

  if cl == 'focus_in_outline' or cl == 'focus_in_code' then
    utils.win_set_option(0, 'cursorline', cl ~= 'focus_in_outline')
  end
  -- vim.opt doesn't seem to provide a way to remove last item, like a pop()
  -- vim.o.guicursor = vim.o.guicursor:gsub(",n.-:.-$", "")
  vim.o.guicursor = self.original_cursor
end

---Set the cursor to current.line_in_outline and column to a convenient place
---@param current outline.FlatSymbol?
function Sidebar:update_cursor_pos(current)
  if not self.code.win or not self.view.win then
    return
  end

  local col = 0

  local buf = vim.api.nvim_win_get_buf(self.code.win)
  if cfg.o.outline_items.show_symbol_lineno then
    -- Padding area between lineno column and start of guides
    col = #tostring(vim.api.nvim_buf_line_count(buf) - 1)
  end
  if current then -- Don't attempt to set cursor if the matching node is not found
    vim.api.nvim_win_set_cursor(self.view.win, { current.line_in_outline, col })
  end
end

---Calls build_outline and then calls update_cursor_pos if update_cursor is
---not false
---@param update_cursor boolean?
---@param set_cursor_to_node outline.Symbol|outline.FlatSymbol?
function Sidebar:_update_lines(update_cursor, set_cursor_to_node)
  local current = self:build_outline(set_cursor_to_node)
  if update_cursor ~= false then
    self:update_cursor_pos(current)
  end
end

---@return boolean new_buf
function Sidebar:refresh_setup()
  local curwin = vim.api.nvim_get_current_win()
  local curbuf = vim.api.nvim_get_current_buf()
  local newbuf = curbuf ~= self.code.buf

  self.code.win = curwin
  self.code.buf = curbuf

  self:setup_attached_buffer_autocmd()
  return newbuf
end

---Handler for provider request_symbols for refreshing outline
---@param response outline.ProviderSymbol[]
function Sidebar:refresh_handler(response)
  if response == nil or type(response) ~= 'table' then
    utils.echo('No response from provider when requesting symbols!')
    return
  end

  local curbuf = vim.api.nvim_get_current_buf()
  if curbuf == self.view.buf then
    return
  end

  local newbuf = self:refresh_setup()

  local items = parser.parse(response, curbuf)
  self:_merge_items(items)

  local update_cursor = newbuf or cfg.o.outline_items.auto_set_cursor
  self:_update_lines(update_cursor)
end

---@param items outline.Symbol[]
function Sidebar:_merge_items(items)
  parser.merge_items_rec({ children = items }, { children = self.items })
end

---Re-request symbols from provider
function Sidebar:__refresh()
  local buf = vim.api.nvim_get_current_buf()
  local focused_outline = self.view.buf == buf
  if focused_outline or not self.view:is_open() then
    return
  end
  local ft = utils.buf_get_option(buf, 'ft')
  local listed = utils.buf_get_option(buf, 'buflisted')
  if ft == 'OutlineHelp' or not (listed or ft == 'help') then
    return
  end
  self.provider, self.provider_info = providers.find_provider()
  if self.provider then
    self.provider.request_symbols(function(res)
      if self.view:is_open() then
        self:refresh_handler(res)
      end
    end, nil, self.provider_info)
    return
  end
  -- No provider
  self:refresh_setup()
  self:no_providers_ui()
end

-- stylua: ignore start
-- TODO: Is this still needed?
function Sidebar:_refresh()
  (utils.debounce(function() self:__refresh() end, 100))()
end
-- stylua: ignore end

function Sidebar:no_providers_ui()
  self.view:rewrite_lines({ cfg.o.outline_window.no_provider_message })
  vim.api.nvim_win_set_cursor(self.view.win, { 1, 0 })
end

---Currently hovered node in outline
---@return outline.FlatSymbol?
function Sidebar:_current_node()
  local current_line = vim.api.nvim_win_get_cursor(self.view.win)[1]
  if self.flats then
    return self.flats[current_line]
  end
end

---@param change_focus boolean Whether to switch to code window after setting cursor
function Sidebar:__goto_location(change_focus)
  if not self.provider then
    return
  end
  local node = self:_current_node()
  if not node then
    return
  end

  if not vim.api.nvim_win_is_valid(self.code.win) then
    vim.notify('outline.nvim: Code window closed', vim.log.levels.WARN)
    return
  end

  -- XXX: There will be strange problems when using `nvim_buf_set_mark()`.
  vim.fn.win_execute(self.code.win, "normal! m'")

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

---Goto location in code, run fn() then go back to outline.
---Like emacs save-excursion but here it's explicitly goto_location.
---@param fn function
function Sidebar:wrap_goto_location(fn)
  local pos = vim.api.nvim_win_get_cursor(0)
  self:__goto_location(true)
  fn()
  vim.fn.win_gotoid(self.view.win)
  vim.api.nvim_win_set_cursor(self.view.win, pos)
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
function Sidebar:_toggle_fold(move_cursor)
  if not self.provider then
    return
  end
  local node = self:_current_node()
  if not node then
    return
  end
  local is_folded = folding.is_folded(node)

  if folding.is_foldable(node) then
    self:_set_folded(not is_folded, move_cursor)
  end
end

---@param folded boolean
---@param move_cursor? boolean
---@param node_index? integer
function Sidebar:_set_folded(folded, move_cursor, node_index)
  if not self.provider then
    return
  end
  local node = self.flats[node_index] or self:_current_node()
  local changed = (folded ~= folding.is_folded(node))

  if folding.is_foldable(node) and changed then
    node.folded = folded

    if move_cursor then
      vim.api.nvim_win_set_cursor(self.view.win, { node_index, 0 })
    end

    self:_update_lines(false)
  elseif node.parent then
    local parent_node = self.flats[node.parent.line_in_outline]

    if parent_node then
      self:_set_folded(folded, not parent_node.folded and folded, parent_node.line_in_outline)
    end
  end
end

---@param nodes outline.Symbol[]
function Sidebar:_toggle_all_fold(nodes)
  if not self.provider then
    return
  end
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
---@param nodes? outline.Symbol[]
function Sidebar:_set_all_folded(folded, nodes)
  if not self.provider then
    return
  end
  local stack = { nodes or self.items }
  local current = self:_current_node()
  if not current then
    return
  end

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

function Sidebar:has_code_win()
  return self.code.win
    and self.code.buf
    and self.code.win ~= 0
    and self.code.buf ~= 0
    and vim.api.nvim_win_is_valid(self.code.win)
    and vim.api.nvim_buf_is_valid(self.code.buf)
end

---@see outline.follow_cursor
---@param opts outline.OutlineOpts?
---@return boolean ok
function Sidebar:follow_cursor(opts)
  if not self.view:is_open() then
    return false
  end

  if self:has_code_win() then
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
    self.preview.s = self
    self.provider, self.provider_info = providers.find_provider()
    if self.provider then
      self.provider.request_symbols(function(...)
        self:initial_handler(...)
      end, opts, self.provider_info)
      return
    else
      -- No provider
      self:initial_setup(opts)
      self:no_providers_ui()
    end
    if not cfg.o.outline_window.focus_on_open or not opts.focus_outline then
      vim.fn.win_gotoid(self.code.win)
    end
  else
    if cfg.o.outline_window.focus_on_open and opts.focus_outline then
      self:focus()
    end
  end
end

---@see outline.close_outline
function Sidebar:close()
  local code_win = self.code.win
  self.view:close()
  self.preview:close()
  vim.fn.win_gotoid(code_win)
end

---@see outline.focus_outline
---@return boolean is_open
function Sidebar:focus()
  if self.view:is_open() then
    vim.fn.win_gotoid(self.view.win)
    return true
  end
  return false
end

---@see outline.focus_code
---@return boolean ok
function Sidebar:focus_code()
  if self:has_code_win() then
    vim.fn.win_gotoid(self.code.win)
    return true
  end
  return false
end

---@see outline.focus_toggle
---@return boolean ok
function Sidebar:focus_toggle()
  if self.view:is_open() and self:has_code_win() then
    local winid = vim.fn.win_getid()
    if winid == self.code.win then
      vim.fn.win_gotoid(self.view.win)
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
  return self.view:is_open() and winid == self.view.win
end

---Whether there is currently an available provider.
---@return boolean has_provider
function Sidebar:has_provider()
  if self:has_focus() then
    return self.provider ~= nil
  end
  return providers.has_provider()
end

function Sidebar:_highlight_current_item(winnr, update_cursor)
  local has_provider = self:has_provider()
  local has_outline_open = self.view:is_open()
  local current_buffer_is_outline = self.view.buf == vim.api.nvim_get_current_buf()

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

---The quintessential function of this entire plugin. Clears virtual text,
---parses each node and replaces old lines with new lines to be written for the
---outline buffer.
---
---Handles highlights, virtual text, and of course lines of outline to write.
---@note Ensure new outlines are already set to `self.items` before calling
---this function. `self.flats` will be overwritten and current line is obtained
---from `win_get_cursor` using `self.code.win`.
---@param find_node outline.FlatSymbol|outline.Symbol? Find a given node rather than node matching cursor position in codewin
---@return outline.FlatSymbol? set_cursor_to_this_node
function Sidebar:build_outline(find_node)
  ---@type integer 0-indexed
  local hovered_line = vim.api.nvim_win_get_cursor(self.code.win)[1] - 1
  ---@type outline.FlatSymbol Deepest visible matching node to set cursor
  local put_cursor
  self.flats = {}
  local line_count = 0
  local lines = {} ---@type string[]
  local details = {} ---@type string[]
  local linenos = {} ---@type string[]
  local hl = {} ---@type outline.HL[]

  -- Find the prefix for each line needed for the lineno space.
  -- Use [max width of [max_line-1]] + 1 space padding.
  -- -1 because if max_width is a power of ten, don't shift the entire lineno
  -- column by the right just because the last line number requires an extra
  -- digit. i.e.: If max_width is 1000, the lineno column will take up 3
  -- columns to fill the digits, and 1 padding on the right. The 1000 can fit
  -- perfectly there.
  local lineno_offset = 0
  local lineno_prefix = ''
  local lineno_max_width = #tostring(vim.api.nvim_buf_line_count(self.code.buf) - 1)
  if cfg.o.outline_items.show_symbol_lineno then
    lineno_offset = math.max(2, lineno_max_width) + 1
    lineno_prefix = string.rep(' ', lineno_offset)
  end

  -- Closures for convenience
  -- stylua: ignore start
  local function save_guide_hl(from, to)
    table.insert(hl, {
      line = line_count, name = 'OutlineGuides',
      from = from, to = to,
    })
  end
  local function save_fold_hl(from, to)
    table.insert(hl, {
      line = line_count, name = 'OutlineFoldMarker',
      from = from, to = to,
    })
  end
  -- stylua: ignore end

  local guide_markers = cfg.o.guides.markers
  local fold_markers = cfg.o.symbol_folding.markers

  for node in parser.preorder_iter(self.items) do
    line_count = line_count + 1
    node.line_in_outline = line_count
    table.insert(self.flats, node)

    node.hovered = false
    if
      node.line == hovered_line
      or (hovered_line >= node.range_start and hovered_line <= node.range_end)
    then
      -- Not setting for children, but it works because when unfold is called
      -- this function is called again anyway.
      node.hovered = true
      table.insert(self.hovered, node)
      if not find_node then
        put_cursor = node
      end
    end
    if find_node and find_node == node then
      ---@diagnostic disable-next-line: cast-local-type
      put_cursor = find_node
    end

    table.insert(details, node.detail or '')
    local lineno = tostring(node.range_start + 1)
    local leftpad = string.rep(' ', lineno_max_width - #lineno)
    table.insert(linenos, leftpad .. lineno)

    -- Make the guides for the line prefix
    local pref = utils.str_to_table(string.rep(' ', node.depth))
    local fold_marker_width = 0

    if folding.is_foldable(node) then
      -- Add fold marker
      local marker = fold_markers[2]
      if folding.is_folded(node) then
        marker = fold_markers[1]
      end
      pref[#pref] = marker
      fold_marker_width = strlen(marker)
    else
      -- Rightmost guide for the direct parent, only added if fold marker is
      -- not added
      if node.depth > 1 then
        local marker = guide_markers.middle
        if node.isLast then
          marker = guide_markers.bottom
        end
        pref[#pref] = marker
      end
    end

    -- Add vertical guides to the left, for all parents that isn't the last
    -- sibling. Iter from first grandparent until second last ancestor (last
    -- ancestor is the entire outline itself, it should not have a vertical
    -- guide).
    local iternode = node
    for i = node.depth - 1, 2, -1 do
      iternode = iternode.parent_node
      if not iternode.isLast then
        pref[i] = guide_markers.vertical
      end
    end

    -- Finished with guide prefix. Now join all prefix chars by a space
    local pref_str = table.concat(pref, ' ')
    local total_pref_len = lineno_offset + #pref_str

    -- Guide hl goes from start of prefix till before the fold marker, if any.
    -- Fold hl goes from start of fold marker until before the icon.
    save_guide_hl(lineno_offset, total_pref_len - fold_marker_width)
    if fold_marker_width > 0 then
      save_fold_hl(total_pref_len - fold_marker_width, total_pref_len + 1)
    end

    local line = lineno_prefix .. pref_str
    local icon_pref = 0
    if node.icon ~= '' then
      line = line .. ' ' .. node.icon
      icon_pref = 1
    end
    line = line .. ' ' .. node.name

    -- Start from left of icon col
    local hl_start = #pref_str + #lineno_prefix + icon_pref
    local hl_end = hl_start + #node.icon -- until after icon
    local hl_type = cfg.o.symbols.icons[symbols.kinds[node.kind]].hl
    -- stylua: ignore start
    table.insert(hl, {
      line = line_count, name = hl_type,
      from = hl_start, to = hl_end,
    })
    -- stylua: ignore end
    -- Prefix length is from start until the beginning of the node.name, used
    -- for hover highlights.
    node.prefix_length = hl_end + 1

    -- Each line passed to nvim_buf_set_lines cannot contain newlines
    line = line:gsub('\n', ' ')
    table.insert(lines, line)
  end

  -- PERF:
  -- * Is setting individual lines is not as good as rewriting entire buffer?
  --   That way we can set all highlights and virtual text together without
  --   requiring extra O(n) iterations.
  -- * Is there a significant difference if new lines are set first, on top
  --   of old highlights, before resetting the highlights? (Rather than doing
  --   like below)
  self.view:clear_all_ns()
  self.view:rewrite_lines(lines)
  self.view:add_hl_and_ns(hl, self.flats, details, linenos)

  return put_cursor
end

return Sidebar
