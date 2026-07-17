## Why

`mini.nvim` is already installed (for `mini.completion`), and `plugin/20-keymaps.lua` already
defines `Config.leader_group_clues` — a table describing each `<Leader>` prefix group — explicitly
"for consumption by a which-key-style UI plugin" (per the `keymaps` spec), but no such plugin is
configured yet, so it's currently read by nothing. Separately, the editor has no auto-pairing of
brackets/quotes and no `[`/`]` bracket-navigation mappings. `mini.nvim` ships modules for all
three (`mini.clue`, `mini.pairs`, `mini.bracketed`), so this change adds them without introducing a
new plugin dependency.

## What Changes

- Add `mini.bracketed` and `mini.pairs`, both via `require(...).setup()` with no custom options —
  the defaults cover the desired behavior (bracket/quote auto-pairing with smart skip-over and
  empty-pair backspace/enter handling; `[x`/`]x` navigation across buffers, comments, diagnostics,
  files, jumps, oldfiles, quickfix/location lists, treesitter nodes, undo states, windows, and
  yanks).
- Add `mini.clue`, configured (not defaults) in `plugin/60-mini.lua`:
  - `triggers`: `<Leader>` in normal and visual mode — the two modes already present in
    `Config.leader_group_clues` — plus a standard set of built-in prefixes: `g` and `z` (normal,
    visual), marks (`'`/`` ` ``, normal, visual), registers (`"`, normal/visual; `<C-r>`,
    insert/cmdline), windows (`<C-w>`, normal), and `[`/`]` (normal, visual) for `mini.bracketed`'s
    groups.
  - `clues`: `Config.leader_group_clues` for the Leader groups (its `{mode, keys, desc}` shape
    already matches what `mini.clue` expects), plus `mini.clue`'s own built-in `gen_clues`
    generators (`g()`, `z()`, `marks()`, `registers()`, `windows()`, `builtin_completion()`) for
    the rest. `[`/`]` get no hand-authored clue entries — `mini.clue` has no generator for
    `mini.bracketed`, so that popup relies on the `desc` `mini.bracketed`'s own mappings already
    set.
- **Modify** the existing insert-mode `<CR>` mapping in `plugin/60-mini.lua` (added for
  `mini.completion`): its non-popup-confirm fallback currently returns a literal `"<CR>"`.
  `mini.pairs` registers its own global smart `<CR>` (splits an adjacent empty bracket pair across
  lines) by default, which would otherwise be silently overridden by the plain `<CR>` fallback.
  The fallback branch changes to call `MiniPairs.cr()` instead, so both behaviors compose: a
  selected completion candidate still confirms as before, and otherwise `<CR>` gets `mini.pairs`'
  smart behavior instead of a bare newline.

## Capabilities

- **New Capabilities**:
  - `auto-pairs` — `mini.pairs` default setup and behavior.
  - `bracket-navigation` — `mini.bracketed` default setup and behavior.
  - `keybinding-clues` — `mini.clue` setup: its `<Leader>` triggers and use of
    `Config.leader_group_clues`, its standard built-in-generator triggers (`g`, `z`, marks,
    registers, windows), and its `[`/`]` triggers for `mini.bracketed`.
- **Modified Capabilities**:
  - `keymaps` — the "Leader group descriptions" requirement's scenario changes from a hypothetical
    "which-key-style UI plugin" to naming `mini.clue` as the concrete consumer.
  - `completion` — the "Confirmation with Enter" requirement's "no item selected" scenario changes
    from "a normal line break is inserted" to "the key falls through to `mini.pairs`' smart `<CR>`
    handling (which itself falls back to a normal line break when no pair applies)".

## Impact

- Modified file: `plugin/60-mini.lua` (three new `setup()` calls, one modified `<CR>` fallback).
- No `vim.pack.add` changes and no new `nvim-pack-lock.json` entry — `mini.nvim` is already
  declared.
- No conflicts with existing keymaps: `mini.bracketed`'s default mappings all use an unmapped
  `[`/`]` + suffix-letter combination; `mini.pairs`' default mappings are insert-mode
  bracket/quote characters and (as covered above) `<BS>`/`<CR>`, of which only `<CR>` was already
  mapped; none of `mini.clue`'s trigger keys (`<Leader>`, `g`, `z`, `'`, `` ` ``, `"`, `<C-w>`,
  `<C-r>`, `[`, `]`) are currently mapped bare (unprefixed) anywhere in this config — `mini.clue`
  only intercepts the trigger key itself, dispatching the full sequence exactly as before once
  typed, so existing multi-key commands built on these prefixes (e.g. `gg`, `zt`, `<Leader>tf`)
  are unaffected.
