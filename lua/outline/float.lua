---@class outline.Float
local Float = {}

---@class outline.Float
---@field bufnr integer
---@field winnr integer
---@field ns integer

function Float:new()
  return setmetatable({ bufnr = nil, winnr = nil, ns = nil }, { __index = Float })
end

---Set up a floating window with OutlineHelp ft
---@param lines string[]
---@param hl outline.HL[]
---@param title string
---@param indent integer?
function Float:open(lines, hl, title, indent)
  indent = indent or 0

  self.bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(self.bufnr, 'bufhidden', 'delete')

  local maxwidth = 0
  for _, l in ipairs(lines) do
    if #l > maxwidth then
      maxwidth = #l
    end
  end

  local ui = vim.api.nvim_list_uis()[1]
  local nvim_height, nvim_width = ui.height, ui.width

  local padding_w = 3

  local height, width = math.min(nvim_height, #lines + 1), maxwidth + 2 * padding_w
  local row = math.floor((nvim_height - height) / 2)
  local col = math.floor((nvim_width - width) / 2)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded',
    style = 'minimal',
  }
  if _G._outline_nvim_has[9] then
    opts.title = title
    opts.title_pos = 'center'
  end

  self.winnr = vim.api.nvim_open_win(self.bufnr, true, opts)

  if indent > 0 then
    local pad = string.rep(' ', indent)
    for i = 1, #lines do
      lines[i] = pad .. lines[i]
    end
  end

  vim.api.nvim_win_set_option(self.winnr, 'winfixwidth', true)
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(self.bufnr, 'ft', 'OutlineHelp')

  if hl then
    self.ns = vim.api.nvim_create_namespace('OutlineHelp')
    for _, h in ipairs(hl) do
      vim.api.nvim_buf_add_highlight(
        self.bufnr,
        self.ns,
        h.name,
        h.line,
        h.from + indent,
        (h.to ~= -1 and h.to + indent) or -1
      )
    end
  end
end

function Float:close()
  if self.winnr then
    if self.ns then
      vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns, 0, -1)
    end
    vim.api.nvim_win_close(self.winnr, true)
    self.winnr = nil
    self.bufnr = nil
  end
end

return Float
