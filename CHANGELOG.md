# Changelog

## Main branch

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
  focus_outline = true/false })`.
- Config option for cursorline now supports 2 other string values,
  `focus_in_outline` and `focus_in_code`. These make the cursorline only show up
  depending on cursor focus. The first option, `focus_in_outline` makes it so
  cursorline is enabled only when focus is in outline. This lessens the visual
  changes due to `auto_set_cursor`, when focus is in code.
- Floating windows are now used for `show_help` keymap and `:OutlineStatus` command.
- `:OutlineStatus` command is now more informative.
- New command `:OutlineRefresh` and corresponding lua API function
  `refresh_outline()` triggers re-requesting of symbols from provider and
  updating the outline.
- New lua API function `is_focus_in_outline()`
- Auto-unfold root nodes when there is only N nodes. Where N defaults to 1
  (meaning when there is only 1 root node, keep it unfolded). The added config
  option is `symbol_folding.auto_unfold` with keys `hovered` and `only`.
  Key `hovered` is the successor of the legacy `symbol_folding.auto_unfold_hover`
  option. **The old option would still work as expected.**

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

### Performance

- Building of outline items (and details/lineno) parsed from symbol tree
  functions completely refactored, which reduced redundant code that could have
  O(N) time complexity, a significant difference for codebase with a lot of
  symbols.
- Follow cursor algorithm significantly improved
- Highlight hovered item and initial opening of outline has been rewritten and
  performance improved

### Others

- A [script](scripts/convert-symbols-outline-opts.lua) is added to convert
  symbols-outline.nvim config to outline.nvim config. Note that all config values
  are evaluated, so if the old config uses some external source and assigned it
  to a config key, the value from the external source would be used directly
  rather than the identifier.

## Older changes

Changes before fork detach can be found on [#12 on github](https://github.com/hedyhli/outline.nvim/issues/12)
