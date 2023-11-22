local M = {}

M.hovered_hl_ns = vim.api.nvim_create_namespace('hovered_item')

function M.clear_hover_highlight(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.hovered_hl_ns, 0, -1)
end

function M.add_hover_highlight(bufnr, line, col_start)
  vim.api.nvim_buf_add_highlight(bufnr, M.hovered_hl_ns, 'OutlineCurrent', line, col_start, -1)
end

local get_hl_by_name

if vim.fn.has('nvim-0.9') == 1 then
  get_hl_by_name = function(name)
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    return { fg = hl.fg, bg = hl.bg, ctermfg = hl.ctermfg, ctermbg = hl.ctermbg }
  end
else
  get_hl_by_name = function(name)
    ---@diagnostic disable-next-line undefined-field
    local hlrgb = vim.api.nvim_get_hl_by_name(name, true)
    ---@diagnostic disable-next-line undefined-field
    local hl = vim.api.nvim_get_hl_by_name(name, false)
    return {
      fg = hlrgb.foreground,
      bg = hlrgb.background,
      ctermfg = hl.foreground,
      ctermbg = hl.background,
    }
  end
end

function M.setup_highlights()
  -- Setup the OutlineCurrent highlight group if it hasn't been done already by
  -- a theme or manually set
  if vim.fn.hlexists('OutlineCurrent') == 0 then
    local cline_hl = get_hl_by_name('CursorLine')
    local string_hl = get_hl_by_name('String')

    vim.api.nvim_set_hl(0, 'OutlineCurrent', {
      bg = cline_hl.bg,
      fg = string_hl.fg,
      ctermbg = cline_hl.ctermbg,
      ctermfg = string_hl.ctermfg,
    })
  end

  -- Only inherit fg for these highlights because we do not want the other
  -- stylings messing up the alignment, nor the background so that cursorline
  -- can look normal when on top of it. This can be customized by setting these
  -- highlights before outline.setup() is called, or using winhl.
  for name, link in pairs({ Guides = 'Comment', FoldMarker = 'Normal' }) do
    if vim.fn.hlexists('Outline' .. name) == 0 then
      local h = get_hl_by_name(link)
      vim.api.nvim_set_hl(0, 'Outline' .. name, { fg = h.fg, ctermfg = h.fg })
    end
  end

  for name, link in pairs({
    Details = 'Comment',
    Lineno = 'LineNr',
    JumpHighlight = 'Visual',
  }) do
    if vim.fn.hlexists('Outline' .. name) == 0 then
      vim.api.nvim_set_hl(0, 'Outline' .. name, { link = link })
    end
  end
end

return M
