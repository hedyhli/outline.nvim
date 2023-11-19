-- https://github.com/hedyhli/markdown-toc.nvim
--
-- outline.nvim README uses markdown-toc to auto-update the ToC.
-- The following config makes only second level headings be included.

local ok, mtoc = pcall(require, 'mtoc')
if ok then
  mtoc.update_config({
    headings = {
      pattern = '^(##)%s+(.+)$',
    }
  })
end

