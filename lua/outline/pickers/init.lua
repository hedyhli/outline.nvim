local util = require('outline.pickers.utils')
local M = {}

local function default_picker()
  return 'default'
end

---@param picker_name string?
local function get_picker(picker_name)
  picker_name = picker_name or ''
  local ok_picker, _ = pcall(require, picker_name)
  if not ok_picker then
    picker_name = picker_name
  end

  if util.is_blank(picker_name) then
    picker_name = default_picker()
  end

  local ok, p = pcall(require, string.format('outline.pickers.%s', picker_name))
  if not ok then
    vim.notify(
      string.format('Picker `%s` has not been implemented yet', picker_name),
      vim.log.levels.ERROR
    )
    return
  end

  return p
end

---@param sidebar outline.Sidebar
function M.select_symbols(cfg_symbols, sidebar)
  local p = get_picker(cfg_symbols.o.picker)

  local contents = util.get_contents_symbols(cfg_symbols)
  if not contents or #contents == 0 then
    return
  end

  ---@param sel table|nil
  cfg_symbols.set_filters = function(sel)
    if #sel == 0 then
      sel = nil
    end

    cfg_symbols.o.symbols.filter = sel
    cfg_symbols.o.outline_window.width = 25
    cfg_symbols.setup(vim.tbl_deep_extend('force', {}, cfg_symbols.defaults, cfg_symbols.o or {}))

    if sidebar.view:is_open() and sidebar:has_code_win() then
      sidebar:close()
    end

    -- wait some time to avoid buffer-name conflict
    vim.wait(1500, function()
      return sidebar.view:is_open()
    end)

    sidebar:open()
  end

  if p then
    p(cfg_symbols, contents)
  end
end

return M
