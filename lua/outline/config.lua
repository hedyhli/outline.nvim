local utils = require('outline.utils')

local M = {}
-- stylua: ignore start
local all_kinds = {'File', 'Module', 'Namespace', 'Package', 'Class', 'Method', 'Property', 'Field', 'Constructor', 'Enum', 'Interface', 'Function', 'Variable', 'Constant', 'String', 'Number', 'Boolean', 'Array', 'Object', 'Key', 'Null', 'EnumMember', 'Struct', 'Event', 'Operator', 'TypeParameter', 'Component', 'Fragment', 'TypeAlias', 'Parameter', 'StaticMethod', 'Macro'}
-- stylua: ignore end

M.defaults = {
  guides = {
    enabled = true,
    markers = {
      bottom = '└',
      middle = '├',
      vertical = '│',
      horizontal = '─',
    },
  },
  outline_items = {
    show_symbol_details = true,
    show_symbol_lineno = false,
    -- The two below are both for auto_update_events.follow
    highlight_hovered_item = true,
    -- On open, always followed. This is for auto_update_events.follow, whether
    -- to auto update cursor position to reflect code location. If false, can
    -- manually trigger with follow_cursor (API, command, keymap action).
    auto_set_cursor = true,
    auto_update_events = {
      follow = { 'CursorMoved' },
      items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'BufWritePost' },
    },
  },
  outline_window = {
    position = 'right',
    split_command = nil,
    width = 25,
    relative_width = true,
    wrap = false,
    focus_on_open = true,
    auto_close = false,
    auto_jump = false,
    show_numbers = false,
    show_relative_numbers = false,
    ---@type boolean|string?
    show_cursorline = true,
    hide_cursor = false,
    winhl = '',
    jump_highlight_duration = 400,
    center_on_jump = true,
    no_provider_message = 'No supported provider...',
    -- Floating window options
    float = {
      width = 30,
      height = 80,
      relative_width = true,
      relative_height = true,
      -- Configuration passed directly to nvim_open_win
      -- Can be a table or a function that returns a table
      win_config = {
        relative = 'editor',
        border = 'rounded',
        zindex = 50,
        focusable = true,
        style = 'minimal',
        title = 'Outline',
        title_pos = 'center',
      },
      -- Additional window options (set via nvim_win_set_option)
      win_options = {},
    },
  },
  preview_window = {
    live = false,
    auto_preview = false,
    width = 50,
    min_width = 50,
    relative_width = true,
    height = 50,
    min_height = 10,
    relative_height = true,
    border = 'single',
    open_hover_on_preview = false,
    winhl = 'NormalFloat:',
    winblend = 0,
  },
  symbol_folding = {
    autofold_depth = 1,
    auto_unfold = {
      hovered = true,
      ---@type boolean|integer
      only = true,
    },
    markers = { '', '' },
  },
  keymaps = {
    show_help = '?',
    close = { '<Esc>', 'q' },
    goto_location = '<Cr>',
    peek_location = 'o',
    goto_and_close = '<S-Cr>',
    restore_location = '<C-g>',
    hover_symbol = '<C-space>',
    toggle_preview = 'K',
    rename_symbol = 'r',
    code_actions = 'a',
    fold = 'h',
    fold_toggle = '<tab>',
    fold_toggle_all = '<S-tab>',
    unfold = 'l',
    fold_all = 'W',
    unfold_all = 'E',
    fold_reset = 'R',
    down_and_jump = '<C-j>',
    up_and_jump = '<C-k>',
  },
  providers = {
    priority = { 'lsp', 'coc', 'markdown', 'norg', 'man' },
    lsp = {
      blacklist_clients = {},
    },
    markdown = {
      filetypes = { 'markdown' },
    },
  },
  symbols = {
    ---@type outline.FilterConfig?
    filter = nil,
    icon_source = nil,
    icon_fetcher = nil,
    icons = {
      File = { icon = '󰈔', hl = 'Identifier' },
      Module = { icon = '󰆧', hl = 'Include' },
      Namespace = { icon = '󰅪', hl = 'Include' },
      Package = { icon = '󰏗', hl = 'Include' },
      Class = { icon = '𝓒', hl = 'Type' },
      Method = { icon = 'ƒ', hl = 'Function' },
      Property = { icon = '', hl = 'Identifier' },
      Field = { icon = '󰆨', hl = 'Identifier' },
      Constructor = { icon = '', hl = 'Special' },
      Enum = { icon = 'ℰ', hl = 'Type' },
      Interface = { icon = '󰜰', hl = 'Type' },
      Function = { icon = '', hl = 'Function' },
      Variable = { icon = '', hl = 'Constant' },
      Constant = { icon = '', hl = 'Constant' },
      String = { icon = '𝓐', hl = 'String' },
      Number = { icon = '#', hl = 'Number' },
      Boolean = { icon = '⊨', hl = 'Boolean' },
      Array = { icon = '󰅪', hl = 'Constant' },
      Object = { icon = '⦿', hl = 'Type' },
      Key = { icon = '🔐', hl = 'Type' },
      Null = { icon = 'NULL', hl = 'Type' },
      EnumMember = { icon = '', hl = 'Identifier' },
      Struct = { icon = '𝓢', hl = 'Structure' },
      Event = { icon = '🗲', hl = 'Type' },
      Operator = { icon = '+', hl = 'Identifier' },
      TypeParameter = { icon = '𝙏', hl = 'Identifier' },
      Component = { icon = '󰅴', hl = 'Function' },
      Fragment = { icon = '󰅴', hl = 'Constant' },
      -- ccls
      TypeAlias = { icon = ' ', hl = 'Type' },
      Parameter = { icon = ' ', hl = 'Identifier' },
      StaticMethod = { icon = ' ', hl = 'Function' },
      Macro = { icon = ' ', hl = 'Function' },
    },
  },
}

M.o = {}

function M.has_numbers()
  return M.o.outline_window.show_numbers or M.o.outline_window.show_relative_numbers
end

function M.get_position_navigation_direction()
  if M.o.outline_window.position == 'left' then
    return 'h'
  else
    return 'l'
  end
end

function M.get_window_width()
  if M.o.outline_window.relative_width then
    return math.ceil(vim.o.columns * (M.o.outline_window.width / 100))
  end
  return M.o.outline_window.width
end

function M.get_float_window_height()
  if M.o.outline_window.float.relative_height then
    return math.ceil(vim.o.lines * (M.o.outline_window.float.height / 100))
  end
  return M.o.outline_window.float.height
end

function M.get_float_window_width()
  if M.o.outline_window.float.relative_width then
    return math.ceil(vim.o.columns * (M.o.outline_window.float.width / 100))
  end
  return M.o.outline_window.float.width
end

---@param conf table
function M.get_preview_width(conf)
  if conf.relative_width then
    local relative_width = math.max(math.ceil(vim.o.columns * (conf.width / 100)), conf.min_width)
    return relative_width
  else
    return conf.width
  end
end

---@param conf table
---@param outline_height integer
---@return integer
function M.get_preview_height(conf, outline_height)
  if conf.relative_height then
    local relative_height =
      math.max(math.ceil(outline_height * (conf.height / 100)), conf.min_height)
    return relative_height
  else
    return conf.height
  end
end

function M.get_split_command()
  local sc = M.o.outline_window.split_command
  if sc then
    return sc
  end
  if M.o.outline_window.position == 'left' then
    return 'topleft vs'
  else
    return 'botright vs'
  end
end

local function table_has_content(t)
  return t and next(t) ~= nil
end

---Determine whether to include symbol in outline based on bufnr and its kind
---@param kind string
---@param bufnr integer
---@return boolean include
function M.should_include_symbol(kind, bufnr)
  local ft = utils.buf_get_option(bufnr, 'ft')
  -- There can only be one kind in markdown and norg as of now
  if ft == 'markdown' or ft == 'norg' or kind == nil then
    return true
  end

  local filter_table = M.o.symbols.filter[ft]
  local default_filter_table = M.o.symbols.filter.default

  -- When filter table for a ft is not specified, all symbols are shown
  if not filter_table then
    if not default_filter_table then
      return true
    else
      return default_filter_table[kind] ~= false
    end
  end

  -- If the given kind is not known by outline.nvim (ie: not in all_kinds),
  -- still return true. Only exclude those symbols that were explicitly
  -- filtered out.
  return filter_table[kind] ~= false
end

---@param client vim.lsp.Client|number
function M.is_client_blacklisted(client)
  if not client then
    return false
  end
  if type(client) == 'number' then
    client = vim.lsp.get_client_by_id(client)
    if not client then
      return false
    end
  end
  return M.o.providers.lsp.blacklist_clients[client.name] == true
end

---Retrieve and cache import paths of all providers in order of given priority
---@return string[]
function M.get_providers()
  if M.providers then
    return M.providers
  end

  M.providers = {}
  for _, p in ipairs(M.o.providers.priority) do
    if p == 'lsp' then
      p = 'nvim-lsp' -- due to legacy reasons
    end
    table.insert(M.providers, p)
  end
  return M.providers
end

---Check for inconsistent or mutually exclusive opts.
-- Does not alter the opts. Might show messages.
function M.check_config()
  if M.o.outline_window.hide_cursor and not M.o.outline_window.show_cursorline then
    utils.echo('config', 'Warning: hide_cursor enabled without cursorline enabled')
  end
end

---Resolve shortcuts and deprecated option conversions.
-- Might alter opts. Might show messages.
function M.resolve_config()
  ----- GUIDES -----
  local guides = M.o.guides
  if type(guides) == 'boolean' then
    M.o.guides = M.defaults.guides
    if not guides then
      M.o.guides.enabled = false
    end
  end
  if not M.o.guides.enabled then
    M.o.guides = {
      enabled = true,
      markers = { middle = ' ', vertical = ' ', bottom = ' ' },
    }
  end
  ----- SPLIT COMMAND -----
  local sc = M.o.outline_window.split_command
  if sc then
    -- This should not be needed, nor is it failsafe. But in case user only provides
    -- the, eg, "topleft", we append the ' vs'.
    if not sc:find(' vs', 1, true) then
      M.o.outline_window.split_command = sc .. ' vs'
    end
  end
  ----- COMPAT (renaming) -----
  local dg = M.o.keymaps.down_and_goto
  local ug = M.o.keymaps.up_and_goto
  if dg then
    M.o.keymaps.down_and_jump = dg
    M.o.keymaps.down_and_goto = nil
  end
  if ug then
    M.o.keymaps.up_and_jump = ug
    M.o.keymaps.up_and_goto = nil
  end
  if M.o.outline_window.auto_goto then
    M.o.outline_window.auto_jump = M.o.outline_window.auto_goto
    M.o.outline_window.auto_goto = nil
  end
  ----- SYMBOLS FILTER -----
  M.resolve_filter_config()
  ----- AUTO UNFOLD -----
  local au = M.o.symbol_folding.auto_unfold
  if M.o.symbol_folding.auto_unfold_hover == nil then
    if au.hovered ~= nil then
      M.o.symbol_folding.auto_unfold_hover = au.hovered
    end
  end
  if type(au.only) ~= 'number' then
    au.only = (au.only and 1) or 0
  end
  ----- KEYMAPS -----
  for action, keys in pairs(M.o.keymaps) do
    if type(keys) == 'string' then
      M.o.keymaps[action] = { keys }
    end
  end
  ----- WINDOW -----
  M.o.outline_window.width = M.get_window_width()
  ----- LSP BLACKLIST -----
  local map = {}
  for _, client in ipairs(M.o.providers.lsp.blacklist_clients) do
    map[client] = true
  end
  M.o.providers.lsp.blacklist_clients = map
  ----- LSP PROVIDER CONFIG NAME -----
  M.o.providers['nvim-lsp'] = M.o.providers.lsp
end

---Ensure l is either table, false, or nil. If not, print warning using given
-- name that describes l, set l to nil, and return l.
---@generic T
---@param l T
---@param name string
---@return T
local function validate_filter_list(l, name)
  if type(l) == 'boolean' and l then
    utils.echo(
      'config',
      ('Setting %s to true is undefined behaviour. Defaulting to nil.'):format(name)
    )
    l = nil
  elseif l and type(l) ~= 'table' and type(l) ~= 'boolean' then
    utils.echo(
      'config',
      ('%s must either be a table, false, or nil. Defaulting to nil.'):format(name)
    )
    l = nil
  end
  return l
end

---Resolve shortcuts and compat opt for symbol filtering config, and set up
-- `M.o.symbols.filter` to be a proper `outline.FilterFtTable` lookup table.
function M.resolve_filter_config()
  ---@type outline.FilterConfig
  local tmp = M.o.symbols.filter
  tmp = validate_filter_list(tmp, 'symbols.filter')

  ---- legacy form -> ft filter list ----
  if table_has_content(M.o.symbols.blacklist) then
    tmp = { default = M.o.symbols.blacklist }
    tmp.default.exclude = true
    M.o.symbols.blacklist = nil
  else
    ---- nil or {} -> include all symbols ----
    -- For filter = {}: theoretically this would make no symbols show up. The
    -- user can't possibly want this (they should've disabled the plugin
    -- through the plugin manager); so we let filter = {} denote filter = nil
    -- (or false), meaning include all symbols.
    if not table_has_content(tmp) then
      tmp = { default = { exclude = true } }

      -- Lazy filter list -> ft filter list
    elseif tmp[1] then
      if type(tmp[1]) == 'string' then
        tmp = { default = vim.deepcopy(tmp) }
      else
        tmp.default = vim.deepcopy(tmp[1])
        tmp[1] = nil
      end
    end
  end

  M.o.symbols.user_config_filter = vim.deepcopy(tmp)

  ---@type outline.FilterFtList
  local filter = tmp
  ---@type outline.FilterFtTable
  M.o.symbols.filter = {}

  ---- ft filter list -> lookup table ----
  -- We do this so that all the O(N) checks happen once, in the setup phase,
  -- and checks for the filter list later on can be speedy.
  -- After this operation, filter table would have ft as keys, and for each
  -- value, it has each kind key denoting whether to include that kind for this
  -- filetype.
  -- {
  --   python = { String = false, Variable = true, ... },
  --   default = { File = true, Method = true, ... },
  -- }
  for ft, list in pairs(filter) do
    if type(ft) ~= 'string' then
      utils.echo(
        'config',
        'ft (keys) for symbols.filter table can only be string. Skipping this ft.'
      )
      goto continue
    end

    M.o.symbols.filter[ft] = {}

    list = validate_filter_list(list, ("filter list for ft '%s'"):format(ft))

    -- Ensure boolean.
    -- Catches setting some ft = false/nil, meaning include all kinds
    if not list then
      list = { exclude = true }
    else
      list.exclude = (list.exclude ~= nil and list.exclude) or false
    end

    -- If it's an exclude-list, set all kinds to be included (true) by default
    -- If it's an inclusive list, set all kinds to be excluded (false) by default
    for _, kind in pairs(all_kinds) do
      M.o.symbols.filter[ft][kind] = list.exclude
    end

    -- Now flip the switches
    for _, kind in ipairs(list) do
      M.o.symbols.filter[ft][kind] = not M.o.symbols.filter[ft][kind]
    end
    ::continue::
  end
end

function M.setup(options)
  vim.g.outline_loaded = 1
  M.o = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
  M.check_config()
  M.resolve_config()
end

return M
