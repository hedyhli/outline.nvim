local cfg = require('outline.config')
local outline = require('outline')
local util = vim.lsp.util

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

-- handler yoinked from the default implementation
function M.show_hover()
  local current_line = vim.api.nvim_win_get_cursor(outline.current.view.winnr)[1]
  local node = outline.current.flats[current_line]

  local hover_params = get_hover_params(node, outline.current.code.win)

  vim.lsp.buf_request(
    hover_params.bufnr,
    'textDocument/hover',
    hover_params,
    ---@diagnostic disable-next-line: param-type-mismatch
    function(_, result, _, config)
      if not (result and result.contents) then
        return
      end
      local markdown_lines = util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        return
      end
      -- FIXME
      local bufnr, winnr = util.open_floating_preview(markdown_lines, 'markdown', config)
      vim.api.nvim_win_set_option(winnr, 'winhighlight', cfg.o.preview_window.winhl)
    end
  )
end

return M
