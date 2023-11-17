local M = {}

M.hovered_hl_ns = vim.api.nvim_create_namespace('hovered_item')

function M.clear_hover_highlight(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.hovered_hl_ns, 0, -1)
end

function M.add_hover_highlight(bufnr, line, col_start)
  vim.api.nvim_buf_add_highlight(bufnr, M.hovered_hl_ns, 'OutlineCurrent', line, col_start, -1)
end

function M.setup_highlights()
  -- Setup the OutlineCurrent highlight group if it hasn't been done already by
  -- a theme or manually set
  if vim.fn.hlexists('OutlineCurrent') == 0 then
    -- TODO: Use nvim_get_hl
    local cline_hl = vim.api.nvim_get_hl_by_name('CursorLine', true)
    local string_hl = vim.api.nvim_get_hl_by_name('String', true)

    vim.api.nvim_set_hl(
      0,
      'OutlineCurrent',
      { bg = cline_hl.background, fg = string_hl.foreground }
    )
  end

  -- Some colorschemes do some funky things with the comment highlight, most
  -- notably making them italic, which messes up the outline connector. Fix
  -- this by copying the foreground color from the comment hl into a new
  -- highlight.
  local comment_fg_gui = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID('Comment')), 'fg', 'gui')

  if vim.fn.hlexists('OutlineGuides') == 0 then
    vim.cmd(string.format('hi OutlineGuides guifg=%s', comment_fg_gui))
  end
end

return M
