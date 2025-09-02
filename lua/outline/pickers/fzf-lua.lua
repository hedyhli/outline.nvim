local Util = require('outline.pickers.utils')
local fzf = require('fzf-lua')

local function format_title(str, icon, icon_hl)
  return {
    { ' ', 'FzfLuaTitle' },
    { (icon and icon .. ' ' or ''), icon_hl or 'FzfLuaTitle' },
    { str, 'FzfLuaTitle' },
    { ' ', 'FzfLuaTitle' },
  }
end

local function get_width_and_height(contents)
  local max_height = 30
  local max_width = 50

  local height = #contents + 1
  local width = 1

  for _, ctx in pairs(contents) do
    if width < #ctx then
      width = #ctx
    end
  end

  local win_height = max_height < height and max_height or height
  local win_width = max_width > width and max_width or width

  return {
    win_height = win_height,
    win_width = win_width,
    width_str = width,
  }
end

return function(opts, contents)
  local win_opts = get_width_and_height(contents)

  local entry_str = {}
  for _, symbol in pairs(contents) do
    if symbol ~= Util.all_kind then
      local kind = opts.o.symbols.icons
      if kind[symbol] then
        local get_icon = Util.pad_string(kind[symbol].icon, 5)
        local icon_hl = fzf.utils.ansi_from_hl(kind[symbol].hl, get_icon)
        entry_str[#entry_str + 1] = string.format('%s %s', icon_hl, Util.strip_whitespace(symbol))
      end
    else
      entry_str[#entry_str + 1] = symbol
    end
  end

  fzf.fzf_exec(entry_str, {
    ---@diagnostic disable: missing-fields
    ---@type fzf-lua.config.Winopts
    winopts = {
      title = format_title('Filter Symbols', ' '),
      width = win_opts.win_width,
      height = win_opts.win_height,
      col = 0.50,
      row = 0.50,
    },
    actions = {
      ['default'] = function(selected, _)
        if not selected then
          return
        end

        local filters = {}

        if #selected == 1 then
          local sel = selected[1]
          if sel ~= Util.all_kind then
            local str_e = fzf.utils.strip_ansi_coloring(sel)
            local mtch_str = str_e:match('[a-zA-Z].*$')
            if mtch_str then
              table.insert(filters, mtch_str)
            end
          end
        else
          for _, sel in ipairs(selected) do
            local str_e = fzf.utils.strip_ansi_coloring(sel)
            local mtch_str = str_e:match('[a-zA-Z].*$')
            if mtch_str then
              table.insert(filters, mtch_str)
            end
          end
        end

        opts.set_filters(filters)
      end,
    },
  })
end
