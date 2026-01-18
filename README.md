<!-- panvimdoc-ignore-start -->

<details>
<summary>⚠️  Coming from <strong>symbols-outline.nvim</strong>?</summary>

This is a fork of the original **symbols-outline.nvim** with many fixes and
improvements, you can see the full list in [#12 on
github](https://github.com/hedyhli/outline.nvim/issues/12) with links to issues
from the original repo, and after `outline.nvim` was detached as a fork, all
changes are documented in the [changelog](./CHANGELOG.md).

**Migrating your configuration**

If you have existing setup opts for symbols-outline.nvim, you can convert it to
be usable for outline.nvim using this script:
[scripts/convert-symbols-outline-opts.lua](scripts/convert-symbols-outline-opts.lua).

</details>

<!-- panvimdoc-ignore-end -->

---

<!-- panvimdoc-ignore-start -->

# outline.nvim

> *A sidebar with a tree-like outline of symbols from your code, powered by LSP.*

https://github.com/hedyhli/outline.nvim/assets/50042066/f66fa661-b66a-4b48-84e8-37920a3d8d2c

**Features**

- Auto-updates items and highlight for current symbol as the cursor moves
- Supports **JSX** (treesitter), **Markdown**, **Norg** (treesitter), **Man**, in
  addition to LSP.
- Support for other languages for treesitter through an [external
provider](https://github.com/epheien/outline-treesitter-provider.nvim).
- Outline window opened for each tabpage
- Symbol hierarchy UI with collapsible nodes and automatic collapsing based on
  cursor movements
- Custom symbol icon function, mapping, or use LspKind (see [custom
  function](#custom-icons) and [config](#symbols-table))
- Dynamically set cursorline and cursor colors in outline (see
  [screenshot](#blend-cursor-with-cursorline))
- Extra symbol details and line numbers of symbols (see
  [screenshot](#blend-cursor-with-cursorline))
- Preview symbol location without visiting it
- Neovim command modifiers on where to open outline (see `:h mods`)
- Support for opening outline as a floating window (see `:OutlineOpenFloat`)

> Unconvinced? Check out the outline.nvim alternatives and [related
> plugins](#related-plugins).

<!-- panvimdoc-ignore-end -->

## Prerequisites

- Neovim 0.7+
  - Note that it is recommended to use Neovim 0.8+ for all the features and fixes.
    See details [here](#neovim-07). Everything else works as normal in Neovim 0.7.
- To use outline.nvim with LSP, a properly configured LSP client is required.

<!-- panvimdoc-ignore-start -->

## Contents

<!-- mtoc-start -->

* [Installation](#installation)
* [Setup](#setup)
* [Configuration](#configuration)
* [Providers](#providers)
* [Commands](#commands)
* [Default keymaps](#default-keymaps)
* [Highlights](#highlights)
* [Lua API](#lua-api)
* [Tips](#tips)
* [Recipes](#recipes)
* [Neovim 0.7](#neovim-07)
* [Limitations](#limitations)
* [Related plugins](#related-plugins)

<!-- mtoc-end -->
<!-- panvimdoc-ignore-end -->

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
    vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>",
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
    { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle outline" },
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
(otherwise you might see this error:
[simrat39/symbols-outline.nvim#213](https://github.com/simrat39/symbols-outline.nvim/issues/213)).

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
- **Follow**: Update hover highlight and cursor position in outline to match
  position in code. Opposite of 'jump'.

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
    -- Width can be included (with will override the width setting below):
    -- Eg, `topleft 20vsp` to prevent a flash of windows when resizing.
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
    -- To change background color to "CustomHl" for example, use "Normal:CustomHl".
    winhl = '',
    -- Message displayed when there are no providers avialable.
    no_provider_message = 'No supported provider...'

    -- Floating window options
    float = {
      -- Percentage or integer of columns
      width = 30,
      -- Percentage or integer of lines
      height = 80,
      -- Whether width is relative to the total width of nvim
      relative_width = true,
      -- Whether height is relative to the total height of nvim
      relative_height = true,
      -- Configuration passed directly to nvim_open_win
      -- Can be a table or a function that returns a table
      win_config = {
        relative = 'editor',
        border = 'rounded',
        zindex = 50,
        focusable = true,
        style = 'minimal',
        title = 'Outline',
        title_pos = 'center',
      },
      -- Additional window options (set via nvim_win_set_option)
      win_options = {},
    },
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
    -- Depth past which nodes will be folded by default. Set to false to unfold all on open.
    autofold_depth = 1,
    -- When to auto unfold nodes
    auto_unfold = {
      -- Auto unfold currently hovered symbol
      hovered = true,
      -- Auto fold when the root level only has this many nodes.
      -- Set true for 1 node, false for 0.
      only = true,
    },
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
    min_width = 50, -- Minimum number of columns
    -- Whether width is relative to the total width of nvim.
    -- When relative_width = true, this means take 50% of the total
    -- screen width for preview window, ensure the result width is at least 50
    -- characters wide.
    relative_width = true,
    height = 50,     -- Percentage or integer of lines
    min_height = 10, -- Minimum number of lines
    -- Similar to relative_width, except the height is relative to the outline
    -- window's height.
    relative_height = true,
    -- Border option for floating preview window.
    -- Options include: single/double/rounded/solid/shadow or an array of border
    -- characters.
    -- See :help nvim_open_win() and search for "border" option.
    border = 'single',
    -- winhl options for the preview window, see ':h winhl'
    winhl = 'NormalFloat:',
    -- Pseudo-transparency of the preview window, see ':h winblend'
    winblend = 0,
    -- Experimental feature that let's you edit the source content live
    -- in the preview window. Like VS Code's "peek editor".
    live = false
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
    priority = { 'lsp', 'coc', 'markdown', 'norg', 'man' },
    -- Configuration for each provider (3rd party providers are supported)
    lsp = {
      -- Lsp client names to ignore
      blacklist_clients = {},
    },
    markdown = {
      -- List of supported ft's to use the markdown provider
      filetypes = {'markdown'},
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
    ---@param kind string Key of the icons table below
    ---@param bufnr integer Code buffer
    ---@param symbol outline.Symbol The current symbol object
    ---@returns string|boolean The icon string to display, such as "f", or `false`
    ---                        to fallback to `icon_source`.
    icon_fetcher = nil,
    -- 3rd party source for fetching icons. This is used as a fallback if
    -- icon_fetcher returned an empty string.
    -- Currently supported values: 'lspkind'
    icon_source = nil,
    -- The next fallback if both icon_fetcher and icon_source has failed, is
    -- the custom mapping of icons specified below. The icons table is also
    -- needed for specifying hl group.
    icons = {
      File = { icon = '󰈔', hl = 'Identifier' },
      Module = { icon = '󰆧', hl = 'Include' },
      Namespace = { icon = '󰅪', hl = 'Include' },
      Package = { icon = '󰏗', hl = 'Include' },
      Class = { icon = '𝓒', hl = 'Type' },
      Method = { icon = 'ƒ', hl = 'Function' },
      Property = { icon = '', hl = 'Identifier' },
      Field = { icon = '󰆨', hl = 'Identifier' },
      Constructor = { icon = '', hl = 'Special' },
      Enum = { icon = 'ℰ', hl = 'Type' },
      Interface = { icon = '󰜰', hl = 'Type' },
      Function = { icon = '', hl = 'Function' },
      Variable = { icon = '', hl = 'Constant' },
      Constant = { icon = '', hl = 'Constant' },
      String = { icon = '𝓐', hl = 'String' },
      Number = { icon = '#', hl = 'Number' },
      Boolean = { icon = '⊨', hl = 'Boolean' },
      Array = { icon = '󰅪', hl = 'Constant' },
      Object = { icon = '⦿', hl = 'Type' },
      Key = { icon = '🔐', hl = 'Type' },
      Null = { icon = 'NULL', hl = 'Type' },
      EnumMember = { icon = '', hl = 'Identifier' },
      Struct = { icon = '𝓢', hl = 'Structure' },
      Event = { icon = '🗲', hl = 'Type' },
      Operator = { icon = '+', hl = 'Identifier' },
      TypeParameter = { icon = '𝙏', hl = 'Identifier' },
      Component = { icon = '󰅴', hl = 'Function' },
      Fragment = { icon = '󰅴', hl = 'Constant' },
      TypeAlias = { icon = ' ', hl = 'Type' },
      Parameter = { icon = ' ', hl = 'Identifier' },
      StaticMethod = { icon = ' ', hl = 'Function' },
      Macro = { icon = ' ', hl = 'Function' },
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

## Providers

The current list of tested providers are:
1. LSP (requires a suitable LSP server to be configured for the requested buffer)
   - For JSX support, `javascript` parser for treesitter is required
1. Markdown (no external requirements)
1. Norg (requires `norg` parser for treesitter)

External providers:
- [Asciidoc](https://github.com/msr1k/outline-asciidoc-provider.nvim) (no external requirements)
- [Treesitter](https://github.com/epheien/outline-treesitter-provider.nvim) (require treesitter)
- [ctags](https://github.com/epheien/outline-ctags-provider.nvim) (require universal-ctags)
- [Test blocks](https://github.com/bngarren/outline-test-blocks-provider.nvim)
(For showing `describe(...)`, `it(...)` in the outline)

<details>
  <summary>How to implement an external provider</summary>

External providers are separate plugins that users can install in addition to
`outline.nvim`. Their names can be appended to the `providers.priority` list in
the outline.nvim config. Each item in the `providers.priority` list is used
to form an import path `"outline.providers.<item>"` and then `require()`'ed for
use as a provider.

External providers from plugins should define the provider module at
`lua/outline/providers/<name>.lua` with these functions:

- `supports_buffer(bufnr: integer, config: table?) -> boolean`

  This function could check buffer filetype, existence of required modules, etc.

  The config table comes from the user's configuration in the
  `providers['provider-name']` table where `provider-name` is the
  `require('outline.providers.<name>').name`.

- `get_status() -> string[]` (optional)

  Return a list of lines to be included in `:OutlineStatus` as supplementary
  information when this provider is active.

  See an example of this function in the
  [LSP](./lua/outline/providers/nvim-lsp.lua) provider.

- `request_symbols(callback: function, opts: table)`

  - param `callback` is a function that receives a list of symbols and the
  `opts` table.
  - param `opts` can be passed to `callback` without processing

  The function should return a list of "symbol tables".

  Each symbol table should have these fields:
  - name: string -- displayed in the outline
  - kind: integer|string -- determines the icon to use
  - selectionRange: table with fields `start` and `end`, each have fields
  `line` and `character`, each integers:
  `{ start = { line = ?, character = ? }, ['end'] = { line = ?, character = ? } }`
  - range: same as selectionRange
  - children: list of symbol tables
  - detail: (optional) string, shown for `outline_items.show_symbol_details`

The built-in [markdown](./lua/outline/providers/markdown.lua) provider is a
good example of a very simple outline-provider module which parses raw buffer
lines and uses regex; the built-in [norg](./lua/outline/providers/norg.lua)
provider is an example which uses treesitter.

All providers should support at least nvim 0.7. You can make use of
`_G._outline_nvim_has` with fields `[8]`, `[9]`, and `[10]`. For instance,
`_G._outline_nvim_has[8]` is equivalent to: `vim.fn.has('nvim-0.8') == 1`.

If a higher nvim version is required, it is recommended to check for this
requirement in the `supports_buffer` function.

Hover symbol, code action and rename functions are defined from providers. You
can customize what these functions do if these functions are triggered when
your provider is active. See the built-in
[LSP](./lua/outline/providers/nvim-lsp.lua) provider for an example.

Other functions such as goto-location may also be delegated to providers in the
future.

</details>


## Commands

- **:Outline[!]** (✓ bang ✓ mods)

  Toggle outline. With bang (`!`) the cursor focus stays in your
  original window after opening the outline window. Set
  `outline_window.focus_on_open = false` to always use this behaviour.

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
  window after opening the outline window. Set `outline_window.focus_on_open =
  false` to always use this behaviour.

  You can use command modifiers `topleft`/`aboveleft`/`botright`/`belowright`
  on this command to control how the outline window split is created. Other
  modifiers are ignored.

```vim
" in config: position='left'
:aboveleft OutlineOpen   " opens with 'aboveleft vsplit'
:belowright OutlineOpen  " opens with 'belowright vsplit'
:OutlineOpen             " opens with 'topleft vsplit'
```

  If the outline is already open, running this command without bang will focus
  on the outline window.

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

- **:OutlineOpenFloat[!]** (✓ bang × mods)

  Open outline as a floating window. With bang (`!`) the cursor focus stays in your
  original window after opening the outline window.

- **:OutlineToggleFloat[!]** (✓ bang × mods)

  Toggle outline as a floating window. With bang (`!`) the cursor focus stays in
  your original window after opening the outline window.


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


If you frequently use horizontal splits and need `<C-k/j>` to navigate them,
you may want to remap:
```lua
keymaps = {
  up_and_jump = '<C-p>',
  down_and_jump = '<C-n>',
}
```

Or if you never use arrow keys to move around, you can use:
```lua
keymaps = {
  up_and_jump = '<up>',
  down_and_jump = '<down>',
}
```

## Highlights

### Outline window

Default:

```lua
outline_window = {
  winhl = '',
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

You can customize any other highlight groups using `winhl`, this option is
passed directly to the `winhl` vim option unprocessed.

If any of the above highlights have not already been set before outline.setup
is called (say by a theme), the following links are used:

| Highlight            | Link     |
| -------------------- | -------- |
| OutlineGuides        | Comment  |
| OutlineFoldMarker    | Normal   |
| OutlineDetails       | Comment  |
| OutlineLineno        | LineNr   |

For `OutlineCurrent`, foreground is set to String and background CursorLine.

To customize colors of the symbol icons, use the `symbols.icons` table. See
[config](#configuration).

### Preview window

```lua
preview_window = {
  winhl = 'NormalFloat:',
},
```

### Help windows

| Highlight                 | Link     |
| ------------------------- | -------- |
| OutlineHelpTip            | Comment  |
| OutlineStatusFt           | Type     |
| OutlineStatusError        | ErrorMsg |
| OutlineStatusProvider     | Special  |
| OutlineKeymapHelpKey      | Special  |
| OutlineKeymapHelpDisabled | Comment  |

Help windows include:
1. the keymap help from pressing `?` in the outline window
1. `:OutlineStatus`


### Other highlight groups

| Highlight            | Description                                                           |
| -------------------- | --------------------------------------------------------------------- |
| OutlineJumpHighlight | Indicating cursor position when jumping/focusing, defaults to Visual  |

You can also use `outline_window.jump_highlight_duration` to customize in milliseconds,
how long the highlight is applied for.

## Lua API

Outline.nvim provides the following public API for use in lua.

```lua
require'outline'
```
- setup(opts)

- **toggle(opts)**

  Toggle opening/closing of outline window.

  If `opts.focus_outline=false`, keep focus on previous window.

- **open(opts)**

  Open the outline window.

  If `opts.focus_outline=false`, keep focus on previous window.

- **close()**

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

  Returns whether a provider is available.

- **follow_cursor(opts)**

  Go to corresponding node in outline based on cursor position in code, and
  focus on the outline window.

  With `opts.focus_outline=false`, cursor focus will remain on code window.

  This is automatically called on events
  `outline_items.auto_update_events.follow` from config.

- **has_focus()**

  Return whether outline is open and current focus is in outline.

- **refresh()**

  Re-request symbols from provider and update outline items.

  This is automatically called on events
  `outline_items.auto_update_events.refresh` from config.

- **open_outline_float(opts)**

  Open the outline window as a floating window.

  If `opts.focus_outline=false`, keep focus on previous window.

- **toggle_outline_float(opts)**

  Toggle opening/closing of outline window as a floating window.

  If `opts.focus_outline=false`, keep focus on previous window.

 - **get_breadcrumb(opts)**

  Return a string concatenated from hovered symbols hierarchy representing code
  location.

  Optional opts table fields:
  - depth (nil): Maximum depth of the last symbol included. First item has depth 1.
    Set to 0 or nil to include all
  - sep (` > `): String for separator

- **get_symbol(opts)**

  Return the symbol name of the deepest hovered symbol representing code
  location.

  Optional opts table fields:
  - depth (nil): Maximum depth of the returned symbol
  - kind (nil): Symbol kind to search for (string).


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

  The `icon_fetcher` function may also accept a second and third parameter, the buffer
  number of the code buffer, and the symbol object of type `outline.Symbol`. For
  example, you can use it to determine the icon to use based on the filetype.

```lua
symbols = {
  icon_fetcher = function(kind, bufnr, symbol)
    -- Use nvim_buf_get_option(bufnr, 'ft') for nvim 0.7 users
    local ft = vim.api.nvim_get_option_value('ft', { buf = bufnr })
    -- ...
  end,
}
```

  Or display public, protected, and private symbols differently:

```lua
symbols = {
  icon_fetcher = function(kind, bufnr, symbol)
    local access_icons = { public = '○', protected = '◉', private = '●' }
    local icon = require('outline.config').o.symbols.icons[kind].icon
    -- ctags provider might add an `access` key
    if symbol and symbol.access then
      return icon .. ' ' .. access_icons[symbol.access]
    end
    return icon
  end,
}
```

  See [this section](#custom-icons) for other examples of this function.

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

(Now a default behaviour, different to symbols-outline.nvim.)

Unfold all others except currently hovered item.

```lua
symbol_folding = {
  autofold_depth = 1,
  auto_unfold = {
    hovered = true,
  },
},
```
<div align=center><img width="900" alt="outline window showing auto fold depth" src="https://github.com/hedyhli/outline.nvim/assets/50042066/2e0c5f91-a979-4e64-a100-256ad062dce3"></div>

### Unfold entire symbol tree by default

```lua
symbol_folding = {
  autofold_depth = false,
},
```

### Auto-unfold when there's only two (or any number of) root nodes

```lua
symbol_folding = {
  auto_unfold = {
    only = 2,
  },
},
```

`auto_unfold.only = 2`:

https://github.com/hedyhli/outline.nvim/assets/50042066/035fadac-ecee-4427-9ee1-795dac215cea

`auto_unfold.only = 1`:

https://github.com/hedyhli/outline.nvim/assets/50042066/3a123b7e-ccf6-4278-9a8c-41d2e1865d83

In words "auto unfold nodes when there is only 2 nodes shown in the outline."

For `auto_unfold.only = true`: "auto unfold nodes when the root node is the only node left visible in the outline."


### Auto-jump

Use outline window as a quick-jump window

```lua
preview_window = {
  auto_preview = true,
},
```

https://github.com/hedyhli/outline.nvim/assets/50042066/a473d791-d1b9-48e9-917f-b816b564a645

Note that auto-resizing of the preview window is only enabled for auto-preview.
Otherwise, close and reopen the preview after resizing the code window.

https://github.com/hedyhli/outline.nvim/assets/50042066/b7f6d2b6-98b3-4557-8143-e49583e99d3b


Alternatively, if you want to automatically navigate to the corresponding code
location directly and not use the preview window:

```lua
outline_window = {
  auto_jump = true,
},
```

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

Hide the cursor within cursorline. This setting changes the cursor color to be
that of `Cursorline` when focus is in outline window. As of now `guicursor` is
a global option, so outline.nvim has to set and reset responsibly hence this
feature may be unstable. You can inspect
`require('outline').state.original_cursor` and set `guicursor` accordingly,
though you should almost never need to do this.

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


### Custom icons

You can write your own function for fetching icons. Here is one such example
that simply returns in plain text, the first letter of the given kind.

```lua
symbols = {
  icon_fetcher = function(kind, bufnr, symbol) return kind:sub(1,1) end,
}
```

The fetcher function, if provided, is checked first before using `icon_source`
and `icons` as fallback.

<div align=center><img width="500" alt="outline with plain text icons" src="https://github.com/hedyhli/outline.nvim/assets/50042066/655b534b-da16-41a7-926e-f14475376a04"></div>

### Different icons based on filetype

```lua
symbols = {
  icon_fetcher = function(kind, bufnr)
    -- Use nvim_buf_get_option(bufnr, 'ft') for nvim 0.7 users
    local ft = vim.api.nvim_get_option_value('ft', { buf = bufnr })
    -- ...
  end,
}
```

### Disable icons

Disable all icons:

```lua
symbols = {
  icon_fetcher = function() return "" end,
}
```

Disable icons for specific kinds, and for others use lspkind:

```lua
symbols = {
  icon_fetcher = function(k, buf)
    if k == 'String' then
      return ""
    end
    return false
  end,
  icon_source = 'lspkind',
}
```

<div align=center><img width="500" alt="outline with disabled icon for String" src="https://github.com/hedyhli/outline.nvim/assets/50042066/26d258c6-9530-43d4-b88b-963304e3bf2d"></div>

### Disable icons for a specific filetype

In this example, icons are disabled for markdown, and `lspkind` is used for
other filetypes.

```lua
symbols = {
  icon_fetcher = function(k, buf)
    -- Use nvim_buf_get_option(buf, 'ft') for nvim 0.7 users
    local ft = vim.api.nvim_get_option_value("ft", { buf = buf })
    if ft == 'markdown' then
      return ""
    end
    return false
  end,
  icon_source = "lspkind",
}
```

### Live, editable previews

Press `K` to open the preview, press `K` again to focus on the preview window
to make any quick edits, similar to VS Code's reference window "peek editor".

Then use `:q` to close the window, and continue browsing the outline.

```lua
preview_window = {
  live = true,
}
```

Note that this feature is experimental and may be unstable.

https://github.com/hedyhli/outline.nvim/assets/50042066/183fc5f9-b369-41e2-a831-a4185704d76d

Auto-preview with the feature is also supported, set `auto_preview = true` and
press `K` to focus on the auto-opened preview window. `:q` to quit the window.

### Floating window

Open outline as a floating window instead of a split window:

```lua
-- Using command
:OutlineOpenFloat
```

Or using the Lua API:

```lua
require('outline').open_outline_float()
```

You can customize the floating window appearance using the `outline_window.float`
configuration:

```lua
outline_window = {
  float = {
    width = 40,
    height = 80,
    relative_width = true,
    relative_height = true,
    win_config = {
      relative = 'editor',
      border = 'rounded',
      zindex = 50,
      focusable = true,
      style = 'minimal',
      title = 'Outline',
      title_pos = 'center',
    },
    win_options = {
      winblend = 10,  -- Pseudo-transparency
    },
  },
}
```

The `win_config` table is passed directly to `nvim_open_win()`, so you can use any
options supported by that function. You can also provide a function that returns
the configuration table for dynamic configuration.

<!-- panvimdoc-ignore-start -->

---
Any other recipes you think others may also find useful? Feel free to open a PR.

<!-- panvimdoc-ignore-end -->

## Neovim 0.7

The following features and fixes are not included in Neovim 0.7.

- [Command](#commands) modifiers (`:rightbel Outline`).
- Rename methods in golang from outline window
  ([#42](https://github.com/hedyhli/outline.nvim/issues/42))

## Limitations

### Preview window

Sometimes the preview window could be slow in loading. This could be due to the
code buffer being large. As of now there are no good solutions in circumventing
this problem — currently the entire code buffer is read, and then put into the
preview buffer. If only the required portion to preview is read and set
instead, there would be highlighting issues (say the calculated starting line
was within a markdown code block, so what was previously not supposed to be
code is now highlighted as code).

If this poses a problem for you, you should try out the
[live-preview](#live-editable-previews) feature, which uses the code buffer
directly for displaying the preview.

### Many outlines

Outline.nvim supports opening independent outline windows for different
tabpages, but does not support multiple outline windows in the same tabpage as
of now. However, this feature is
[planned](https://github.com/hedyhli/outline.nvim/issues/26). Alternatively, you
can use a single outline that auto-updates on buffer switches, which is turned
on by default.

## Related plugins

- [**Aerial.nvim**](https://github.com/stevearc/aerial.nvim)

  The most obvious plugin alternative to Outline.nvim would be Aerial. It
  provides an outline window with a lot of features that outline.nvim does not
  have (but might add in the future). That said, outline.nvim also has features
  that Aerial does not support. I do not find it productive to be listing out
  the exact details of which, as a table here, since both plugins are in active
  development and the table would get out of date quickly; Instead, I have
  listed a few example use-cases where you may want to use Aerial, and others
  Outline.nvim.

  Aerial does a great job at supercharging vim's built-in outline (`gO`). It
  supports treesitter which Outline.nvim does not provide [by
  default](#external-providers), but can be added an external provider. (Note
  that Aerial also supports Norg through treesitter like Outline.nvim, but as of
  writing it does not support JSX like Outline.nvim does.)

  - Aerial.nvim supports only Neovim 0.8 and above for the bleeding-edge
    features, as far as I know. You should use Outline.nvim (or the
    alternatives below) if you use Neovim 0.7 and wish to have equal support.
  - At the moment, integrations such as Telescope and statuslines in Outline.nvim
    has not been very well implemented yet, though they are planned features. If you
    wish to use this, you should use Aerial.
  - Outline.nvim supports both inclusive and exclusive symbol filtering.

  In addition to these, Aerial also supports a `AerialNav` window which gives
  you a miller column view of symbol hierarchy similar to
  [nvim-navbuddy](https://github.com/SmiteshP/nvim-navbuddy). This feature
  might never be supported in Outline.nvim because I personally feel that it is
  out of scope of a "outline window" plugin, and to keep the codebase simple.
  If you don't want to install a second plugin for this feature, you should use
  Aerial.

- [**nvim-navic**](https://github.com/SmiteshP/nvim-navic)

  nvim-navic gives you fully customizable breadcrumb section for you
  winbar/statusline. However, as far as I am aware it only supports LSP. To
  have other providers built-in you can try Aerial, or
  [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim).

- [**nvim-navbuddy**](https://github.com/SmiteshP/nvim-navbuddy)

  Miller columns popup for LSP navigation. Again as far as I know only LSP is
  supported.

- [**dropbar.nvim**](https://github.com/Bekaboo/dropbar.nvim)

  Clickable breadcrumbs section with support for many sources in addition to
  LSP. However, it requires Neovim nightly as of writing.

- [**lspsaga**](https://github.com/nvimdev/lspsaga.nvim)

  I've heard that this plugin gives you many features previously described all
  in one plugin. However I have not used this myself so I cannot comment on it
  more, other than it might only support LSP.

- [**glance.nvim**](https://github.com/DNLHC/glance.nvim)

  Extremely interesting plugin that gives you a floating window for navigation
  and quick-edits of locations provided by LSP. However it solves a different
  problem to Outline.nvim: navigating references and definitions.

- [**navigator.lua**](https://github.com/ray-x/navigator.lua)

  Unfortunately I have not used this myself, but it looks pretty good. It might
  only support LSP.

- **Treesitter (inspect/edit)**

  The built-in treesitter module has a `:InspectTree` feature that can follow
  your cursor around and let you jump to locations by navigating the tree.
  Compared to Outline.nvim it may not be as customizable, but it uses
  treesitter and can highlight entire ranges of symbols.

<hr>

If you've read this much, maybe you should subscribe to the [breaking changes
announcements](https://github.com/hedyhli/outline.nvim/issues/10) to get
updates when there are breaking changes. It's low-volume, I promise ;)
