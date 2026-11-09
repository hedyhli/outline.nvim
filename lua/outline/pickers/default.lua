local M = {}

function M.pick_item(opts)
  local items = opts.items or {}
  local title = opts.title or "Select Item"
  local on_select = opts.on_select

  -- Use UI select as default as it has no dependencies and still looks cool if it was for example
  -- overwritten by dressing.nvim or telescopes ui-select etc.
  vim.ui.select(items, { prompt = title }, function(choice)
    if choice and on_select then
      on_select(choice)
    end
  end)
end

return M
