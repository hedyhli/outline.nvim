local M = {
  name = 'norg',
  query = [[
  [
  (heading1 (heading1_prefix)
    title: (paragraph_segment) @name)
  (heading2 (heading2_prefix)
    title: (paragraph_segment) @name)
  (heading3 (heading3_prefix)
    title: (paragraph_segment) @name)
  (heading4 (heading4_prefix)
    title: (paragraph_segment) @name)
  (heading5 (heading5_prefix)
    title: (paragraph_segment) @name)
  (heading6 (heading6_prefix)
    title: (paragraph_segment) @name)
  ]
  ]],
}

---@param bufnr integer
---@param config table?
function M.supports_buffer(bufnr, config)
  if vim.api.nvim_buf_get_option(bufnr, 'ft') ~= 'norg' then
    return false
  end

  local status, parser = pcall(vim.treesitter.get_parser, bufnr, 'norg')
  if not status or not parser then
    return false
  end

  M.parser = parser
  return true
end

local is_ancestor = vim.treesitter.is_ancestor

if not _G._outline_nvim_has[8] then
  is_ancestor = function(dest, source)
    if not (dest and source) then
      return false
    end

    local current = source
    while current ~= nil do
      if current == dest then
        return true
      end

      current = current:parent()
    end

    return false
  end
end

---@param node outline.ProviderSymbol
---@param field string
local function rec_remove_field(node, field)
  node[field] = nil
  if node.children then
    for _, child in ipairs(node.children) do
      rec_remove_field(child, field)
    end
  end
end

---@param callback fun(symbols?:outline.ProviderSymbol[], opts?:table)
---@param opts table
function M.request_symbols(callback, opts)
  if not M.parser then
    local status, parser = pcall(vim.treesitter.get_parser, 0, 'norg')

    if not status or not parser then
      callback(nil, opts)
      return
    end

    M.parser = parser
  end

  local root = M.parser:parse()[1]:root()
  if not root then
    callback(nil, opts)
    return
  end

  local r = { children = {}, tsnode = root, name = 'root' }
  local stack = { r }

  local query
  if _G._outline_nvim_has[9] then
    query = vim.treesitter.query.parse('norg', M.query)
  else
    ---@diagnostic disable-next-line: deprecated
    query = vim.treesitter.query.parse_query('norg', M.query)
  end
  ---@diagnostic disable-next-line: missing-parameter
  for _, captured_node, _ in query:iter_captures(root, 0) do
    local row1, col1, row2, col2 = captured_node:range()
    local title = vim.api.nvim_buf_get_text(0, row1, col1, row2, col2, {})[1]
    local heading_node = captured_node:parent()
    row1, col1, row2, col2 = heading_node:range()

    title = title:gsub('^%s+', '')

    local current = {
      kind = 15,
      name = title,
      -- Treesitter includes the last newline in the end range which spans
      -- until the next heading, so we -1
      -- TODO: This fix can be removed when we let highlight_hovered_item
      -- account for current column position in addition to the line.
      -- FIXME: By the way the end character should be the EOL
      selectionRange = {
        start = { character = col1, line = row1 },
        ['end'] = { character = col2, line = row2 - 1 },
      },
      range = {
        start = { character = col1, line = row1 },
        ['end'] = { character = col2, line = row2 - 1 },
      },
      children = {},
      tsnode = heading_node,
    }

    while #stack > 0 do
      local top = stack[#stack]
      if is_ancestor(top.tsnode, heading_node) then
        current.parent = top
        table.insert(top.children, current)
        break
      end
      table.remove(stack, #stack)
    end

    table.insert(stack, current)
  end

  rec_remove_field(r, 'tsnode')

  callback(r.children, opts)
end

return M
