-- CONFIG

-- { 'String', 'Variable', exclude = true }
-- If FilterList is nil or false, means include all
---@class outline.FilterList: string[]?
---@field exclude boolean? If nil, means exclude=false, so the list would be an inclusive list.

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
---@field config table?
---@field get_status? fun(info:table?):string[]
---@field supports_buffer fun(bufnr:integer, config:table?):boolean,table?
---@field request_symbols fun(on_symbols:fun(symbols?:outline.ProviderSymbol[], opts:table?, provider_info:table?), opts:table?)
---@field show_hover? fun(sidebar:outline.Sidebar):boolean
---@field rename_symbol? fun(sidebar:outline.Sidebar):boolean
---@field code_actions? fun(sidebar:outline.Sidebar):boolean

-- HELP

---@class outline.HL
---@field line integer Line number 1-indexed
---@field from integer
---@field to integer
---@field name string

---@class outline.StatusContext
---@field provider outline.Provider?
---@field provider_info table?
---@field outline_open boolean?
---@field code_win_active boolean?
---@field ft string?
---@field filter outline.FilterList?
---@field default_filter outline.FilterList?
---@field priority string[]?

-- API

---@class outline.OutlineOpts
---@field focus_outline boolean?  Whether to focus on outline of after some operation. If nil, defaults to true
---@field split_command string?
---@field use_float boolean? Whether to use floating window

---@class outline.BreadcrumbOpts
---@field depth integer?
---@field sep string?

---@class outline.SymbolOpts
---@field depth integer?
---@field kind string?
