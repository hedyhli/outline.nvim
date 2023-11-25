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

---@param kind string|integer
function M.icon_from_kind(kind)
  local kindstr = kind
  if type(kind) ~= 'string' then
    kindstr = M.kinds[kind]
  end
  if not kindstr then
    kindstr = 'Object'
  end

  if type(cfg.o.symbols.icon_fetcher) == 'function' then
    local icon = cfg.o.symbols.icon_fetcher(kindstr)
    -- Allow returning empty string
    if icon then
      return icon
    end
  end

  if cfg.o.symbols.icon_source == 'lspkind' then
    local has_lspkind, lspkind = pcall(require, 'lspkind')
    if not has_lspkind then
      vim.notify(
        '[outline]: icon_source set to lspkind but failed to require lspkind!',
        vim.log.levels.ERROR
      )
    else
      local icon = lspkind.symbolic(kindstr, { with_text = false })
      if icon and icon ~= '' then
        return icon
      end
    end
  end

  return cfg.o.symbols.icons[kindstr].icon
end

return M
