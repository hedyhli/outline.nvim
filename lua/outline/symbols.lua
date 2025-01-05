local cfg = require('outline.config')

local M = {}

M.kinds = {
  [1] = 'File',
  [2] = 'Module',
  [3] = 'Namespace',
  [4] = 'Package',
  [5] = 'Class',
  [6] = 'Method',
  [7] = 'Property',
  [8] = 'Field',
  [9] = 'Constructor',
  [10] = 'Enum',
  [11] = 'Interface',
  [12] = 'Function',
  [13] = 'Variable',
  [14] = 'Constant',
  [15] = 'String',
  [16] = 'Number',
  [17] = 'Boolean',
  [18] = 'Array',
  [19] = 'Object',
  [20] = 'Key',
  [21] = 'Null',
  [22] = 'EnumMember',
  [23] = 'Struct',
  [24] = 'Event',
  [25] = 'Operator',
  [26] = 'TypeParameter',
  [27] = 'Component',
  [28] = 'Fragment',

  -- ccls
  [252] = 'TypeAlias',
  [253] = 'Parameter',
  [254] = 'StaticMethod',
  [255] = 'Macro',
}

-- inverse indexing of symbols.kind
M.str_to_kind = {}
for k, v in pairs(M.kinds) do
  M.str_to_kind[v] = k
end

-- use a stub if lspkind is missing or not configured
local lspkind = {
  symbolic = function(kind, opts)
    return ''
  end,
}

---@param kind string|integer
---@param bufnr integer
---@param symbol outline.Symbol
---@return string icon
function M.icon_from_kind(kind, bufnr, symbol)
  local kindstr = kind
  if type(kind) ~= 'string' then
    kindstr = M.kinds[kind]
  end
  if not kindstr then
    kindstr = 'Object'
  end

  if type(cfg.o.symbols.icon_fetcher) == 'function' then
    local icon = cfg.o.symbols.icon_fetcher(kindstr, bufnr, symbol)
    -- Allow returning empty string
    if icon then
      return icon
    end
  end

  local icon = lspkind.symbolic(kindstr, { with_text = false })
  if icon and icon ~= '' then
    return icon
  end

  return cfg.o.symbols.icons[kindstr].icon
end

function M.setup()
  if cfg.o.symbols.icon_source == 'lspkind' then
    local has_lspkind, _lspkind = pcall(require, 'lspkind')
    if has_lspkind then
      lspkind = _lspkind
    else
      vim.notify(
        '[outline]: icon_source set to lspkind but failed to require lspkind!',
        vim.log.levels.ERROR
      )
    end
  end
end

return M
