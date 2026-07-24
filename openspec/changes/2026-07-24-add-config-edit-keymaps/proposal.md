## Why

Editing this config currently means either browsing to it with the generic `<Leader>ed` (explore
cwd) toggle, or `:edit`-ing a path by hand. There's no quick way to jump straight to the config
directory or to any one of the eight files that make up this Neovim config. The (currently
leaf-empty apart from `<Leader>ed`) `<Leader>e` "+Explore/Edit" group is the natural home for this:
one leaf to explore the config directory, and one leaf per file to edit it directly.

## What Changes

- Add `<Leader>ec`, in `plugin/60-mini.lua` alongside the existing `<Leader>ed` toggle: opens
  `mini.files` anchored on `vim.fn.stdpath("config")` (this Neovim config directory), using the
  same shared `toggle_files()` recipe as `-`/`<Leader>ed`.
- Add seven quick-edit keymaps in `plugin/20-keymaps.lua`, one per config entry point, each a plain
  `vim.cmd.edit(vim.fn.stdpath("config") .. "/<path>")` call. The leaf key is the first letter of
  the file's name once its numeric `plugin/NN-` prefix is stripped:
  - `<Leader>ei` → `init.lua`
  - `<Leader>eo` → `plugin/10-options.lua`
  - `<Leader>ek` → `plugin/20-keymaps.lua`
  - `<Leader>ea` → `plugin/30-autocmds.lua`
  - `<Leader>el` → `plugin/40-lsp.lua`
  - `<Leader>ep` → `plugin/50-plugins.lua`
  - `<Leader>em` → `plugin/60-mini.lua`

## Capabilities

- **Modified Capabilities**:
  - `keymaps` — seven new `<Leader>e{i,o,k,a,l,p,m}` quick-edit keymaps for this config's own
    files, defined in `plugin/20-keymaps.lua`.
  - `file-explorer` — one new `<Leader>ec` toggle keymap (explorer anchored on the Neovim config
    directory), defined in `plugin/60-mini.lua` alongside the existing `mini.files` toggles.

## Impact

- Modified file: `plugin/20-keymaps.lua` (seven new keymaps, one shared `edit_config_file()`
  helper).
- Modified file: `plugin/60-mini.lua` (one new keymap, reusing the existing `toggle_files()`
  helper — no new helper needed).
- Modified file: `CLAUDE.md` (load-order section: mention the new keymaps under both
  `plugin/20-keymaps.lua` and `plugin/60-mini.lua` bullets).
- No `vim.pack.add`/`nvim-pack-lock.json` changes — no new plugins, only new keymaps on top of
  already-configured `mini.files`.
- No collisions: `<Leader>e{c,i,o,k,a,l,p,m}` are all previously-unused leaves under the `<Leader>e`
  group (only `<Leader>ed` was taken).
