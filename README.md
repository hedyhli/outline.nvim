<!-- panvimdoc-ignore-start -->

# Fork status

This is a fork of the original symbols-outline.nvim which fixed a lot of bugs
from the original repo, and also added many more features.

You can see all the changes from the original plugin before v1.0.0 in [#12 on
github](https://github.com/hedyhli/outline.nvim/issues/12).

It started out as a personal fork which I maintain for my personal use-cases,
soon more and more features found their way in and I started introducing
significant changes.

However, due to simrat's status with the original plugin, I eventually decided
to rename and detach the fork, starting to work on this as a new plugin.

## Migrating from symbols-outline.nvim

If you have existing setup opts for symbols-outline.nvim, you can convert it to
be usable for outline.nvim using this script: [scripts/convert-symbols-outline-opts.lua](scripts/convert-symbols-outline-opts.lua).


---

# outline.nvim

**A sidebar with a tree-like outline of symbols from your code, powered by LSP.**


![demo](https://github.com/simrat39/rust-tools-demos/raw/master/symbols-demo.gif)

Table of contents

<!-- mtoc-start -->

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Setup](#setup)
* [Configuration](#configuration)
  * [Terminology](#terminology)
  * [Default options](#default-options)
  * [Symbols table](#symbols-table)
* [Commands](#commands)
* [Default keymaps](#default-keymaps)
* [Highlights](#highlights)
  * [Outline window](#outline-window)
  * [Preview window](#preview-window)
  * [Other highlight groups](#other-highlight-groups)
* [Lua API](#lua-api)
* [Tips](#tips)
* [Recipes](#recipes)
  * [Unfold others](#unfold-others)
  * [Auto-jump](#auto-jump)
  * [Symbol details](#symbol-details)
  * [Line numbers](#line-numbers)
  * [Blend cursor with cursorline](#blend-cursor-with-cursorline)
  * [Custom icons](#custom-icons)
  * [Disable icons](#disable-icons)
* [TODO](#todo)
* [Limitations](#limitations)
  * [Preview window](#preview-window-1)
  * [Many outlines](#many-outlines)
* [Related plugins](#related-plugins)

<!-- mtoc-end -->
<!-- panvimdoc-ignore-end -->

## Prerequisites

- Neovim 0.7+
- Properly configured Neovim LSP client

## Installation

- GitHub repo: `"hedyhli/outline.nvim"`
- Or SourceHut repo: `url = "https://git.sr.ht/~hedy/outline.nvim"` (an
  equivalent key to `url` for your plugin manager)

Lazy.nvim example:
```lua
{
  "hedyhli/outline.nvim",
  config = function()
    -- Example mapping to toggle outline
    vim.keymap.set("n", "<leader>tt", "<cmd>Outline<CR>",
      { desc = "Toggle Outline" })

    require("outline").setup {
      -- Your setup opts here (leave empty to use defaults)
    }
  end,
},
```

Lazy.nvim with lazy-loading example:
```lua
{
  "hedyhli/outline.nvim",
  lazy = true,
  cmd = { "Outline", "OutlineOpen" },
  keys = { -- Example mapping to toggle outline
    { "<leader>tt", "<cmd>Outline<CR>", desc = "Toggle outline" },
  },
  opts = {
    -- Your setup opts here
  },
},
```

This allows Lazy.nvim to lazy-load the plugin on commands `Outline`,
`OutlineOpen`, and your keybindings.


## Setup

Call the setup function with your configuration options.

Note that a call to `.setup()` is **required** for this plugin to work
(otherwise you might see this error: simrat39/symbols-outline.nvim#213).

```lua
require("outline").setup({})
```

[Skip to commands](#commands)

## Configuration

The configuration structure has been heavily improved and refactored in this
plugin. If you're migrating from the original symbols-outline, see [#12 on
github](https://github.com/hedyhli/outline.nvim/issues/12) under "breaking
changes" section.

### Terminology

Check this list if you have any confusion with the terms used in the
configuration.

- **Provider**: Source of the items in the outline view. Could be LSP, CoC, etc.
- **Node**: An item in the outline view
- **Fold**: Collapse a collapsible node
- **Location**: Where in the source file a node is from
- **Preview**: Show the location of a node in code using a floating window.
  Syntax highlighting is provided if treesitter is installed.
- **Jump/Peek**: Go to corresponding location in code without leaving outline window
- **Hover**: Cursor currently on the line of a node
- **Hover symbol**: Displaying a floating window to show symbol information
  provided by provider.
- **Focus**: Which window the cursor is in

[Skip to commands](#commands)

### Default options

Pass a table to the setup call with your configuration options.

<details><summary>Show defaults</summary>

```lua
{
  outline_window = {
    -- Where to open the split window: right/left
    position = 'right',
    -- The default split commands used are 'topleft vs' and 'botright vs'
    -- depending on `position`. You can change this by providing your own
    -- `split_command`.
    -- `position` will not be considered if `split_command` is non-nil.
    -- This should be a valid vim command used for opening the split for the
    -- outline window. Eg, 'rightbelow vsplit'.
    split_command = nil,

    -- Percentage or integer of columns
    width = 25, 
    -- Whether width is relative to the total width of nvim
    -- When relative_width = true, this means take 25% of the total
    -- screen width for outline window.
    relative_width = true,

    -- Auto close the outline window if goto_location is triggered and not for
    -- peek_location
    auto_close = false,
    -- Automatically scroll to the location in code when navigating outline window.
    auto_jump = false,
    -- boolean or integer for milliseconds duration to apply a temporary highlight
    -- when jumping. false to disable.
    jump_highlight_duration = 300,
    -- Whether to center the cursor line vertically in the screen when
    -- jumping/focusing. Executes zz.
    center_on_jump = true,

    -- Vim options for the outline window
    show_numbers = false,
    show_relative_numbers = false,
    wrap = false,

    -- true/false/'focus_in_outline'/'focus_in_code'.
    -- The last two means only show cursorline when the focus is in outline/code.
    -- 'focus_in_outline' can be used if the outline_items.auto_set_cursor
    -- operations are too distracting due to visual contrast caused by cursorline.
    show_cursorline = true,
    -- Enable this only if you enabled cursorline so your cursor color can
    -- blend with the cursorline, in effect, as if your cursor is hidden
    -- in the outline window.
    -- This makes your line of cursor have the same color as if the cursor
    -- wasn't focused on the outline window.
    -- This feature is experimental.
    hide_cursor = false,

    -- Whether to auto-focus on the outline window when it is opened.
    -- Set to false to *always* retain focus on your previous buffer when opening
    -- outline.
    -- If you enable this you can still use bangs in :Outline! or :OutlineOpen! to
    -- retain focus on your code. If this is false, retaining focus will be
    -- enforced for :Outline/:OutlineOpen and you will not be able to have the
    -- other behaviour.
    focus_on_open = true,
    -- Winhighlight option for outline window.
    -- See :help 'winhl'
    -- To change background color to "CustomHl" for example, append "Normal:CustomHl".
    -- Note that if you're adding highlight changes, you should append to this
    -- default value, otherwise details/lineno will not have highlights.
    winhl = "OutlineDetails:Comment,OutlineLineno:LineNr",
  },

  outline_items = {
    -- Show extra details with the symbols (lsp dependent) as virtual next
    show_symbol_details = true,
    -- Show corresponding line numbers of each symbol on the left column as
    -- virtual text, for quick navigation when not focused on outline.
    -- Why? See this comment:
    -- https://github.com/simrat39/symbols-outline.nvim/issues/212#issuecomment-1793503563
    show_symbol_lineno = false,
    -- Whether to highlight the currently hovered symbol and all direct parents
    highlight_hovered_item = true,
    -- Whether to automatically set cursor location in outline to match
    -- location in code when focus is in code. If disabled you can use
    -- `:OutlineFollow[!]` from any window or `<C-g>` from outline window to
    -- trigger this manually.
    auto_set_cursor = true,
    -- Autocmd events to automatically trigger these operations.
    auto_update_events = {
      -- Includes both setting of cursor and highlighting of hovered item.
      -- The above two options are respected.
      -- This can be triggered manually through `follow_cursor` lua API,
      -- :OutlineFollow command, or <C-g>.
      follow = { 'CursorMoved' },
      -- Re-request symbols from the provider.
      -- This can be triggered manually through `refresh_outline` lua API, or
      -- :OutlineRefresh command.
      items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TabEnter', 'BufWritePost' },
    },
  },

  -- Options for outline guides which help show tree hierarchy of symbols
  guides = {
    enabled = true,
    markers = {
      -- It is recommended for bottom and middle markers to use the same number
      -- of characters to align all child nodes vertically.
      bottom = '└',
      middle = '├',
      vertical = '│',
    },
  },

  symbol_folding = {
    -- Depth past which nodes will be folded by default
    autofold_depth = nil,
    -- Automatically unfold currently hovered symbol
    auto_unfold_hover = true,
    markers = { '', '' },
  },

  preview_window = {
    -- Automatically open preview of code location when navigating outline window
    auto_preview = false,
    -- Automatically open hover_symbol when opening preview (see keymaps for
    -- hover_symbol).
    -- If you disable this you can still open hover_symbol using your keymap
    -- below.
    open_hover_on_preview = false,
    width = 50,     -- Percentage or integer of columns
    min_width = 50, -- This is the number of columns
    -- Whether width is relative to the total width of nvim.
    -- When relative_width = true, this means take 50% of the total
    -- screen width for preview window, ensure the result width is at least 50
    -- characters wide.
    relative_width = true,
    -- Border option for floating preview window.
    -- Options include: single/double/rounded/solid/shadow or an array of border
    -- characters.
    -- See :help nvim_open_win() and search for "border" option.
    border = 'single',
    -- winhl options for the preview window, see ':h winhl'
    winhl = '',
    -- Pseudo-transparency of the preview window, see ':h winblend'
    winblend = 0
  },

  -- These keymaps can be a string or a table for multiple keys.
  -- Set to `{}` to disable. (Using 'nil' will fallback to default keys)
  keymaps = { 
    show_help = '?',
    close = {'<Esc>', 'q'},
    -- Jump to symbol under cursor.
    -- It can auto close the outline window when triggered, see
    -- 'auto_close' option above.
    goto_location = '<Cr>',
    -- Jump to symbol under cursor but keep focus on outline window.
    peek_location = 'o',
    -- Visit location in code and close outline immediately
    goto_and_close = '<S-Cr>',
    -- Change cursor position of outline window to match current location in code.
    -- 'Opposite' of goto/peek_location.
    restore_location = '<C-g>',
    -- Open LSP/provider-dependent symbol hover information
    hover_symbol = '<C-space>',
    -- Preview location code of the symbol under cursor
    toggle_preview = 'K',
    rename_symbol = 'r',
    code_actions = 'a',
    -- These fold actions are collapsing tree nodes, not code folding
    fold = 'h',
    unfold = 'l',
    fold_toggle = '<Tab>',
    -- Toggle folds for all nodes.
    -- If at least one node is folded, this action will fold all nodes.
    -- If all nodes are folded, this action will unfold all nodes.
    fold_toggle_all = '<S-Tab>',
    fold_all = 'W',
    unfold_all = 'E',
    fold_reset = 'R',
    -- Move down/up by one line and peek_location immediately.
    -- You can also use outline_window.auto_jump=true to do this for any
    -- j/k/<down>/<up>.
    down_and_jump = '<C-j>',
    up_and_jump = '<C-k>',
  },

  providers = {
    priority = { 'lsp', 'coc', 'markdown' },
    lsp = {
      -- Lsp client names to ignore
      blacklist_clients = {},
    },
  },

  symbols = {
    -- Filter by kinds (string) for symbols in the outline.
    -- Possible kinds are the Keys in the icons table below.
    -- A filter list is a string[] with an optional exclude (boolean) field.
    -- The symbols.filter option takes either a filter list or ft:filterList
    -- key-value pairs.
    -- Put  exclude=true  in the string list to filter by excluding the list of
    -- kinds instead.
    -- Include all except String and Constant:
    --   filter = { 'String', 'Constant', exclude = true }
    -- Only include Package, Module, and Function:
    --   filter = { 'Package', 'Module', 'Function' }
    -- See more examples below.
    filter = nil,

    -- You can use a custom function that returns the icon for each symbol kind.
    -- This function takes a kind (string) as parameter and should return an
    -- icon as string.
    icon_fetcher = nil,
    -- 3rd party source for fetching icons. Fallback if icon_fetcher returned
    -- empty string. Currently supported values: 'lspkind'
    icon_source = nil,
    -- The next fallback if both icon_fetcher and icon_source has failed, is
    -- the custom mapping of icons specified below. The icons table is also
    -- needed for specifying hl group.
    icons = {
      File = { icon = '󰈔', hl = '@text.uri' },
      Module = { icon = '󰆧', hl = '@namespace' },
      Namespace = { icon = '󰅪', hl = '@namespace' },
      Package = { icon = '󰏗', hl = '@namespace' },
      Class = { icon = '𝓒', hl = '@type' },
      Method = { icon = 'ƒ', hl = '@method' },
      Property = { icon = '', hl = '@method' },
      Field = { icon = '󰆨', hl = '@field' },
      Constructor = { icon = '', hl = '@constructor' },
      Enum = { icon = 'ℰ', hl = '@type' },
      Interface = { icon = '󰜰', hl = '@type' },
      Function = { icon = '', hl = '@function' },
      Variable = { icon = '', hl = '@constant' },
      Constant = { icon = '', hl = '@constant' },
      String = { icon = '𝓐', hl = '@string' },
      Number = { icon = '#', hl = '@number' },
      Boolean = { icon = '⊨', hl = '@boolean' },
      Array = { icon = '󰅪', hl = '@constant' },
      Object = { icon = '⦿', hl = '@type' },
      Key = { icon = '🔐', hl = '@type' },
      Null = { icon = 'NULL', hl = '@type' },
      EnumMember = { icon = '', hl = '@field' },
      Struct = { icon = '𝓢', hl = '@type' },
      Event = { icon = '🗲', hl = '@type' },
      Operator = { icon = '+', hl = '@operator' },
      TypeParameter = { icon = '𝙏', hl = '@parameter' },
      Component = { icon = '󰅴', hl = '@function' },
      Fragment = { icon = '󰅴', hl = '@constant' },
      TypeAlias =  { icon = ' ', hl = '@type' },
      Parameter = { icon = ' ', hl = '@parameter' },
      StaticMethod = { icon = ' ', hl = '@function' },
      Macro = { icon = ' ', hl = '@macro' },
    },
  },
}
```

</details>

To find out exactly what some of the options do, please see the
[recipes](#recipes) section at the bottom for screen-recordings/shots.

### Symbols table

**filter**

Include all symbols except kinds String and Variable:
```lua
symbols.filter = { 'String', 'Variable', exclude=true }
```

Include only Function symbols:
```lua
symbols.filter = { 'Function' }
```

Per-filetype filtering example:
- For python, only include function and class
- For other file types, include all but string
```lua
symbols.filter = {
  default = { 'String', exclude=true },
  python = { 'Function', 'Class' },
}
```

Note how the python filter list and the default filter list is NOT merged.

Setting any filter list to `nil` or `false` means include all symbols, where a
filter list is an array of strings with an optional `exclude` field.


**icons**

The order in which the sources for icons are checked is:

1. Icon fetcher function
2. Icon source (only `lspkind` is supported for this option as of now)
3. Icons table

A fallback is always used if the previous candidate returned a falsey value.

## Commands

- **:Outline[!]** (✓ bang ✓ mods)

  Toggle outline. With bang (`!`) the cursor focus stays in your
  original window after opening the outline window. Set `focus_on_open = true` to
  always use this behaviour.

  You can use command modifiers `topleft`/`aboveleft`/`botright`/`belowright`
  on this command to control how the outline window split is created. Other
  modifiers are ignored.

  Example:
```vim
" in config: position='right'
:topleft Outline     " opens with 'topleft vsplit'
:belowright Outline  " opens with 'belowright vsplit'
:Outline             " opens with 'botright vsplit'
```

- **:OutlineOpen[!]** (✓ bang ✓ mods)

  Open outline. With bang (`!`) the cursor focus stays in your original
  window after opening the outline window. Set `focus_on_open = true` to always
  use this behaviour.

  You can use command modifiers `topleft`/`aboveleft`/`botright`/`belowright`
  on this command to control how the outline window split is created. Other
  modifiers are ignored.

```vim
" in config: position='left'
:aboveleft OutlineOpen   " opens with 'aboveleft vsplit'
:belowright OutlineOpen  " opens with 'belowright vsplit'
:OutlineOpen             " opens with 'topleft vsplit'
```

- **:OutlineClose**: Close outline

- **:OutlineFocus**: Toggle focus between outline and code/source window

- **:OutlineFocusOutline**: Focus on outline

- **:OutlineFocusCode**: Focus on source window

- **:OutlineStatus**: Display provider and outline window status in a floating window, similar to `:LspInfo`

- **:OutlineFollow[!]** (✓ bang × mods)

  Go to corresponding node in outline based on cursor position in code, and
  focus on the outline window.

  With bang (`!`), retain focus on the code window.

  This can be understood as the converse of `goto_location` (see keymaps).
  `goto_location` sets cursor of code window to the position of outline window,
  whereas this command sets position in outline window to the cursor position of
  code window.

  With bang, it can be understood as the converse of `peek_location`.

  This is automatically triggered on events
  `outline_items.auto_update_events.follow`.

  You can also trigger this manually using the `restore_location` keymap
  (default `<C-g>`) from the outline window.

- **:OutlineRefresh**

  Trigger refresh of symbols from provider and update outline items.

  This is automatically triggered on events
  `outline_items.auto_update_events.refresh`.


## Default keymaps

These mappings are active only for the outline window.

You can open a floating window showing the following list of keymaps using the `?`
key by default from the outline window.

| Key        | Action                                             |
| ---------- | -------------------------------------------------- |
| Esc / q    | Close outline                                      |
| Enter      | Go to symbol location in code                      |
| o          | Go to symbol location in code without losing focus |
| Shift+Enter| Go to symbol location in code and close outline    |
| Ctrl+g     | Update outline window to focus on code location    |
| K          | Toggles the current symbol preview                 |
| Ctrl+Space | Hover current symbol (provider action)             |
| r          | Rename symbol                                      |
| a          | Code actions                                       |
| h          | Fold symbol or parent symbol                       |
| Tab        | Toggle fold under cursor                           |
| Shift+Tab  | Toggle all folds                                   |
| l          | Unfold symbol                                      |
| W          | Fold all symbols                                   |
| E          | Unfold all symbols                                 |
| R          | Reset all folding                                  |
| Ctrl+k     | Go up and peek location                            |
| Ctrl+j     | Go down and peek location                          |
| ?          | Show current keymaps in a floating window          |

## Highlights

### Outline window

Default:

```lua
outline_window = {
  winhl = "OutlineDetails:Comment,OutlineLineno:LineNr",
},
```

Possible highlight groups for the outline window:

| Highlight            | Description                                          |
| -------------------- | ---------------------------------------------------- |
| OutlineCurrent       | Current symbol under cursor                          |
| OutlineGuides        | Guide markers section in each line of the outline    |
| OutlineFoldMarker    | Fold markers in the outline                          |
| OutlineDetails       | Symbol details in virtual text                       |
| OutlineLineno        | The Lineno column virtual text                       |

You can customize any other highlight groups using `winhl` too, this option is
passed directly to the `winhl` vim option unprocessed.

To customize colors of the symbol icons, use the `symbols.icons` table. See
[config](#configuration).

### Preview window

```lua
preview_window = {
  winhl = "",
},
```

### Other highlight groups

| Highlight            | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| OutlineJumpHighlight | Used for indicating cursor position when jumping/focusing  |

You can also use `outline_window.jump_highlight_duration` to customize in milliseconds,
how long the highlight is applied for.

## Lua API

Outline.nvim provides the following public API for use in lua.

```lua
require'outline'
```
- setup(opts)

- **toggle_outline(opts)**

  Toggle opening/closing of outline window.

  If `opts.focus_outline=false`, keep focus on previous window.

- **open_outline(opts)**

  Open the outline window.

  If `opts.focus_outline=false`, keep focus on previous window.

- **close_outline()**

  Close the outline window.

- **focus_toggle()**

  Toggle cursor focus between code and outline window.

- **focus_outline()**

  Focus cursor on the outline window.

- **focus_code()**

  Focus cursor on the window which the outline is derived from.

- **is_open()**

  Return whether the outline window is open.

- **show_status()**

  Display provider and outline window status in a floating window.

- **has_provider()**

  Returns whether a provider is available for current window.

- **follow_cursor(opts)**

  Go to corresponding node in outline based on cursor position in code, and
  focus on the outline window.

  With `opts.focus_outline=false`, cursor focus will remain on code window.

  This is automatically called on events
  `outline_items.auto_update_events.follow` from config.

- **is_focus_in_outline()**

  Return whether outline is open and current focus is in outline.

- **refresh_outline()**

  Re-request symbols from provider and update outline items.

  This is automatically called on events
  `outline_items.auto_update_events.refresh` from config.


## Tips

- To open the outline but don't focus on it, you can use `:Outline!` or
`:OutlineOpen!`.

  This is useful in autocmds, say you have a filetype that, whenever a buffer with
  that filetype is opened you want to open the outline.

- After navigating around in the outline window, you can use `<C-g>` (default
  mapping for `restore_location`) to go back to the corresponding outline
  location based on the code location.

- To customize the background colors, text colors, and borders, you can use
  `outline_window.winhl` for the outline window or `preview_window.winhl` for the
  preview floating window. See [highlights](#highlights).

- To fix symbol icon related issues, there are several options. If you use
  `lspkind`, you can set `symbols.icon_source = 'lspkind'` to use lspkind for
  fetching icons. You can also use your own function `symbols.icon_fetcher` that
  takes a string and should return an icon. Otherwise, you can edit the
  `symbols.icons` table for specifying icons.

  The order in which the sources of icons are checked is:

  1. Icon fetcher function
  2. Icon source
  3. Icons table

  A fallback is always used if the previous candidate returned falsey value.

  You can hide an icon for a specific type by returning `""`.

  Below is an example where icons are disabled for kind 'Package', and for other
  icons use lspkind.

```lua
symbols = {
  icon_fetcher = function(k)
    if k == 'Package' then
      return ""
    end
    return false
  end,
  icon_source = 'lspkind',
}
```

- You can customize the split command used for creating the outline window split
  using `outline_window.split_command`, such as `"topleft vsp"`. See `:h windows`

- Is the outline window too slow when first opening a file? This is usually due
  to the LSP not being ready when you open outline, hence we have to wait for the
  LSP response before the outline can be shown. If LSP is ready generally the
  outline latency is almost negligible.

## Recipes

Behaviour you may want to achieve and the combination of configuration options
to achieve it.

Code snippets in this section are to be placed in `.setup({ <HERE> })` directly
unless specified otherwise.

### Unfold others

Unfold all others except currently hovered item

```lua
symbol_folding = {
  autofold_depth = 1,
  auto_unfold_hover = true,
},
```
<div align=center><img width="900" alt="outline window showing auto fold depth" src="https://github.com/hedyhli/outline.nvim/assets/50042066/2e0c5f91-a979-4e64-a100-256ad062dce3"></div>


### Auto-jump

Use outline window as a quick-jump window

```lua
preview_window = {
  auto_preview = true,
},
```

https://github.com/hedyhli/outline.nvim/assets/50042066/a473d791-d1b9-48e9-917f-b816b564a645

Alternatively, if you want to automatically navigate to the corresponding code
location directly and not use the preview window:

```lua
outline_window = {
  auto_jump = true,
},
```

This feature was added by @stickperson in an upstream PR 🙌

https://github.com/hedyhli/outline.nvim/assets/50042066/3d06e342-97ac-400c-8598-97a9235de66c

Or, you can use keys `<C-j>` and `<C-k>` to achieve the same effect, whilst not
having `auto_jump` on by default.

### Symbol details

Hide the extra details after each symbol name

```lua
outline_items = {
  show_symbol_details = false,
},
```

You can customize its highlight group by setting `OutlineDetails` in
`outline_window.winhl`.

### Line numbers

Show line numbers next to each symbol to jump to that symbol quickly

```lua
outline_items = {
  show_symbol_lineno = true,
},
```

The default highlight group for the line numbers is `LineNr`, you can customize
it using `outline_window.winhl`: please see [highlights](#outline-window).

<div align=center><img width="900" alt="outline window showing lineno" src="https://github.com/hedyhli/outline.nvim/assets/50042066/2bbb5833-f40b-4c53-8338-407252d61443"></div>


### Blend cursor with cursorline

'Single' cursorline

```lua
outline_window = {
  show_cursorline = true,
  hide_cursor = true,
}
```

This will be how the outline window looks like when focused:

<div align=center><img width="500" alt="outline window showing another example of hide_cursor" src="https://github.com/hedyhli/outline.nvim/assets/50042066/527c567b-a777-4518-a9da-51d8bcb445e7"></div>

Some may find this unhelpful, but one may argue that elements in each row of the
outline becomes more readable this way, hence this is an option.

This feature is newly added in this fork, and is currently experimental (may be
unstable).

### Custom icons

You can write your own function for fetching icons. Here is one such example
that simply returns in plain text, the first letter of the given kind.

```lua
symbols = {
  icon_fetcher = function(kind) return kind:sub(1,1) end
}
```

The fetcher function, if provided, is checked first before using `icon_source`
and `icons` as fallback.

<div align=center><img width="500" alt="outline with plain text icons" src="https://github.com/hedyhli/outline.nvim/assets/50042066/655b534b-da16-41a7-926e-f14475376a04"></div>

### Disable icons

Disable all icons:

```lua
symbols = {
  icon_fetcher = function(_) return "" end,
}
```

Disable icons for specific kinds, and for others use lspkind:

```lua
symbols = {
  icon_fetcher = function(k)
    if k == 'String' then
      return ""
    end
    return false
  end,
  icon_source = 'lspkind',
}
```

<div align=center><img width="500" alt="outline with disabled icon for String" src="https://github.com/hedyhli/outline.nvim/assets/50042066/26d258c6-9530-43d4-b88b-963304e3bf2d"></div>

<!-- panvimdoc-ignore-start -->

---
Any other recipes you think others may also find useful? Feel free to open a PR.


## TODO

Key:
```
-     : Idea
- [ ] : Planned
- [/] : WIP
- ❌  : Was idea, found usable workaround
- ✅  : Implemented
```

- Folds
  - `[ ]` Org-like <kbd>shift+tab</kbd> behavior: Open folds level-by-level
  - `[ ]` Optionally not opening all child nodes when opening parent node
  - Fold siblings and siblings of parent on startup

- Navigation
  - ❌ Go to parent (as of now you can press `hl` to achieve the same
    effect)
  - ❌ Cycle siblings (as of now when reached the last sibling, you can use `hlj`
    to go back to first sibling)

- `[ ]` simrat39/symbols-outline.nvim#75: Handling of the outline window when attached
  buffer is closed.

  Maybe it should continue working, so that pressing enter can open a split to
  the correct location like `NvimTree` does, and pressing `q` can properly
  close the buffer.

<!-- panvimdoc-ignore-end -->

## Limitations

### Preview window

Sometimes the preview window could be slow in loading. This could be due to the
code buffer being large. As of now there are no good solutions in circumventing
this problem — currently the entire code buffer is read, and then put into the
preview buffer. If only the required portion to preview is read and set
instead, there would be highlighting issues (say the calculated starting line
was within a markdown code block, so what was previously not supposed to be
code is now highlighted as code).

### Many outlines

Outline.nvim does not support having multiple outlines attached to different
buffers as of now. However, this feature is
[planned](https://github.com/hedyhli/outline.nvim/issues/26), and for now you
can use a single outline sidebar and have it auto-update whenever you switch
buffers.

## Related plugins

- Aerial.nvim
- nvim-navic
- nvim-navbuddy
- dropdown.nvim
- treesitter (inspect/edit)
- lspsaga
- navigator.lua
