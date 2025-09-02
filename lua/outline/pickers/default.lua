local Util = require('outline.pickers.utils')

return function(opts, contents)
  vim.ui.select(contents, { prompt = 'Filter Symbols> ' }, function(choice)
    if not choice then
      return
    end
    local filters = {}
    if choice ~= Util.all_kind then
      table.insert(filters, Util.strip_whitespace(choice))
    end
    opts.set_filters(filters)
  end)
end
