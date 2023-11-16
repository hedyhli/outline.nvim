local M = {}

---maps the table|string of keys to the action
---@param keys table|string
---@param action function|string
function M.nmap(bufnr, keys, action)
  if type(keys) == 'string' then
    keys = { keys }
  end

  for _, lhs in ipairs(keys) do
    vim.keymap.set(
      'n',
      lhs,
      action,
      { silent = true, noremap = true, buffer = bufnr }
    )
  end
end

--- @param  f function
--- @param  delay number
--- @return function
function M.debounce(f, delay)
  local timer = vim.loop.new_timer()

  return function(...)
    local args = { ... }

    timer:start(
      delay,
      0,
      vim.schedule_wrap(function()
        timer:stop()
        f(unpack(args))
      end)
    )
  end
end

function M.items_dfs(callback, children)
  for _, val in ipairs(children) do
    callback(val)

    if val.children then
      M.items_dfs(callback, val.children)
    end
  end
end

---Merges a symbol tree recursively, only replacing nodes
---which have changed. This will maintain the folding
---status of any unchanged nodes.
---@param new_node table New node
---@param old_node table Old node
---@param index? number Index of old_item in parent
---@param parent? table Parent of old_item
function M.merge_items_rec(new_node, old_node, index, parent)
  local failed = false

  if not new_node or not old_node then
    failed = true
  else
    for key, _ in pairs(new_node) do
      if
        vim.tbl_contains({
          'parent',
          'children',
          'folded',
          'hovered',
          'line_in_outline',
          'hierarchy',
        }, key)
      then
        goto continue
      end

      if key == 'name' then
        -- in the case of a rename, just rename the existing node
        old_node['name'] = new_node['name']
      else
        if not vim.deep_equal(new_node[key], old_node[key]) then
          failed = true
          break
        end
      end

      ::continue::
    end
  end

  if failed then
    if parent and index then
      parent[index] = new_node
    end
  else
    local next_new_item = new_node.children or {}

    -- in case new children are created on a node which
    -- previously had no children
    if #next_new_item > 0 and not old_node.children then
      old_node.children = {}
    end

    local next_old_item = old_node.children or {}

    for i = 1, math.max(#next_new_item, #next_old_item) do
      M.merge_items_rec(next_new_item[i], next_old_item[i], i, next_old_item)
    end
  end
end

function M.flash_highlight(winnr, lnum, durationMs, hl_group)
  if durationMs == false then
    return
  end
  hl_group = hl_group or "Visual"
  if durationMs == true or durationMs == 1 then
    durationMs = 500
  end
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local ns = vim.api.nvim_buf_add_highlight(bufnr, 0, hl_group, lnum - 1, 0, -1)
  local remove_highlight = function()
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
  end
  vim.defer_fn(remove_highlight, durationMs)
end

---@param module string   Used as message if second param omitted
---@param message string?
function M.echo(module, message)
  if not message then
    message = module
    module = ""
  end
  local prefix = "outline"
  if module ~= "" then
    prefix = prefix.."."..module
  end
  local prefix_chunk = { '('..prefix..') ', "WarningMsg" }
  -- For now we don't echo much, so add all to history
  vim.api.nvim_echo({ prefix_chunk, { message } }, true, {})
end

return M
