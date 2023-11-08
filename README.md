# Fork status

[Skip to plugin readme](#symbols-outlinenvim)

This is a fork of the original symbols-outline.nvim which fixes a lot of bugs
from the original repo.

It also adds many more features listed [below](#features).

It does not attempt to be an up-to-date successor of the original repo, nor does
it attempt to ensure everyone's use-cases are satisfied by providing an overall
better experience. It is merely a fork which I maintain for my personal
use-cases which incorporates some selected PRs.

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

- **Config**: `keymaps.focus_location` RENAMED to `keymaps.peek_location` to
  avoid confusion with focus window commands.

- **Config**: Marker icons used for guides can now be customized. `show_guides`
  REMOVED in favor of `guides.enabled`.

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

- Move down/up by one line and peek_location immediately.

- Flash highlight when using goto/peek location.

- Auto jump config option (see config `auto_goto`)
(simrat39/symbols-outline.nvim#229, simrat39/symbols-outline.nvim#228).

- New Follow command, opposite of `goto_location`/`focus_location`

- New restore location keymap option to go back to corresponding outline
  location synced with code (see config `restore_location`).

Screen recordings of some of the features is shown at the bottom of the readme.

## PRs

[Skip to plugin readme](#symbols-outlinenvim)

Key:
```
✅ = Either merged superseded
📮 = Planned for merge
```

- 📮 center view on goto symbol
  (#239 by skomposzczet)

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

- Distinguish between public and private function display in Elixir
  (#187 by scottming)

- ✅ Fix some options
  (#180 by cljoly)

- ✅ fix: Invalid buffer id error
  (#177 by snowair)

- ✅ fix(code_actions): use the builtin code_action
  (#168 by zjp-CN)

- ✅ fix: plugin crashes when SymbolOutlineClose used
  (#163 by beauwilliams)

- 📮 feat: Add window_bg_highlight to config
  (#137 by Zane-)

- 📮 Added preview width and relative size
  (#130 by Freyskeyd)

- 📮 Improve preview, hover windows configurability and looks
  (#128 by toppair)

- ✅ Do not close outline when focus_location occurs
  (#119 by M1Sports20)

- ✅ feat: instant_preview
  (#116 by axieax)

  **Superseded with an improved implementation**

- ✅ check if code_win is nill
  (#110 by i3Cheese)

  **Superseded before this fork was created**

  (perhaps the PR was forgotten to be closed)

- Floating window (Draft)
  (#101 by druskus20)


## TODO

[Skip to plugin readme](#symbols-outlinenvim)

Key:
```
- [ ] : Planned
- [/] : WIP
-     : Idea
```

- Folds
  - `[ ]` Org-like <kbd>shift+tab</kbd> behavior: Open folds level-by-level
  - `[ ]` Optionally not opening all child nodes when opening parent node
  - Fold siblings and siblings of parent on startup
- Navigation
  - Go to parent
  - Cycle siblings

- `[ ]` simrat39/symbols-outline.nvim#75: Handling of the outline window when attached
  buffer is closed.

  Maybe it should continue working, so that pressing enter can open a split to
  the correct location, and pressing `q` can properly close the buffer.

- Preview / Hover
  - `[/]` Configurable winhighlight options for preview window (like nvim-cmp)
  (simrat39/symbols-outline#128)
  - `[/]` Configurable width and height of preview window (simrat39/symbols-outline.nvim#130)

- View
  - `[/]` Outline window customizations (simrat39/symbols-outline.nvim#137)
  - ✅ Option to show line number next to symbols (simrat39/symbols-outline.nvim#212)
  - `[/]` Option to hide cursor in outline window if cursorline enabled


## Related plugins

- nvim-navic
- nvim-navbuddy
- dropdown.nvim
- treesitter (inspect/edit)
- lspsaga
- navigator.lua

---

# symbols-outline.nvim

**A tree like view for symbols in Neovim using the Language Server Protocol.
Supports all your favourite languages.**

![demo](https://github.com/simrat39/rust-tools-demos/raw/master/symbols-demo.gif)

Table of contents

<!-- mtoc start -->

* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Setup](#setup)
* [Configuration](#configuration)
    * [Terminology](#terminology)
    * [Options](#options)
* [Commands](#commands)
    * [Lua API](#lua-api)
* [Default keymaps](#default-keymaps)
* [Highlights](#highlights)
* [Recipes](#recipes)

<!-- mtoc end -->

## Prerequisites

- `neovim 0.7+`
- Properly configured Neovim LSP client

## Installation

Use `hedyhli/symbols-outline.nvim` if you wish to use this fork.

Packer:
```lua
use 'simrat39/symbols-outline.nvim'
```

Lazy:
```lua
{
  "simrat39/symbols-outline.nvim",
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
  "simrat39/symbols-outline.nvim",
  cmd = { "SymbolsOutline", "SymbolsOutlineOpen" },
  keys = {
    -- Example mapping to toggle outline
    { "<leader>tt", "<cmd>SymbolsOutline<CR>", desc = "Toggle outline window" },
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

### Terminology

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

### Options

Pass a table to the setup call with your configuration options.

Default values are shown:

```lua
local opts = {
  -- Where to open the split window: right/left
  position = 'right',
  -- Whether width is relative to existing windows
  relative_width = true,
  -- Percentage or integer of columns
  width = 25,

  -- Whether to highlight the currently hovered symbol (high cpu usage)
  highlight_hovered_item = true,
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
  -- Automatically open preview of code on hover
  auto_preview = false,
  -- Automatically open hover_symbol when opening toggle_preview (see keymaps).
  -- If you disable this you can still open hover_symbol using your keymap
  -- below.
  -- Only in this fork
  open_hover_on_preview = true,
  -- Border option for floating preview window.
  -- Options include: single/double/rounded/solid/shadow or an array of border
  -- characters.
  -- See :help nvim_open_win() and search for "border" option.
  border = 'single',
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
  show_cursorline = true,  -- Only in this fork
  -- Show extra details with the symbols (lsp dependent)
  show_symbol_details = true,
  -- Only in this fork.
  -- Show line numbers of each symbol next to them.
  -- Why? See this comment:
  -- https://github.com/simrat39/symbols-outline.nvim/issues/212#issuecomment-1793503563
  show_symbol_lineno = false,
  -- Highlight group for the preview background
  preview_bg_highlight = 'Pmenu',
  -- Depth past which nodes will be folded by default
  autofold_depth = nil,
  -- Automatically unfold hovered symbol
  auto_unfold_hover = true,
  fold_markers = { '', '' },
  -- Whether to wrap long lines, or let them flow off the window
  wrap = false,

  -- Only in this fork:
  -- Whether to focus on the outline window when it is opened.
  -- Set to false to remain focus on your previous buffer when opening
  -- symbols-outline.
  focus_on_open = true,
  -- Pseudo-transparency of the preview window
  winblend = 0

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
    -- Only in this fork:
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
    fold_toggle = '<Tab>',       -- Only in this fork
    -- Toggle folds for all nodes.
    -- If at least one node is folded, this action will fold all nodes.
    -- If all nodes are folded, this action will unfold all nodes.
    fold_toggle_all = '<S-Tab>', -- Only in this fork
    fold_all = "W",
    unfold_all = "E",
    fold_reset = "R",
    -- Only in this fork:
    -- Move down/up by one line and peek_location immediately.
    down_and_goto = '<C-j>',
    up_and_goto = '<C-k>',
  },

  -- Lsp clients to ignore
  lsp_blacklist = {},
  -- Symbols to ignore.
  -- Possible values: lua/symbols-outline/symbols.lua
  symbol_blacklist = {},

  symbols = {
    -- Changed in this fork
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
    -- ccls
    TypeAlias =  { icon = ' ', hl = '@type' },
    Parameter = { icon = ' ', hl = '@parameter' },
    StaticMethod = { icon = ' ', hl = '@function' },
    Macro = { icon = ' ', hl = '@macro' },
  },
}
```

To find out exactly what some of the options do, check out the
[recipes](#recipes) section of the readme at the bottom for screen-recordings.

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


### Lua API

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


## Default keymaps

These mappings are active for the outline window.

| Key        | Action                                             |
| ---------- | -------------------------------------------------- |
| Escape     | Close outline                                      |
| ?          | Show help message                                  |
| Enter      | Go to symbol location in code                      |
| o          | Go to symbol location in code without losing focus |
| Ctrl+j     | Go up and goto location                            |
| Ctrl+k     | Go down and goto location                          |
| Ctrl+g     | Go to code location in outline window              |
| Ctrl+Space | Hover current symbol                               |
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

| Highlight               | Purpose                                |
| ----------------------- | -------------------------------------- |
| FocusedSymbol           | Highlight of the focused symbol        |
| Pmenu                   | Highlight of the preview popup windows |
| SymbolsOutlineConnector | Highlight of the table connectors      |
| Comment                 | Highlight of the info virtual text     |


## Recipes

Behaviour you may want to achieve and the combination of configuration options
to achieve it.

**Unfold all others except currently hovered item**

```lua
autofold_depth = 1,
auto_unfold_hover = true,
```
<img width="900" alt="image" src="https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/2e0c5f91-a979-4e64-a100-256ad062dce3">


Any other recipes you think others may also find useful? Feel free to open a PR.

**Use outline window as a quick-jump window**

```lua
auto_preview = true,
```

https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/a473d791-d1b9-48e9-917f-b816b564a645

Alternatively, if you want to automatically navigate to the corresponding code
location and not use the preview window:

```lua
auto_goto = true,
```

This feature was added by @stickperson in an upstream PR 🙌

https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/3d06e342-97ac-400c-8598-97a9235de66c

Or, you can use keys `<C-j>` and `<C-k>` to achieve the same effect, whilst not
having `auto_goto` on by default.


**Hide the extra details after each symbol name**

```lua
show_symbol_details = false,
```

**Show line numbers next to each symbol to jump to that symbol quickly**

```lua
show_symbol_lineno = true,
```

The default highlight group is `LineNr`.

<img width="900" alt="image" src="https://github.com/hedyhli/symbols-outline.nvim/assets/50042066/2bbb5833-f40b-4c53-8338-407252d61443">


