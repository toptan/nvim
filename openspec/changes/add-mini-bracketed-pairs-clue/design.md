## Context

`plugin/60-mini.lua` currently only configures `mini.completion`, with four insert-mode
expr-mappings (`<Tab>`, `<S-Tab>`, `<CR>`, `<Esc>`) branching on `vim.fn.pumvisible()`.
`plugin/20-keymaps.lua` defines:

```lua
Config.leader_group_clues = {
  { mode = "n", keys = "<Leader>b", desc = "+Buffer" },
  ...
  { mode = "x", keys = "<Leader>g", desc = "+Git" },
  { mode = "x", keys = "<Leader>l", desc = "+Language" },
}
```

This is already exactly the shape `mini.clue` expects for its `clues` config entries (group
descriptions keyed by `mode`/`keys`/`desc`), which is why the `keymaps` spec already frames it as
built "for consumption by a which-key-style UI plugin" — this change is that plugin.

Relevant default configs (for reference):

```lua
-- mini.pairs
{
  modes = { insert = true, command = false, terminal = false },
  mappings = {
    ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
    [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
    ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
    [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
    ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },
    ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
    ['"']  = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
    ["'"]  = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
    ['`']  = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
  },
}
```
Bracket-pair entries (`(`, `[`, `{`) register global smart `<BS>` (delete an adjacent empty pair
as one unit) and `<CR>` (split an adjacent empty pair across two lines, indenting between)
mappings by default; quote entries opt out of the `<CR>` registration. `MiniPairs.cr()` and
`MiniPairs.bs()` are public functions specifically documented for composing with another plugin
that also wants `<CR>`/`<BS>` (e.g. a completion plugin) — this is the intended integration point,
not a workaround.

```lua
-- mini.bracketed: default `suffix` covers buffer/comment/conflict/diagnostic/file/indent/jump/
-- location/oldfile/quickfix/treesitter/undo/window/yank, each as `[x`/`]x` (previous/next) with
-- an uppercase variant (`[X`/`]X`) for first/last, in Normal, Visual and Operator-pending modes.
```

```lua
-- mini.clue
{
  triggers = {},   -- empty by default: every trigger must be configured explicitly
  clues = {},
  window = { delay = 1000, config = {}, ... },
}
```
`mini.clue` maps only the trigger key itself (e.g. bare `<Leader>`); it then reads further keys
one at a time and re-dispatches the accumulated sequence, showing the popup only after
`window.delay` ms of hesitation. It does not create or shadow mappings for the deeper sequences
(`<Leader>b`, `<Leader>bd`, ...), so it composes with whatever those already do.

`mini.clue` ships `MiniClue.gen_clues`, generator functions that return ready-made `clues` arrays
for common built-in prefixes: `g()`, `z()`, `marks()`, `registers()`, `windows()`, and
`builtin_completion()` (the last covers `<C-r>` in insert/cmdline as well as `i_CTRL-X` submodes).
Its own documented example config combines these generators with hand-authored entries in the same
flat `clues` list, e.g.:

```lua
clues = {
  { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
  require('mini.clue').gen_clues.g(),
  require('mini.clue').gen_clues.marks(),
  require('mini.clue').gen_clues.registers(),
  require('mini.clue').gen_clues.windows(),
  require('mini.clue').gen_clues.z(),
},
```
`clues` entries and generator-returned sub-arrays can be mixed directly in the outer list —
`mini.clue` flattens it internally. There is no equivalent generator for `mini.bracketed`; for a
prefix with no `clues` entries at all, `mini.clue`'s popup falls back to each leaf mapping's own
`desc` (set via `vim.keymap.set`'s `opts.desc`), which `mini.bracketed`'s default mappings already
provide.

## Goals / Non-Goals

**Goals**
- `mini.pairs` and `mini.bracketed`: zero custom configuration, defaults only.
- `mini.clue`: popup triggered by `<Leader>` in normal and visual mode, showing the groups already
  described in `Config.leader_group_clues`, sourced from that table directly (not a duplicated
  copy).
- `mini.clue`: also trigger on the standard built-in prefixes `mini.clue` ships generators for
  (`g`, `z`, marks, registers, windows) and on `[`/`]` for `mini.bracketed`'s own groups.
- Preserve `mini.pairs`' default smart-`<CR>` behavior alongside the existing
  `mini.completion`-driven `<CR>` mapping, rather than letting one silently clobber the other.

**Non-Goals**
- No `mini.clue` triggers beyond the set above — no operator-mode-specific triggers, no
  `builtin_completion()`-only submodes beyond `<C-r>`, no third-party plugin-specific clue tables.
- No hand-authored clue descriptions for `[`/`]` — relies entirely on `mini.bracketed`'s own
  mapping `desc`s (see Context).
- No per-mapping customization of `mini.pairs` (e.g. filetype-specific pair overrides) or
  `mini.bracketed` (e.g. trimming which suffixes are enabled).
- No change to `mini.clue`'s default `window` styling/delay.

## Decisions

### 1. `mini.pairs` and `mini.bracketed`: call `setup()` with no arguments
```lua
require("mini.bracketed").setup()
require("mini.pairs").setup()
```
Matches the user's ask directly and mini.nvim's own documented "just call setup()" usage for
default behavior.

### 2. `mini.clue`: Leader clues from `Config.leader_group_clues`, the rest from built-in generators
```lua
local miniclue = require("mini.clue")
miniclue.setup({
  triggers = {
    { mode = "n", keys = "<Leader>" },
    { mode = "x", keys = "<Leader>" },

    { mode = "n", keys = "g" },
    { mode = "x", keys = "g" },

    { mode = "n", keys = "z" },
    { mode = "x", keys = "z" },

    { mode = "n", keys = "'" },
    { mode = "n", keys = "`" },
    { mode = "x", keys = "'" },
    { mode = "x", keys = "`" },

    { mode = "n", keys = '"' },
    { mode = "x", keys = '"' },
    { mode = "i", keys = "<C-r>" },
    { mode = "c", keys = "<C-r>" },

    { mode = "n", keys = "<C-w>" },

    { mode = "n", keys = "[" },
    { mode = "x", keys = "[" },
    { mode = "n", keys = "]" },
    { mode = "x", keys = "]" },
  },

  clues = {
    Config.leader_group_clues,
    miniclue.gen_clues.g(),
    miniclue.gen_clues.z(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.builtin_completion(),
  },
})
```
No `clues` entries are added for `[`/`]` — see Context for why that's fine (falls back to
`mini.bracketed`'s own mapping `desc`s).

**Alternative considered**: copy `Config.leader_group_clues`'s entries into a separate
`mini.clue`-specific table. Rejected — the whole point of that table (per `CLAUDE.md` and the
`keymaps` spec) is to be the single source of truth for leader-group descriptions; a second copy
would drift as groups are added/renamed.

**Alternative considered**: derive the `triggers` list programmatically from the distinct
`mode`s present in `Config.leader_group_clues`, instead of hardcoding the two `{mode, "<Leader>"}`
entries. Rejected as unnecessary indirection for two static entries — flagged under Risks below in
case a third mode is ever added to that table.

**Alternative considered**: also add a hand-authored `clues` table for `mini.bracketed`'s `[`/`]`
groups (one entry per suffix/direction, e.g. `{ mode = 'n', keys = '[b', desc = 'Buffer (prev)' }`).
Rejected — `mini.bracketed` already sets a `desc` on every mapping it creates, so authoring a
parallel table would duplicate that metadata and risk drifting from the actual suffix list (14
targets × prev/next × first/last × normal/visual — a lot of surface to keep in sync by hand for no
behavioral gain).

**Alternative considered**: skip `builtin_completion()`/`<C-r>` since it's arguably a stretch
beyond "the standard set". Kept in — it's one of `mini.clue`'s own documented example-config
generators and directly useful (register preview when pasting in insert/cmdline mode), and adding
its one trigger pair costs nothing extra.

### 3. Compose `mini.pairs`' smart `<CR>` into the existing completion `<CR>` mapping
Current (`mini.completion`-only) mapping:
```lua
imap("<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "<C-y>"
  end
  return "<CR>"
end)
```
Changes to:
```lua
imap("<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "<C-y>"
  end
  return require("mini.pairs").cr()
end)
```
`MiniPairs.cr()` itself falls back to a plain `<CR>` when the cursor isn't inside an empty
registered pair, so this is a strict superset of the previous behavior, not a narrowing.

**Alternative considered**: let `mini.pairs.setup()` register its own global `<CR>` and leave the
existing mapping as the last one defined (so it silently wins, discarding `mini.pairs`' smart-CR
entirely). Rejected — that would make "default configuration is good enough" for `mini.pairs`
false in practice, since its most-visible feature (Enter-inside-`()`  to split across lines) would
silently never fire.

**Alternative considered**: let `mini.pairs.setup()` run *after* the completion block and win
outright (opposite order). Rejected — that would drop `mini.completion`'s own `<CR>`-confirms
behavior instead, which is the core interaction this config already relies on.

`<BS>` is left untouched: no existing `<BS>` mapping exists in this config, so `mini.pairs`'
default global `<BS>` registration applies without needing any composition.

## Risks / Trade-offs

- **Hardcoded `<Leader>` triggers instead of deriving from `Config.leader_group_clues`'s modes** →
  if a future change adds a `leader_group_clues` entry with a third mode (e.g. operator-pending),
  the `mini.clue` popup wouldn't trigger for it until `triggers` is updated by hand. Mitigation:
  low likelihood (only `n`/`x` used today, matching how leader keymaps are actually bound), and
  cheap to fix when it happens.
- **`<CR>` composition depends on `mini.pairs.cr()`'s existing fallback-to-plain-`<CR>` behavior**
  → if a future `mini.nvim` update changes what `MiniPairs.cr()` returns when no pair applies, the
  non-completion `<CR>` behavior in this config would inherit that change silently. Mitigation:
  covered by the manual verification step in `tasks.md` (plain `<CR>` outside any pair, and outside
  any completion popup, must still just insert a newline).
- **`[`/`]` popups depend on `mini.bracketed` setting `desc` on its own mappings** → if a future
  `mini.bracketed` update stops setting `desc` (or changes its wording) on its default mappings,
  the bracket-prefix popup would show blank/raw-key entries instead of descriptive ones, with no
  local fallback text to catch it. Mitigation: covered by the manual verification step in
  `tasks.md` (confirm the `[`/`]` popup actually shows non-empty descriptions, not just that it
  opens).
- **`gen_clues.g()`/`.z()` cover only `mini.nvim`'s own idea of "common" `g`/`z` mappings** → some
  built-in or other-plugin `g`-/`z`-prefixed commands not known to `mini.clue` will show in the
  popup with no description (falling back to raw keys), same as any unmapped-`desc` leaf.
  Mitigation: none needed — this is strictly additive over having no popup at all for these
  prefixes.

## Open Questions

- None — mini.pairs/mini.bracketed per-mapping customization remains explicitly out of scope and
  can be proposed as a separate change if wanted later.
