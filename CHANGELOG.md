# Changelog

<!--
### Breaking changes

### Features

### Fixes

### Performance

### Others
-->

## Main branch

### Features

- `OutlineOpen` without `!`, (and `outline.open`) will now focus in the outline if it is
  already open when invoked.
  ([#71](https://github.com/hedyhli/outline.nvim/issues/71))
- The `symbols.icon_fetcher` function now supports a second parameter, the code
  buffer number. Use it to fetch icons based on buffer options such as filetype.
- New config options `preview_window.height,min_height,relative_height` that
  match the existing options for width.
  ([#85](https://github.com/hedyhli/outline.nvim/pull/85))
- Mention new external providers for ctags and tree-sitter
  ([#103](https://github.com/hedyhli/outline.nvim/pull/103) and
  [#107](https://github.com/hedyhli/outline.nvim/pull/107))
- Support symbol kind of type string from providers
  ([#106](https://github.com/hedyhli/outline.nvim/pull/106))
- New provider for manpages
  ([#104](https://github.com/hedyhli/outline.nvim/pull/104))
- Give `symbols.icon_fetcher` a third parameter of type `outline.Symbol` to
  access extra information from provider.
  ([#109](https://github.com/hedyhli/outline.nvim/pull/109))

### Fixes

- Show `lspkind` errors just once on startup.
  ([#85](https://github.com/hedyhli/outline.nvim/pull/85))
- Allow the preview window's width and height adapt to nvim window's resize.
  ([#85](https://github.com/hedyhli/outline.nvim/pull/85))
- Keybinding to close the outline will exit neovim if it is the last window
  remaining; previously this threw an error.
  ([#91](https://github.com/hedyhli/outline.nvim/pull/91))
- Prevent an error on attempt to `goto_location` when code window is closed.
- Fix `hide_cursor`
  ([#100](https://github.com/hedyhli/outline.nvim/pull/100))
- Use `token.location.range` and `token.range` fallback when selection range is
  not provided.
  ([#105](https://github.com/hedyhli/outline.nvim/pull/105))

## v1.0.0

### Breaking changes

- Highlight for guides (previously `OutlineConnector` that covers both guides
  and fold markers) now split into `OutlineGuides` (covering from left edge until
  start of symbol icon) and `OutlineFoldMarker`.
- Config options `auto_goto -> auto_jump`, `keymaps.down/up_and_goto ->
  keymaps.down/up_and_jump`. The old names **still work as expected** but may be
  removed in feature releases (after v1.0.0).

### Features

- Config option for split command used in creating outline (`outline_window.split_command`)
- Added highlight group for fold marker
- A custom icon fetcher function can be used, which receives a kind as string and should
  return an icon as string. An empty string means no icon for this kind
- Lspkind is now supported as an icon source
- Outline open/toggle commands now support command modifiers to override the
  config options `position` and `split_command`. Eg: `:leftabove
  Outline`/`:belowright OutlineOpen!`
- Highlight group and duration of the 'flash' highlight on goto/jump operations
  can now be customized
  ([#27](https://github.com/hedyhli/outline.nvim/issues/27))
- A better config system for symbol filtering: deprecating `symbols.blacklist`
  config. Note that the old option **still works as expected** but may be
  deprecated in feature releases. This new `symbols.filter` option supports both
  inclusive filtering and also exclusive filtering, per-filetype filtering is
  also supported. ([#23](https://github.com/hedyhli/outline.nvim/issues/23))
- Optionally put cursor vertically centered on the screen after a goto/jump
  operation. Configurable via `outline_window.center_on_jump`
- By default, automatic following of cursor (and highlight hover) when outline
  is not in focus will now trigger on each `CursorMoved` event, rather than
  `CursorHold`. This is also configurable now using
  `outline_items.auto_update_events` with key `follow`. The key `items` controls
  the events that should trigger a re-request of symbols from the provider.
- On fold all or unfold all operations, the cursor will now stay on the same
  node, rather than the same line in the outline.
- Optionally not automatically update cursor position in outline to reflect
  cursor location in code. The auto-update is triggered by events from
  `outline_items.auto_update_events.follow` which controls both highlighting of
  hovered node and also setting of cursor in outline. To disable the latter,
  use `outline_items.auto_set_cursor`. Disabling the former can still be done using
  `outline_items.highlight_hovered_item`. Regardless, manual follow-cursor can
  still be done using `:FollowCursor[!]` or lua API `follow_cursor({
  focus_outline = true/false })`
- Config option for cursorline now supports 2 other string values,
  `focus_in_outline` and `focus_in_code`. These make the cursorline only show up
  depending on cursor focus. The first option, `focus_in_outline` makes it so
  cursorline is enabled only when focus is in outline. This lessens the visual
  changes due to `auto_set_cursor`, when focus is in code
- Floating windows are now used for `show_help` keymap and `:OutlineStatus` command
- `:OutlineStatus` command is now more informative (and prettier!)
- New command `:OutlineRefresh` and corresponding lua API function
  `refresh()` triggers re-requesting of symbols from provider and updating the
  outline
- New lua API function `has_focus()`
- Auto-unfold root nodes when there is only N nodes. Where N defaults to 1
  (meaning when there is only 1 root node, keep it unfolded). The added config
  option is `symbol_folding.auto_unfold` with keys `hovered` and `only`.
  Key `hovered` is the successor of the legacy `symbol_folding.auto_unfold_hover`
  option. **The old option would still work as expected.**
- Updated the default symbols icon highlights to not use highlight groups that
  start with `@`. Everything should still work as expected, most highlights
  should still be the same. This is to support `nvim-0.7`. The symbols icon
  highlights is still configurable as before
- Highlights used by outline.nvim are now set to default using links if they
  aren't already defined. Default winhl for outline window is now an empty
  string, and for preview window, `NormalFloat:` to ensure the preview window
  looks similar to a normal window (since it displays a preview of the actual
  code)
- Highlights will also take into account `ctermfg/bg` when setting default values.
  This ensures outline.nvim highlights work if `termguicolors` is not enabled
- A built-in provider for `norg` files that displays headings in the outline is now
  provided. This requires `norg` parser to be installed for treesitter
- Outline.nvim now supports per-tabpage outlines
  ([#37](https://github.com/hedyhli/outline.nvim/issues/37))
- Added `get_symbol` and `get_breadcrumb` functions (useful in
  statusline/winbar) ([#24](https://github.com/hedyhli/outline.nvim/issues/24))
- New "Live Preview" feature which allows editing in the preview buffer. This
  allows navigating some symbol away from cursor location and make quick edits in
  the other position using the preview window. This feature is currently
  experimental and opt-in. Enable with `preview_window.live = true`
- New outline window can be opened when no providers are found. A message is
  displayed in the outline buffer. Same goes for refreshing outline during buffer
  switches.
- Config option `autofold_depth = 1` is now the default. To restore previous
  behaviour set it to `false` (`nil` will NOT work). Reason being that it is
  rarely beneficial to show neighboring symbol locations (sometimes even same
  line!) when opening outline with the intention of getting an overall view of
  the file and jumping elsewhere.
- If auto-preview is enabled the preview window will automatically resize and
  reposition
- Each provider can now handle its own configuration via the
  `providers["provider-name"]` table. The first provider to make use of this will
  be the markdown provider, which looks at `providers.markdown.filetypes` for
  the list of filetypes to be supported for markdown outline symbols.
- The `outline_window.split_command` config now supports including width
  together with the command as supported by neovim. This removes a slight glitch
  on some machines when the outline is opened.
  ([#63](https://github.com/hedyhli/outline.nvim/issues/63))

### Fixes

- Don't auto-update cursor when focus is in outline
  ([#7](https://github.com/hedyhli/outline.nvim/issues/7))
- Symbol hover is not opened on preview open by default now
- Incorrect guide highlights
- Follow cursor can now put the cursor on the parent node if the child is
  folded and invisible in outline
- Follow cursor puts the cursor in the first column, and if there is lineno,
  puts it at the end of the lineno
- Markdown headings produced from the built-in markdown provider will now
  use the `String` kind, like marksman
- Preview window can now properly vertically center-align and determine its
  correct height depending on relative position of the outline window. Previously
  this did not work if there were horizontal splits below the outline window.
  This also adds a `preview_window.min_height` config option. The preview height
  is half of the outline height, unless smaller than `min_height`.
- No more obnoxious '}' on the cmdline when using `show_help` keymap. A
  floating window is used now.
  ([#19](https://github.com/hedyhli/outline.nvim/issues/19))
- Fixed display of JSX Fragments due to recent update from `javascript` TS
  parser
- Markdown parser included the next heading when setting the end range for
  previous heading. So when cursor was on the next heading, the previous heading
  would also be highlighted in the outline. This is now fixed, but marksman LSP
  would still do this. A "fix" is to add marksman into lsp client blacklist.
- Fix rename symbol (LSP) in golang methods. We now use `vim.lsp.buf.rename` to
  handle all the edge cases instead, for nvim-0.8 and above.
  ([#42](https://github.com/hedyhli/outline.nvim/issues/42))

### Performance

- Building of outline items (and details/lineno) parsed from symbol tree
  functions completely refactored, which reduced redundant code that could have
  O(N) time complexity, a significant difference for codebase with a lot of
  symbols.
- Follow cursor algorithm significantly improved
- Highlight hovered item and initial opening of outline has been rewritten and
  performance improved
- Revamped various provider-related modules such as rename/code-actions/hover
  to delegate the task to specific providers
- Revamped the preview module for better per-tab outline support and more features

### Others

- A [script](scripts/convert-symbols-outline-opts.lua) is added to convert
  symbols-outline.nvim config to outline.nvim config. Note that all config values
  are evaluated, so if the old config uses some external source and assigned it
  to a config key, the value from the external source would be used directly
  rather than the identifier.

## Older changes

Changes before fork detach can be found on [#12 on github](https://github.com/hedyhli/outline.nvim/issues/12)
