local cfg = require('outline.config')
local outline = require('outline')

local M = {}

local function get_hover_params(node, winnr)
  local bufnr = vim.api.nvim_win_get_buf(winnr)
  local fn = vim.uri_from_bufnr(bufnr)

  return {
    textDocument = { uri = fn },
    position = { line = node.line, character = node.character },
    bufnr = bufnr,
  }
end

function M.show_hover()
  local current_line = vim.api.nvim_win_get_cursor(outline.current.view.win)[1]
  local node = outline.current.flats[current_line]

  local hover_params = get_hover_params(node, outline.current.code.win)

  vim.lsp.buf_request(
    hover_params.bufnr,
    'textDocument/hover',
    hover_params,
    function(_, result, _, config)
      if not (result and result.contents) then
        return
      end
      local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        return
      end
      local bufnr, winnr = vim.lsp.util.open_floating_preview(markdown_lines, 'markdown', config)
      vim.api.nvim_win_set_option(winnr, 'winhighlight', cfg.o.preview_window.winhl)
    end
  )
end

return M
