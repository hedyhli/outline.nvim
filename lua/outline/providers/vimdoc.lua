local M = {
  name = 'vimdoc'
}

local LANG = 'vimdoc'
local MAX_LINES_COUNT = 1000000000

---@param bufnr integer
---@param _ table?
---@return boolean
function M.supports_buffer(bufnr, _)
  local val = vim.api.nvim_get_option_value('ft', { buf = bufnr })
  if val ~= 'help' then
    return false
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, LANG)
  if not ok then
    return false
  end

  M.parser = parser
  return true
end

---@param on_symbols fun(symbols?:outline.ProviderSymbol[], opts?:table)
---@param opts table
function M.request_symbols(on_symbols, opts)
  local rootNode = M.parser:parse()[1]:root()

  local queryString = [[
    [
      (h1 (heading) @h1)
      (h2 (heading) @h2)
      (h3 (heading) @h3)
      (tag) @tag
    ]
  ]]
  local query
  if _G._outline_nvim_has[9] then
    query = vim.treesitter.query.parse(LANG, queryString)
  else
    ---@diagnostic disable-next-line: deprecated
    query = vim.treesitter.query.parse_query(LANG, queryString)
  end

  local captureLevelMap = { h1 = 1, h2 = 2, h3 = 3, tag = 4 }
  local kindMap = { h1 = 15, h2 = 15, h3 = 15, tag = 13 }

  local root = { children = {}, level = 0, parent = nil }
  local current = root

  local function updateRangeEnd(node, rangeEnd)
    if node.range ~= nil and node.level <= 3 then
      node.range['end'] = { character = node.range['end'], line = rangeEnd }
      node.selectionRange = node.range
    end
  end

  for id, node, _, _ in query:iter_captures(rootNode, 0) do
    local capture = query.captures[id]
    local captureLevel = captureLevelMap[capture]

    local row1, col1, row2, col2 = node:range()
    local captureString = vim.api.nvim_buf_get_text(0, row1, col1, row2, col2, {})[1]

    local prevHeadingsRangeEnd = row1 - 1
    local rangeStart = row1
    if captureLevel <= 2 then
      prevHeadingsRangeEnd = prevHeadingsRangeEnd - 1
      rangeStart = rangeStart - 1
    end

    while captureLevel <= current.level do
      updateRangeEnd(current, prevHeadingsRangeEnd)
      current = current.parent
      assert(current ~= nil)
    end

    local new = {
      kind = kindMap[capture],
      name = captureString,
      -- Treesitter includes the last newline in the end range which spans
      -- until the next heading, so we -1
      -- TODO: This fix can be removed when we let highlight_hovered_item
      -- account for current column position in addition to the line.
      -- FIXME: By the way the end character should be the EOL
      selectionRange = {
        start = { character = col1, line = rangeStart },
        ['end'] = { character = col2, line = row2 - 1 },
      },
      range = {
        start = { character = col1, line = rangeStart },
        ['end'] = { character = col2, line = row2 - 1 },
      },
      children = {},

      parent = current,
      level = captureLevel,
    }

    table.insert(current.children, new)
    current = new
  end

  while current.level > 0 do
    updateRangeEnd(current, MAX_LINES_COUNT)
    current = current.parent
    assert(current ~= nil)
  end

  local function removeExtraAttrs(node)
    for _, child in pairs(node.children) do
      removeExtraAttrs(child)
    end
    node.parent = nil
    node.level = nil
  end
  removeExtraAttrs(root)

  on_symbols(root.children, opts)
end

return M
