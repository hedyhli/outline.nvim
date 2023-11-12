<!-- panvimdoc-ignore-start -->

# Fork status

[Skip to plugin readme](#symbols-outlinenvim)

This is a fork of the original symbols-outline.nvim which fixes a lot of bugs
from the original repo.

It also adds many more features listed [below](#features).

It does not attempt to be an up-to-date successor of the original repo, nor does
it attempt to ensure everyone's use-cases are satisfied by providing an overall
better experience. For now, it is a fork which I maintain for my personal
use-cases that incorporates a significant number of existing [PRs](#prs) and [fixes](#fixes)
many previously reported issues.

## Maintenance status

This fork is NOT guaranteed to be completely bug-free, nor as stable as the
original (aside from the already broken things in the original repo). However,
since I use this plugin myself, it is guaranteed that selected issues that I
encounter myself would be fixed (to the best of my
ability).

I do not merge PRs from the original repo that I don't personally need.

- **DO use this fork if**:
  - You want to use the bugfixes included in this fork, including `auto_preview`,
    and others listed in [fixes](#fixes)
  - You want to use [features](#features) available in this fork, which are not
    included upstream
  - You are OK with some things not being looked after well such as CoC support
    (things I don't personally use)

- **Do NOT use this fork if**:
  - You do not need the bugfixes in this fork
  - You want a stable plugin (aside from the existing bugs in original repo)
  - You don't need the extra features in this fork

## Fixes

- Extra padding/indent on left on outline window removed. Fixed issues:
  - simrat39/symbols-outline.nvim#165
  - simrat39/symbols-outline.nvim#178
  - simrat39/symbols-outline.nvim#209
- Symbol preview empty (simrat39/symbols-outline.nvim#176)
- `SymbolsOutlineClose` crashing when already closed: simrat39/symbols-outline.nvim#163
- Symbols not showing by supporting Nerd fonts v3.0: simrat39/symbols-outline.nvim#225
- Newlines in symbols crash: simrat39/symbols-outline.nvim#204 (simrat39/symbols-outline.nvim#184)
- `code_actions`: simrat39/symbols-outline.nvim#168 (simrat39/symbols-outline.nvim#123)
- Fold all operation too slow: simrat39/symbols-outline.nvim#223 (simrat39/symbols-outline.nvim#224)
- "Invalid buffer id" error simrat39/symbols-outline.nvim#177
- Open handler triggering multiple times ends up in messy state with errors
  simrat39/symbols-outline.nvim#235
- Fixed `_highlight_current_item` function checking provider on outline window
- Fixed behaviour of empty markdown headings `^(#+)(%s+)$` being listed in the
outline.

## 🛑 Breaking changes

This section may be relevant to you if your existing config uses the mentioned
features:

- **Config**: Configuration options have been significantly restructured to
provide better consistency and understandability. Please see the [default config](#configuration) for an example of the full list.
  - Options that control the looks
and behaviour of outline window is now moved to `outline_window` table;
  - Options that control the items that show up are now in `outline_items`
  - Options for the preview window is in `preview_window`.
  - Symbol icons are now in `symbols.icons`, symbol blacklists are in
  `symbols.blacklist`
  - Lsp blacklists are now in `providers.lsp.blacklist_clients`.
  - Fold options are now in `symbol_folding` with `fold_markers` being
  `symbol_folding.markers`, consistent to `guides.markers`.

  The reasoning for the above is simple. When you see 'border' under
  `preview_window` you can directly infer it controls the border for the preview
  window. Previously, for example, when you see `winblend` or `wrap`: is it for
  the outline window or the preview window? Furthermore, this change also aids
  extensibility to the configuration, and avoids cluttering the root setup opts
  namespace.

  If you disagree with this decision, you are always free to switch back to the
  original symbols-outline.nvim, or you could pin a commit in this fork if you
  still want to use the features and fixes from here.

- **Config**: `keymaps.focus_location` RENAMED to `keymaps.peek_location` to
  avoid confusion with focus window commands.

- **Config**: Marker icons used for guides can now be customized. `show_guides`
  REMOVED in favor of `guides.enabled`.

  You can set `guides = false` to disable guides altogether, or set `guides =
  true` to enable it but use default configuration for the guides. Otherwise,
  please use `guides.enabled` if your configuration for `guides` is a table.

- **Behaviour**: Removed hover floating window from `toggle_preview`.
  - Instead, you can set `open_hover_on_preview=true` (true by default) so that
    the `hover_symbol` action can be triggered when `toggle_preview`is
    triggered.
  - The preview window's size changed to half of neovim height (rather than a
    third). This is planned to be configurable.
  - The preview window is positioned to be vertically center-aligned (rather
    than fixed to the top). This is planned to be configurable.

- **Behaviour**: When `auto_close=true` only auto close if `goto_location` is
  used (where focus changed), and not for `focus_location`
  (simrat39/symbols-outline.nvim#119).

- **Behaviour**: For `auto_preview=true`, previously preview is only shown after
  some delay. Now preview is shown instantly every time the cursor moves.


## Features

[Skip to plugin readme](#symbols-outlinenvim)

Below is a list of features I've included in this fork which, at the time of
writing, has not been included upstream (in the original repo). I try my best to
keep this list up to date.

Features/Changes:

- Toggling folds (and added default keymaps for it)
(simrat39/symbols-outline.nvim#194).

- Control focus between outline and code window.
  - New commands: SymbolsOutline`Focus,FocusOutline,FocusCode` (see
  [commands](#commands))
  - Fixed issues:
    - simrat39/symbols-outline.nvim#143
    - simrat39/symbols-outline.nvim#174
    - simrat39/symbols-outline.nvim#207

- Show line number of each symbol in outline window (see [recipes](#recipes)
  for a screenshot)
  - Fixed issues:
    - simrat39/symbols-outline.nvim#212

- Cursorline option for the outline window.

- Added function and command to show provider and outline window status,
  somewhat like `:LspInfo`.

- Move down/up by one line and peek_location immediately, default bindings are
`<C-j>` and `<C-k>` just like Aerial.

- Flash highlight when using goto/peek location.

- Auto jump config option (see config `auto_goto`)
(simrat39/symbols-outline.nvim#229, simrat39/symbols-outline.nvim#228).

- New Follow command, opposite of `goto_location`/`focus_location`

- New restore location keymap option to go back to corresponding outline
  location synced with code (see config `restore_location`).

- Outline/Preview window border/background/winhighlight configuration.
  (simrat39/symbols-outline.nvim#136). See `outline_window.winhl`,
  `preview_window.winhl`, `preview_window.*width` options.

- All highlights used including the virtual text for symbol details and symbol
  lineno are now fully customizable using `outline_window.winhl`. See
  [highlights](#outline-window).

- Option to blend cursor with cursorline (`outline_window.hide_cursor`)

- Option to use lspkind for icons, and use your own fetcher function. See
[config](#configuration) and [tips](#tips)

- Option for outline window split command

Screen recordings/shots of some of the features is shown at the [bottom of the readme](#recipes).


## PRs

[Skip to plugin readme](#symbols-outlinenvim)

Key:
```
✅ = Either merged superseded
📮 = Planned for merge
```

- 📮 center view on goto symbol
  (#239 by skomposzczet)

- Distinguish between public and private function display in Elixir
  (#187 by scottming)

- Floating window (Draft)
  (#101 by druskus20)


<details><summary>Show completed PRs</summary>

- ✅ Open handler checks if view is not already open
  (#235 by eyalz800)

- ✅ auto_jump config param
  (#229 by stickperson)

  **Renamed to `auto_goto` for consistency**

- ✅ Update nerd fonts to 3.0
  (#225 by anstadnik)

- ✅ fix(folding): optimize fold/unfold all
  (#223 by wjdwndud0114)

- ✅ Support markdown setext-style headers
  (#222 by msr1k)

- ✅ fix(icons): replace obsolete icons
  (#219 by loichyan)

  **Superseded by #225**

- ✅ Support ccls symbols
  (#218 by rqdmap)

- ✅ fix: replace newlines with spaces in writer
  (#204 by tbung)

- ✅ Make close_outline idempotent
  (#200 by showermat)

  **Superseded by #163**

- ✅ Fix some options
  (#180 by cljoly)

- ✅ fix: Invalid buffer id error
  (#177 by snowair)

- ✅ fix(code_actions): use the builtin code_action
  (#168 by zjp-CN)

- ✅ fix: plugin crashes when SymbolOutlineClose used
  (#163 by beauwilliams)

- ✅ feat: Add window_bg_highlight to config
  (#137 by Zane-)

  **Improved implementation**

- ✅ Added preview width and relative size
  (#130 by Freyskeyd)

  **Improved upon and refactored with new config structure**

- ✅ Improve preview, hover windows configurability and looks
  (#128 by toppair)

  **Improved upon and refactored with new config structure**

- ✅ Do not close outline when focus_location occurs
  (#119 by M1Sports20)

- ✅ feat: instant_preview
  (#116 by axieax)

  **Superseded with an improved implementation**

- ✅ check if code_win is nill
  (#110 by i3Cheese)

  **Superseded before this fork was created**

  (perhaps the PR was forgotten to be closed)

</details>


## TODO

[Skip to plugin readme](#symbols-outlinenvim)

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
  the correct location, and pressing `q` can properly close the buffer.

- Preview / Hover
  - ✅ Configurable winhighlight options for preview window (like nvim-cmp)
  (simrat39/symbols-outline#128)
  - ✅ Configurable width and height of preview window (simrat39/symbols-outline.nvim#130)

- View
  - ✅ Outline window customizations (simrat39/symbols-outline.nvim#137)
  - ✅ Option to show line number next to symbols (simrat39/symbols-outline.nvim#212)
  - ✅ Option to hide cursor in outline window if cursorline enabled


## Related plugins

- nvim-navic
- nvim-navbuddy
- dropdown.nvim
- treesitter (inspect/edit)
- lspsaga
- navigator.lua

---


# symbols-outline.nvim

<!-- panvimdoc-ignore-end -->

**A tree like view for symbols in Neovim using the Language Server Protocol.
Supports all your favourite languages.**

![demo](https://github.com/simrat39/rust-tools-demos/raw/master/symbols-demo.gif)

<!-- panvimdoc-ignore-start -->
Table of contents

<!-- mtoc-start -->

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Setup](#setup)
* [Configuration](#configuration)
  * [Terminology](#terminology)
  * [Default options](#default-options)
* [Commands](#commands)
* [Default keymaps](#default-keymaps)
* [Highlights](#highlights)
  * [Outline window](#outline-window)
  * [Preview window](#preview-window)
* [Lua API](#lua-api)
* [Tips](#tips)
* [Recipes](#recipes)

<!-- mtoc-end -->
<!-- panvimdoc-ignore-end -->

## Prerequisites

- `neovim 0.7+`
- Properly configured Neovim LSP client

## Installation

Packer:
```lua
use 'hedyhli/symbols-outline.nvim'
```

Lazy:
```lua
{
  "hedyhli/symbols-outline.nvim",
  config = function()
    -- Example mapping to toggle outline
    vim.keymap.set("n", "<leader>tt", "<cmd>SymbolsOutline<CR>",
      { desc = "SymbolsOutline" })

    require("symbols-outline").setup {
      -- Your setup opts here (leave empty to use defaults)
    }
  end,
},
```

Lazy with lazy-loading:
```lua
{
  "hedyhli/symbols-outline.nvim",
  cmd = { "SymbolsOutline", "SymbolsOutlineOpen" },
  keys = {
    -- Example mapping to toggle outline
    { "<leader>tt", "<cmd>SymbolsOutline<CR>", desc = "Toggle outline" },
  },
  opts = {
    -- Your setup opts here
  },
},
```

This allows Lazy.nvim to lazy load the plugin on commands `SymbolsOutline`,
`SymbolsOutlineOpen`, and your keybindings.


## Setup

Call the setup function with your configuration options.

Note that a call to `.setup()` is *required* for this plugin to work
(simrat39/symbols-outline.nvim#213).

```lua
require("symbols-outline").setup({})
```

## Configuration

The configuration structure has been heavily improved and refactored in this
plugin. For details and reasoning, see [breaking changes](#-breaking-changes).

### Terminology

Check this list if you there's any confusion with the terms used in the
configuration.

- **Provider**: Source of the items in the outline view. Could be LSP, CoC, etc.
- **Node**: An item in the outline view
- **Fold**: Collapse a collapsible node
- **Location**: Where in the source file a node is from
- **Preview**: Show the location of a node in code using a floating window
- **Peek**: Go to corresponding location in code without leaving outline window
- **Hover**: Cursor currently on the line of a node
- **Hover symbol**: Displaying a floating window to show symbol information
provided by provider.
- **Focus**: Which window the cursor is in

### Default options

Pass a table to the setup call with your configuration options.

Default values are shown:

```lua
{
  outline_window = {
    -- Where to open the split window: right/left
    position = 'right',
    -- Only in this fork:
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

    -- Behaviour changed in this fork:
    -- Auto close the outline window if goto_location is triggered and not for
    -- peek_location
    auto_close = false,
    -- Automatically go to location in code when navigating outline window.
    -- Only in this fork
    auto_goto = false,

    -- Vim options for the outline window
    show_numbers = false,
    show_relative_numbers = false,

    -- Only in this fork (this and the one below)
    show_cursorline = true,
    -- Enable this when you enabled cursorline so your cursor color can
    -- blend with the cursorline, in effect, as if your cursor is hidden
    -- in the outline window.
    -- This is useful because with cursorline, there isn't really a need
    -- to know the vertical column position of the cursor and it may even
    -- be distracting, rendering lineno/guides/icons unreadable.
    -- This makes your line of cursor look the same as if the cursor wasn't
    -- focused on the outline window.
    hide_cursor = false,

    -- Whether to wrap long lines, or let them flow off the window
    wrap = false,
    -- Only in this fork:
    -- Whether to focus on the outline window when it is opened.
    -- Set to false to remain focus on your previous buffer when opening
    -- symbols-outline.
    focus_on_open = true,
    -- Only in this fork:
    -- Winhighlight option for outline window.
    -- See :help 'winhl'
    -- To change background color to "CustomHl" for example, append "Normal:CustomHl".
    -- Note that if you're adding highlight changes, you should append to this
    -- default value, otherwise details/lineno will not have highlights.
    winhl = "SymbolsOutlineDetails:Comment,SymbolsOutlineLineno:LineNr",
  },

  outline_items = {
    -- Whether to highlight the currently hovered symbol (high cpu usage)
    highlight_hovered_item = true,
    -- Show extra details with the symbols (lsp dependent)
    show_symbol_details = true,
    -- Only in this fork.
    -- Show line numbers of each symbol next to them.
    -- Why? See this comment:
    -- https://github.com/simrat39/symbols-outline.nvim/issues/212#issuecomment-1793503563
    show_symbol_lineno = false,
  },

  -- Options for outline guides.
  -- Only in this fork
  guides = {
    enabled = true,
    markers = {
      bottom = '└',
      middle = '├',
      vertical = '│',
      horizontal = '─',
    },
  },

  symbol_folding = {
    -- Depth past which nodes will be folded by default
    autofold_depth = nil,
    -- Automatically unfold hovered symbol
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
    -- Only in this fork
    open_hover_on_preview = true,
    -- Only in this fork:
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

  -- These keymaps can be a string or a table for multiple keys
  keymaps = { 
    show_help = '?',
    close = {"<Esc>", "q"},
    -- Jump to symbol under cursor.
    -- It can auto close the outline window when triggered, see
    -- 'auto_close' option above.
    goto_location = "<Cr>",
    -- Jump to symbol under cursor but keep focus on outline window.
    -- Renamed in this fork!
    peek_location = "o",
    -- Only in this fork (next 2):
    -- Visit location in code and close outline immediately
    goto_and_close = "<S-Cr>"
    -- Change cursor position of outline window to the current location in code.
    -- "Opposite" of goto/peek_location.
    restore_location = "<C-g>",
    -- Open LSP/provider-dependent symbol hover information
    hover_symbol = "<C-space>",
    -- Preview location code of the symbol under cursor
    toggle_preview = "K",
    -- Symbol actions
    rename_symbol = "r",
    code_actions = "a",
    -- These fold actions are collapsing tree nodes, not code folding
    fold = "h",
    unfold = "l",
    fold_toggle = "<Tab>",       -- Only in this fork
    -- Toggle folds for all nodes.
    -- If at least one node is folded, this action will fold all nodes.
    -- If all nodes are folded, this action will unfold all nodes.
    fold_toggle_all = "<S-Tab>", -- Only in this fork
    fold_all = "W",
    unfold_all = "E",
    fold_reset = "R",
    -- Only in this fork:
    -- Move down/up by one line and peek_location immediately.
    down_and_goto = "<C-j>",
    up_and_goto = "<C-k>",
  },

  providers = {
    lsp = {
      -- Lsp client names to ignore
      blacklist_clients = {},
    },
  },

  symbols = {
    -- Symbols to ignore.
    -- Possible values are the Keys in the icons table below.
    blacklist = {},
    -- Added in this fork:
    -- You can use a custom function that returns the icon for each symbol kind.
    -- This function takes a kind (string) as parameter and should return an
    -- icon.
    icon_fetcher = nil,
    -- 3rd party source for fetching icons. Fallback if icon_fetcher returned
    -- empty string. Currently supported values: 'lspkind'
    icon_source = nil,
    -- The next fall back if both icon_fetcher and icon_source has failed, is
    -- the custom mapping of icons specified below. The icons table is also
    -- needed for specifying hl group.
    -- Changed in this fork to fix deprecated icons not showing.
    icons = {
      File = { icon = "󰈔", hl = "@text.uri" },
      Module = { icon = "󰆧", hl = "@namespace" },
      Namespace = { icon = "󰅪", hl = "@namespace" },
      Package = { icon = "󰏗", hl = "@namespace" },
      Class = { icon = "𝓒", hl = "@type" },
      Method = { icon = "ƒ", hl = "@method" },
      Property = { icon = "", hl = "@method" },
      Field = { icon = "󰆨", hl = "@field" },
      Constructor = { icon = "", hl = "@constructor" },
      Enum = { icon = "ℰ", hl = "@type" },
      Interface = { icon = "󰜰", hl = "@type" },
      Function = { icon = "", hl = "@function" },
      Variable = { icon = "", hl = "@constant" },
      Constant = { icon = "", hl = "@constant" },
      String = { icon = "𝓐", hl = "@string" },
      Number = { icon = "#", hl = "@number" },
      Boolean = { icon = "⊨", hl = "@boolean" },
      Array = { icon = "󰅪", hl = "@constant" },
      Object = { icon = "⦿", hl = "@type" },
      Key = { icon = "🔐", hl = "@type" },
      Null = { icon = "NULL", hl = "@type" },
      EnumMember = { icon = "", hl = "@field" },
      Struct = { icon = "𝓢", hl = "@type" },
      Event = { icon = "🗲", hl = "@type" },
      Operator = { icon = "+", hl = "@operator" },
      TypeParameter = { icon = "𝙏", hl = "@parameter" },
      Component = { icon = "󰅴", hl = "@function" },
      Fragment = { icon = "󰅴", hl = "@constant" },
      -- Added ccls symbols in this fork
      TypeAlias =  { icon = ' ', hl = '@type' },
      Parameter = { icon = ' ', hl = '@parameter' },
      StaticMethod = { icon = ' ', hl = '@function' },
      Macro = { icon = ' ', hl = '@macro' },
    },
  },
}
```

To find out exactly what some of the options do, please see the
[recipes](#recipes) section of the readme at the bottom for screen-recordings.

The order in which the sources for icons are checked is:

1. Icon fetcher function
2. Icon source (only `lspkind` is supported for this option as of now)
3. Icons table

A fallback is always used if the previous candidate returned either an empty
string or a falsey value.

## Commands

- **:SymbolsOutline[!]**

  Toggle symbols outline. With bang (`!`) the cursor focus stays in your
  original window after opening the outline window. Set `focus_on_win = true` to
  always use this behaviour.

- **:SymbolsOutlineOpen[!]**

  Open symbols outline. With bang (`!`) the cursor focus stays in your original
  window after opening the outline window. Set `focus_on_win = true` to always
  use this behaviour.

- **:SymbolsOutlineClose**

  Close symbols outline

- **:SymbolsOutlineFocus**

  Toggle focus on symbols outline

- **:SymbolsOutlineFocusOutline**

  Focus on symbols outline

- **:SymbolsOutlineFocusCode**

  Focus on source window

- **:SymbolsOutlineStatus**

  Display current provider and outline window status in the messages area.

- **:SymbolsOutlineFollow[!]**

  Go to corresponding node in outline based on cursor position in code, and
  focus on the outline window.

  With bang, retain focus on the code window.

  This can be understood as the converse of `goto_location` (see keymaps).
  `goto_location` sets cursor of code window to the position of outline window,
  whereas this command sets position in outline window to the cursor position of
  code window.

  With bang, it can be understood as the converse of `focus_location`.


## Default keymaps

These mappings are active for the outline window.

| Key        | Action                                             |
| ---------- | -------------------------------------------------- |
| Esc / q    | Close outline                                      |
| ?          | Show help                                          |
| Enter      | Go to symbol location in code                      |
| o          | Go to symbol location in code without losing focus |
| Shift+Enter| Go to symbol location in code and close outline    |
| Ctrl+k     | Go up and goto location                            |
| Ctrl+j     | Go down and goto location                          |
| Ctrl+g     | Update outline window to focus on code location    |
| Ctrl+Space | Hover current symbol (provider action)             |
| K          | Toggles the current symbol preview                 |
| r          | Rename symbol                                      |
| a          | Code actions                                       |
| h          | Fold symbol or parent symbol                       |
| Tab        | Toggle fold under cursor                           |
| Shift+Tab  | Toggle all folds                                   |
| l          | Unfold symbol                                      |
| W          | Fold all symbols                                   |
| E          | Unfold all symbols                                 |
| R          | Reset all folding                                  |

## Highlights

### Outline window

Default:

```lua
outline_window = {
  winhl = "SymbolsOutlineDetails:Comment,SymbolsOutlineLineno:LineNr",
},
```

Possible highlight groups provided by symbols-outline to customize:

| Highlight               | Purpose                                        |
| ----------------------- | ---------------------------------------------- |
| SymbolsOutlineCurrent   | Highlight of the focused symbol                |
| SymbolsOutlineConnector | Highlight of the table connectors              |
| SymbolsOutlineDetails   | Highlight of the details info virtual text     |
| SymbolsOutlineLineno    | Highlight of the lineno column                 |

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

## Lua API

Symbols-outline provides the following public API for use in lua.

```lua
require'symbols-outline'
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

  Display current provider and outline window status in the messages area.

- **has_provider()**

  Returns whether a provider is available for current window.

- **follow_cursor(opts)**

  Go to corresponding node in outline based on cursor position in code, and
  focus on the outline window.

  With `opts.focus_outline=false`, cursor focus will remain on code window.


## Tips

- To open the outline but don't focus on it, you can use `:SymbolsOutline!` or
`:SymbolsOutlineOpen!`.

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

  A fallback is always used if the previous candidate returned either an empty
  string or a falsey value.

- You can customize the split command used for creating the outline window split
  using `outline_window.split_command`, such as `"topleft vsp"`. See `:h windows`

## Recipes

Behaviour you may want to achieve and the combination of configuration options
to achieve it.

Code snippets in this section are to be placed in `.setup({ <HERE> })` directly
unless specified otherwise.

- **Unfold all others except currently hovered item**

```lua
symbol_folding = {
  autofold_depth = 1,
  auto_unfold_hover = true,
},
```
<img width="900" alt="outline window showing auto fold depth" src="https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/2e0c5f91-a979-4e64-a100-256ad062dce3">


- **Use outline window as a quick-jump window**

```lua
preview_window = {
  auto_preview = true,
},
```

https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/a473d791-d1b9-48e9-917f-b816b564a645

Note that in the recording I have `preview_window.open_hover_on_preview =
false`.

Alternatively, if you want to automatically navigate to the corresponding code
location directly and not use the preview window:

```lua
outline_window = {
  auto_goto = true,
},
```

This feature was added by @stickperson in an upstream PR 🙌

https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/3d06e342-97ac-400c-8598-97a9235de66c

Or, you can use keys `<C-j>` and `<C-k>` to achieve the same effect, whilst not
having `auto_goto` on by default.

This feature is newly added in this fork.

- **Hide the extra details after each symbol name**

```lua
outline_items = {
  show_symbol_details = false,
},
```

- **Show line numbers next to each symbol to jump to that symbol quickly**

This feature is newly added in this fork.

```lua
outline_items = {
  show_symbol_lineno = false,
},
```

The default highlight group for the line numbers is `LineNr`, you can customize
it using `outline_window.winhl`: please see [highlights](#outline-window).

<img width="900" alt="outline window showing lineno" src="https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/2bbb5833-f40b-4c53-8338-407252d61443">

- **Single cursorline**

```lua
outline_window = {
  show_cursorline = true,
  hide_cursor = true,
}
```

This will be how the outline window looks like when focused:

<img width="300" alt="outline window showing hide_cursor" src="https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/1e13c4db-ae51-4e1f-a388-2758871df36a">

Note that in the screenshot, `outline_items.show_symbol_lineno` is also enabled.

Some may find this unhelpful, but one may argue that elements in each row of the
outline becomes more readable this way, hence this is an option.

This feature is newly added in this fork, and is currently experimental (may be
unstable).

- **Custom icons**

You can write your own function for fetching icons. Here is one such example
that simply returns in plain text, the first letter of the given kind.

```lua
symbols = {
  icon_fetcher = function(kind) return kind:sub(1,1) end
}
```

The fetcher function, if provided, is checked first before using `icon_source`
and `icons` as fallback.

<img width="300" alt="outline with plain text icons" src="https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/655b534b-da16-41a7-926e-f14475376a04">


<!-- panvimdoc-ignore-start -->

---
Any other recipes you think others may also find useful? Feel free to open a PR.

<!-- panvimdoc-ignore-end -->
