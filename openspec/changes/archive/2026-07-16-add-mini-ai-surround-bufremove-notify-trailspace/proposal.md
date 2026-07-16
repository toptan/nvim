## Why

`mini.nvim` is already installed (for `mini.completion`, `mini.pairs`, `mini.bracketed`,
`mini.clue`). Five more of its modules cover gaps in the current editing setup: no textobject
framework beyond Neovim's built-ins (`mini.ai`), no surround-editing operators (`mini.surround`),
no way to close a buffer without disturbing window layout (`mini.bufremove`), no managed
notification history/UI (`mini.notify`), and no trailing-whitespace highlighting/trimming
(`mini.trailspace`). Adding them extends the existing `mini.nvim` dependency rather than
introducing new plugins.

## What Changes

- Add `mini.ai`, configured with its default mappings (`a`/`i` prefixes, `an`/`in`/`al`/`il`
  next/last variants, `g[`/`g]` goto — see `design.md` §1 for the deliberate override of
  Neovim's built-in incremental-selection mappings of the same name), plus two custom
  treesitter-based textobjects, function (`f`) and class (`c`), sourced from the query files
  already shipped by the currently-unused `nvim-treesitter-textobjects` plugin dependency.
- Add `mini.surround`, called with `setup()` and no custom options — its default mappings
  (`sa`/`sd`/`sf`/`sF`/`sh`/`sr`, `l`/`n` suffixes) are used as-is.
- Add `mini.bufremove`, with two new keymaps under the existing (currently leaf-empty) `<Leader>b`
  "+Buffer" group: `<Leader>bd` deletes the current buffer while preserving window layout,
  `<Leader>bD` force-deletes it (discarding unsaved changes).
- Add `mini.notify`, wired as the `vim.notify` implementation (`vim.notify =
  require("mini.notify").make_notify()`), with a new `<Leader>on` keymap under the existing
  (currently leaf-empty) `<Leader>o` "+Other" group to show notification history.
- Add `mini.trailspace`, called with `setup()` and no custom options (default: highlight trailing
  whitespace in normal buffers only), with a new `<Leader>cw` keymap under the `<Leader>c` "+Code"
  group (alongside `<Leader>cf` format) to manually trim it.

## Capabilities

- **New Capabilities**:
  - `text-objects` — `mini.ai` default setup plus custom treesitter function/class textobjects.
  - `surround` — `mini.surround` default setup and mappings.
  - `buffer-removal` — `mini.bufremove` wired to `<Leader>bd`/`<Leader>bD`.
  - `notifications` — `mini.notify` as the `vim.notify` backend, plus `<Leader>on` history.
  - `trailing-whitespace` — `mini.trailspace` default highlighting, plus `<Leader>cw` manual trim.

## Impact

- Modified file: `plugin/60-mini.lua` (five new `setup()` calls/blocks, four new keymaps).
- No `vim.pack.add` changes and no new `nvim-pack-lock.json` entry — `mini.nvim` is already
  declared. `nvim-treesitter-textobjects` is also already declared (currently unused); this change
  is the first thing that reads its bundled query files.
- New keymaps land in currently-unused leader slots (`<Leader>bd`, `<Leader>bD`, `<Leader>on`,
  `<Leader>cw`) — no existing mapping is shadowed.
- `mini.surround`'s default `s`-prefixed mappings introduce a `timeoutlen` delay on the built-in
  bare `s` (substitute-char) command; `mini.ai`'s default `an`/`in`/`al`/`il` intentionally
  override Neovim's built-in incremental-selection mappings of the same name. Both are kept as
  upstream defaults per explicit approval — see `design.md` Risks.
