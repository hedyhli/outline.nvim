local M = {}

function M.pick_item(opts)
  local items = opts.items or {}
  local title = opts.title or "Select Item"
  local on_select = opts.on_select
  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local sorter = require('telescope.config').values.generic_sorter({})

  pickers.new({}, {
    prompt_title = title,
    finder = finders.new_table { results = items },
    sorter = sorter,
    attach_mappings = function(_, _)
      actions.select_default:replace(function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and on_select then
          on_select(selection[1])
        end
        actions.close(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

return M
