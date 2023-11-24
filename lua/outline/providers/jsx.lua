-- This is not a real provider. It is used by nvim-lsp to obtain JSX symbols
-- using treesitter to be merged to symbols from javascript/typescript language
-- servers

local M = {}

local KIND_COMPONENT = 27
local KIND_FRAGMENT = 28

local function get_open_tag(node)
  if node:type() == 'jsx_element' then
    for _, outer in ipairs(node:field('open_tag')) do
      if outer:type() == 'jsx_opening_element' then
        return outer
      end
    end
  end

  return nil
end

local function jsx_node_detail(node, buf)
  node = get_open_tag(node) or node

  local param_nodes = node:field('attribute')
  if #param_nodes == 0 then
    return nil
  end

  local res = '{ '
    .. table.concat(
      vim.tbl_map(function(el)
        local a, b, c, d = el:range()
        local text = vim.api.nvim_buf_get_text(buf, a, b, c, d, {})
        return text[1]
      end, param_nodes),
      ' '
    )
    .. ' }'

  return res
end

local function jsx_node_tagname(node, buf)
  local tagnode = get_open_tag(node) or node

  local identifier = nil

  for _, val in ipairs(tagnode:field('name')) do
    if val:type() == 'identifier' then
      identifier = val
    end
  end

  if identifier then
    local a, b, c, d = identifier:range()
    local text = vim.api.nvim_buf_get_text(buf, a, b, c, d, {})
    local name = table.concat(text)
    return name
  end
end

local function convert_ts(child, children, bufnr)
  local is_frag = (child:type() == 'jsx_fragment')
  local name = jsx_node_tagname(child, bufnr)

  -- jsx_fragment (<></>) was removed in July 2023. Now we treat all
  -- jsx_opening_element's that do not have a name field to be 'Fragment', same
  -- capitalization as if imported from react rather than using the shorthand.
  if is_frag or not name then
    is_frag = true
    name = 'Fragment'
  end

  local a, b, c, d = child:range()
  local range = {
    start = { line = a, character = b },
    ['end'] = { line = c, character = d },
  }

  local converted = {
    name = name,
    children = (#children > 0 and children) or nil,
    kind = (is_frag and KIND_FRAGMENT) or KIND_COMPONENT,
    detail = jsx_node_detail(child, bufnr),
    range = range,
    selectionRange = range,
  }

  return converted
end

function M.parse_ts(root, children, bufnr)
  children = children or {}

  for child in root:iter_children() do
    if
      vim.tbl_contains({ 'jsx_element', 'jsx_self_closing_element', 'jsx_fragment' }, child:type())
    then
      local new_children = {}

      M.parse_ts(child, new_children, bufnr)

      table.insert(children, convert_ts(child, new_children, bufnr))
    else
      M.parse_ts(child, children, bufnr)
    end
  end

  return children
end

function M.get_symbols(bufnr)
  bufnr = bufnr or 0

  local status, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not status then
    return {}
  end

  if parser == nil then
    return {}
  end

  local root = parser:parse()[1]:root()

  if root == nil then
    return {}
  end

  return M.parse_ts(root, nil, bufnr)
end

return M
