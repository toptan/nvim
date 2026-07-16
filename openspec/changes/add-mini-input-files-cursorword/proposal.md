## Why

`mini.nvim` is already installed and configured for nine other modules
(`mini.completion`, `mini.pairs`, `mini.bracketed`, `mini.ai`, `mini.surround`, `mini.bufremove`,
`mini.notify`, `mini.trailspace`, `mini.clue`). Three more modules cover remaining gaps: no
consistent `vim.ui.input()` prompt styling (`mini.input`), no file explorer (`mini.files` — the
built-in netrw is unconfigured and unstyled), and no highlighting of other occurrences of the word
under the cursor (`mini.cursorword`). Adding them extends the existing `mini.nvim` dependency
rather than introducing new plugins. The colorscheme (`lua/retro/init.lua`) already defines
highlight groups for `MiniCursorword`/`MiniCursorwordCurrent` and the full `MiniFiles*` set, so
both light up correctly with no colorscheme changes needed.

## What Changes

- Add `mini.input`, called with `setup()` and no custom options. `setup()` itself sets
  `vim.ui.input = MiniInput.ui_input`, satisfying the ask to use it as the `vim.ui.input()`
  implementation — no separate wiring needed.
- Add `mini.cursorword`, called with `setup()` and no custom options (default 100ms highlight
  delay).
- Add `mini.files`, called with `setup()` and no custom options (default: `use_as_default_explorer
  = true`, so opening a directory path uses `mini.files` instead of netrw; `permanent_delete =
  true`, so in-explorer deletes bypass any trash/undo). Two new keymaps, both using `mini.files`'
  own documented toggle recipe (`if not MiniFiles.close() then MiniFiles.open(...) end`):
  - `-` toggles the explorer anchored on the current buffer's file (reveals it in the tree).
  - `<Leader>ed` toggles the explorer anchored on the current working directory (project root),
    under the existing (currently leaf-empty) `<Leader>e` "+Explore/Edit" group.

## Capabilities

- **New Capabilities**:
  - `ui-input` — `mini.input` as the `vim.ui.input()` implementation, default configuration.
  - `file-explorer` — `mini.files` default setup, plus `-`/`<Leader>ed` toggle keymaps.
  - `cursor-word-highlight` — `mini.cursorword` default setup.

## Impact

- Modified file: `plugin/60-mini.lua` (three new `setup()` calls, one shared toggle helper, two
  new keymaps).
- No `vim.pack.add` changes and no new `nvim-pack-lock.json` entry — `mini.nvim` is already
  declared.
- No colorscheme changes needed — `lua/retro/init.lua` already themes `MiniCursorword`/
  `MiniCursorwordCurrent` and the full `MiniFiles*` group set from when the colorscheme module was
  originally written.
- `-` (normally "move to first non-blank of previous line") is repurposed as the file-explorer
  toggle; `<Leader>ed` lands in a currently-unused leader slot. Neither shadows an existing mapping
  in this config.
- `mini.files`' default `use_as_default_explorer = true` and `permanent_delete = true` are kept as
  accepted upstream defaults — see `design.md` Risks.
