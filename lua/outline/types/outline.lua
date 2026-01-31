-- CONFIG

-- { 'String', 'Variable', exclude = true }
-- If FilterList is nil or false, means include all
---@class outline.FilterList: string[]?
---@field exclude? boolean If nil, means exclude=false, so the list would be an inclusive list.

-- {
--   python = { 'Variable', exclude = true },
--   go = { 'Field', 'Function', 'Method' },
--   default = { 'String', exclude = true }
-- }
---@alias outline.FilterFtList { [string]: outline.FilterList } A filter list for each file type
---@alias outline.FilterConfig outline.FilterFtList|outline.FilterList
-- { String = false, Variable = true, File = true, ... }
---@alias outline.FilterTable { [string]: boolean }  Each kind:include pair where include is boolean, whether to include this kind. Used internally.
-- {
--   python = { String = false, Variable = true, ... },
--   default = { File = true, Method = true, ... },
-- }
---@alias outline.FilterFtTable { [string]: outline.FilterTable } A filter table for each file type. Used internally.

-- SYMBOLS

---@class outline.ProviderSymbol
---@field name string
---@field kind integer
---@field detail? string
---@field range outline.ProviderSymbolRange
---@field selectionRange outline.ProviderSymbolRange
---@field parent outline.ProviderSymbol
---@field children outline.ProviderSymbol[]

---@class outline.ProviderSymbolRange
---@field start integer
---@field end integer

---@class outline.Symbol
---@field name string
---@field depth integer
---@field parent outline.Symbol
---@field deprecated boolean
---@field kind integer|string
---@field icon string
---@field detail string
---@field line integer
---@field character integer
---@field range_start integer
---@field range_end integer
---@field isLast boolean
---@field hierarchy boolean
---@field children? outline.Symbol[]
---@field _i integer Should NOT be modified during iteration using parser.preorder_iter
---@field is_root? boolean

---@class outline.FlatSymbol : outline.Symbol
---@field line_in_outline integer
---@field prefix_length integer
---@field hovered boolean
---@field folded boolean

-- PROVIDER

---@class outline.Provider
---@field name string
---@field config? table
---@field get_status? fun(info?: table): string[]
---@field supports_buffer fun(bufnr: integer, config?: table): boolean, table?
---@field request_symbols fun(on_symbols: fun(symbols?: outline.ProviderSymbol[], opts?: table, provider_info?: table), opts?: table)
---@field show_hover? fun(sidebar: outline.Sidebar): boolean
---@field rename_symbol? fun(sidebar: outline.Sidebar): boolean
---@field code_actions? fun(sidebar: outline.Sidebar): boolean

-- HELP

---@class outline.HL
---@field line integer Line number 1-indexed
---@field from integer
---@field to integer
---@field name string

---@class outline.StatusContext
---@field provider? outline.Provider
---@field provider_info? table
---@field outline_open? boolean
---@field code_win_active? boolean
---@field ft? string
---@field filter? outline.FilterList
---@field default_filter? outline.FilterList
---@field priority? string[]

-- API

---@class outline.OutlineOpts
---@field focus_outline? boolean  Whether to focus on outline of after some operation. If nil, defaults to true
---@field split_command? string

---@class outline.BreadcrumbOpts
---@field depth? number
---@field sep? string

---@class outline.SymbolOpts
---@field depth? number
---@field kind? string

---@alias outline.AllKinds
---|'Array'
---|'Boolean'
---|'Class'
---|'Component'
---|'Constant'
---|'Constructor'
---|'Enum'
---|'EnumMember'
---|'Event'
---|'Field'
---|'File'
---|'Fragment'
---|'Function'
---|'Interface'
---|'Key'
---|'Macro'
---|'Method'
---|'Module'
---|'Namespace'
---|'Null'
---|'Number'
---|'Object'
---|'Operator'
---|'Package'
---|'Parameter'
---|'Property'
---|'StaticMethod'
---|'String'
---|'Struct'
---|'TypeAlias'
---|'TypeParameter'
---|'Variable'

---@class outline.SetupOpts.Guides
---@field enabled? boolean
---@field markers? { bottom?: string, middle?: string, vertical?: string, horizontal?: string }

---@class outline.SetupOpts.Symbols
---@field filter? nil|outline.FilterConfig
---@field icon_fetcher? nil|fun(kind: string, bufnr: integer, symbol: outline.Symbol): icon_string: string|boolean
---@field icon_source? nil|'lspkind'
---@field icons? table<outline.AllKinds, { icon?: string, hl?: string }>

---@class outline.SetupOpts.Providers
---@field priority? ('lsp'|'coc'|'markdown'|'norg'|'man')[]
---@field lsp? { blacklist_clients?: string[] }
---@field markdown? { filetypes?: string[] }

---@class outline.SetupOpts.Keymaps
---@field close? nil|string[]|string
---@field code_actions? nil|string[]|string
---@field down_and_jump? nil|string[]|string
---@field fold? nil|string[]|string
---@field fold_all? nil|string[]|string
---@field fold_reset? nil|string[]|string
---@field fold_toggle? nil|string[]|string
---@field fold_toggle_all? nil|string[]|string
---@field goto_and_close? nil|string[]|string
---@field goto_location? nil|string[]|string
---@field hover_symbol? nil|string[]|string
---@field peek_location? nil|string[]|string
---@field rename_symbol? nil|string[]|string
---@field restore_location? nil|string[]|string
---@field show_help? nil|string[]|string
---@field toggle_preview? nil|string[]|string
---@field unfold? nil|string[]|string
---@field unfold_all? nil|string[]|string
---@field up_and_jump? nil|string[]|string

---@class outline.SetupOpts.OutlineItems
---@field show_symbol_details? boolean
---@field show_symbol_lineno? boolean
---@field highlight_hovered_item? boolean
-- On open, always followed. This is for auto_update_events.follow, whether
-- to auto update cursor position to reflect code location. If false, can
-- manually trigger with follow_cursor (API, command, keymap action).
---@field auto_set_cursor? boolean
---@field auto_update_events? { follow?: string[], items?: string[] }

---@class outline.SetupOpts.PreviewWindow
---@field auto_preview? boolean
---@field open_hover_on_preview? boolean
---@field width? number
---@field min_width? integer
---@field relative_width? boolean
---@field height? integer
---@field min_height? integer
---@field relative_height? boolean
---@field border? 'single'|'bold'|'double'|'none'|'rounded'|'shadow'|'solid'
---@field winhl? string
---@field winblend? integer
---@field live? boolean

---@class outline.SetupOpts.OutlineWindow
---@field position? 'right'|'left'
---@field width? number
---@field relative_width? boolean
---@field split_command? nil|string
---@field wrap? boolean
---@field focus_on_open? boolean
---@field auto_close? boolean
---@field auto_jump? boolean
---@field show_numbers? boolean
---@field show_relative_numbers? boolean
---@field show_cursorline? boolean|'focus_in_outline'|'focus_in_code'
---@field hide_cursor? boolean
---@field winhl? string
---@field jump_highlight_duration? boolean|integer
---@field center_on_jump? boolean
---@field no_provider_message? string

---@class outline.SetupOpts.SymbolFolding
---@field autofold_depth? false|integer
---@field markers? string[]
---@field auto_unfold? { hovered?: boolean, only?: boolean }
