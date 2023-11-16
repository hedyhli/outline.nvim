-- CONFIG

-- { 'String', 'Variable', exclude = true }
-- If FilterList is nil or false, means include all
---@class outline.FilterList: string[]?
---@field exclude boolean? If nil, means exclude=false, so the list would be an inclusive list.

-- {
--   python = { 'Variable', exclude = true },
--   go = { 'Field', 'Function', 'Method' },
--   ['\*'] = { 'String', exclude = true }
-- }
---@alias outline.FilterFtList { [string]: outline.FilterList } A filter list for each file type
---@alias outline.FilterConfig outline.FilterFtList|outline.FilterList
-- { String = false, Variable = true, File = true, ... }
---@alias outline.FilterTable { [string]: boolean }  Each kind:include pair where include is boolean, whether to include this kind. Used internally.
-- {
--   python = { String = false, Variable = true, ... },
--   ['\*'] = { File = true, Method = true, ... },
-- }
---@alias outline.FilterFtTable { [string]: outline.FilterTable } A filter table for each file type. Used internally.

-- SYMBOLS

---@class outline.SymbolNode
---@field name string
---@field depth integer
---@field parent outline.SymbolNode
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
---@field children? outline.SymbolNode[]
---@field traversal_child integer Should NOT be modified during iteration using parser.preorder_iter

---@class outline.FlatSymbolNode
---@field name string
---@field depth integer
---@field parent outline.SymbolNode
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
---@field children? outline.SymbolNode[]
---@field traversal_child integer
---@field line_in_outline integer
---@field prefix_length integer
---@field hovered boolean
---@field folded boolean

-- API

---@class outline.OutlineOpts
---@field focus_outline boolean?  Whether to focus on outline of after some operation. If nil, defaults to true
---@field on_symbols function?  After symbols have been received, before sidebar window is setup
---@field on_outline_setup function?   After sidebar window is setup
