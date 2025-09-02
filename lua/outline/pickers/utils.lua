local M = {}

M.all_kind = 'All'

function M.is_blank(s)
  return (
    s == nil
    or s == vim.NIL
    or (type(s) == 'string' and string.match(s, '%S') == nil)
    or (type(s) == 'table' and next(s) == nil)
  )
end

---@return string[]|nil
function M.get_contents_symbols(opts)
  if not opts.o.symbols.icons then
    vim.notify('simbols.icons not found!', vim.log.levels.ERROR)
    return
  end

  local symbols_items = {}

  for key, _ in pairs(opts.o.symbols.icons) do
    symbols_items[#symbols_items + 1] = key
  end

  symbols_items[#symbols_items + 1] = M.all_kind
  table.sort(symbols_items)

  return symbols_items
end

function M.pad_string(s, length)
  local string_s = tostring(s)
  return string.format('%s%' .. (length - #string_s) .. 's', string_s, ' ')
end

local rstrip_whitespace = function(str)
  str = string.gsub(str, '%s+$', '')
  return str
end

local function lstrip_whitespace(str, limit)
  if limit ~= nil then
    local num_found = 0
    while num_found < limit do
      str = string.gsub(str, '^%s', '')
      num_found = num_found + 1
    end
  else
    str = string.gsub(str, '^%s+', '')
  end
  return str
end

---@param str string
---@return string
function M.strip_whitespace(str)
  if str then
    return rstrip_whitespace(lstrip_whitespace(str))
  end
  return ''
end

return M
