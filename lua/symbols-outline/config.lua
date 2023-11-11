local vim = vim

local M = {}

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
    highlight_hovered_item = true,
  },
  outline_window = {
    position = 'right',
    width = 25,
    relative_width = true,
    wrap = false,
    focus_on_open = true,
    auto_close = false,
    auto_goto = false,
    show_numbers = false,
    show_relative_numbers = false,
    show_cursorline = true,
    hide_cursor = false,
    winhl = "SymbolsOutlineDetails:Comment,SymbolsOutlineLineno:LineNr",
  },
  preview_window = {
    auto_preview = false,
    width = 50,
    min_width = 50,
    relative_width = true,
    border = 'single',
    open_hover_on_preview = true,
    winhl = '',
    winblend = 0,
  },
  symbol_folding = {
    autofold_depth = nil,
    auto_unfold_hover = true,
    markers = { '', '' },
  },
  keymaps = {
    show_help = '?',
    close = { '<Esc>', 'q' },
    goto_location = '<Cr>',
    peek_location = 'o',
    goto_and_close = '<S-Cr>',
    restore_location = "<C-g>",
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
    down_and_goto = '<C-j>',
    up_and_goto = '<C-k>',
  },
  providers = {
    lsp = {
      blacklist_clients = {},
    },
  },
  symbols = {
    blacklist = {},
    icons = {
      File = { icon = '󰈔', hl = '@text.uri' },
      Module = { icon = '󰆧', hl = '@namespace' },
      Namespace = { icon = '󰅪', hl = '@namespace' },
      Package = { icon = '󰏗', hl = '@namespace' },
      Class = { icon = '𝓒', hl = '@type' },
      Method = { icon = 'ƒ', hl = '@method' },
      Property = { icon = '', hl = '@method' },
      Field = { icon = '󰆨', hl = '@field' },
      Constructor = { icon = '', hl = '@constructor' },
      Enum = { icon = 'ℰ', hl = '@type' },
      Interface = { icon = '󰜰', hl = '@type' },
      Function = { icon = '', hl = '@function' },
      Variable = { icon = '', hl = '@constant' },
      Constant = { icon = '', hl = '@constant' },
      String = { icon = '𝓐', hl = '@string' },
      Number = { icon = '#', hl = '@number' },
      Boolean = { icon = '⊨', hl = '@boolean' },
      Array = { icon = '󰅪', hl = '@constant' },
      Object = { icon = '⦿', hl = '@type' },
      Key = { icon = '🔐', hl = '@type' },
      Null = { icon = 'NULL', hl = '@type' },
      EnumMember = { icon = '', hl = '@field' },
      Struct = { icon = '𝓢', hl = '@type' },
      Event = { icon = '🗲', hl = '@type' },
      Operator = { icon = '+', hl = '@operator' },
      TypeParameter = { icon = '𝙏', hl = '@parameter' },
      Component = { icon = '󰅴', hl = '@function' },
      Fragment = { icon = '󰅴', hl = '@constant' },
      -- ccls
      TypeAlias =  { icon = ' ', hl = '@type' },
      Parameter = { icon = ' ', hl = '@parameter' },
      StaticMethod = { icon = ' ', hl = '@function' },
      Macro = { icon = ' ', hl = '@macro' },
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
  else
    return M.o.outline_window.width
  end
end

function M.get_preview_width()
  if M.o.preview_window.relative_width then
    local relative_width = math.ceil(vim.o.columns * (M.o.preview_window.width / 100))

    if relative_width < M.o.preview_window.min_width then
      return M.o.preview_window.min_width
    else
      return relative_width
    end
  else
    return M.o.preview_window.width
  end
end

function M.get_split_command()
  if M.o.outline_window.position == 'left' then
    return 'topleft vs'
  else
    return 'botright vs'
  end
end

local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

function M.is_symbol_blacklisted(kind)
  if kind == nil then
    return false
  end
  return has_value(M.o.symbols.blacklist, kind)
end

function M.is_client_blacklisted(client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then
    return false
  end
  return has_value(M.o.providers.lsp.blacklist_clients, client.name)
end

function M.show_help()
  print 'Current keymaps:'
  print(vim.inspect(M.o.keymaps))
end

function M.check_config()
  if M.o.outline_window.hide_cursor and not M.o.outline_window.show_cursorline then
    vim.notify("[symbols-outline.config]: hide_cursor enabled WITHOUT cursorline enabled!", vim.log.levels.ERROR)
  end
end

function M.setup(options)
  vim.g.symbols_outline_loaded = 1
  M.o = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
  local guides = M.o.guides
  if type(guides) == 'boolean' and guides then
    M.o.guides = M.defaults.guides
  end
  M.check_config()
end

return M
