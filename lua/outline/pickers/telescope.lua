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
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        local selected_items = {}

        if selections and #selections > 0 then
          -- multiselection was used to select multiple items, add each to selectionlist
          for _, entry in ipairs(selections) do
            selected_items[#selected_items+1] = entry[1]
          end
        else
          -- if single selection mode was used default to the current entry
          local selection = action_state.get_selected_entry()
          if selection then
            selected_items[1] = selection[1]
          end
        end

        if on_select then on_select(selected_items) end
        actions.close(prompt_bufnr)
      end)
      return true
    end,
  }):find()
end

return M
