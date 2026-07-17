## Context

`plugin/60-mini.lua` currently ends with `mini.pick`'s `setup()` and seven keymaps
(`<Leader>ff`/`fg`/`fG`/`fb`/`fh`/`fr`/`fc`) for its builtin pickers, plus `mini.clue`. `mini.extra`
is a separate module inside the same `mini.nvim` plugin (`lua/mini/extra.lua`, read in full this
session) that adds 24 `MiniExtra.pickers.*` functions reusing `mini.pick`'s UI, plus two unrelated
generators (`gen_ai_spec`, `gen_highlighter`) that are out of scope here.

`Config.leader_group_clues` (`plugin/20-keymaps.lua`) already declares `<Leader>g` "+Git",
`<Leader>l` "+Language", and `<Leader>v` "+Visits" groups, none of which have any leaf keymaps
yet — `<Leader>g`/`<Leader>l` are this change's natural home; `<Leader>v` is reserved for a future
`mini.visits` addition (not this change). `<Leader>f` "+Find" already has seven leaves from
`mini.pick`.

Full inventory of `MiniExtra.pickers.*` (from `lua/mini/extra.lua`), grouped by what they need:

- **No extra dependency, single default call works**: `buf_lines`, `colorschemes`, `commands`,
  `diagnostic`, `explorer`, `git_branches`, `git_commits`, `git_files`, `git_hunks`, `history`,
  `hl_groups`, `keymaps`, `manpages`, `marks`, `oldfiles`, `options`, `registers`, `spellsuggest`,
  `treesitter` (19 total).
- **Requires an explicit `scope` argument, no sensible single default**: `list` (quickfix/
  location/jump/change — **excluded**, no quickfix/loclist workflow exists in this config to
  justify it) and `lsp` (8 scopes — **included**, all 8, see Decision 3).
- **Requires a `mini.*` module not installed in this config, errors otherwise**: `hipatterns`
  (needs `mini.hipatterns`), `visit_paths`/`visit_labels` (need `mini.visits`) — **excluded**.

Relevant per-picker defaults confirmed by reading `lua/mini/extra.lua` directly (not assumed):
`git_files` defaults `scope = 'tracked'` (`git ls-files --cached --exclude-standard`); `git_hunks`
defaults `scope = 'unstaged'`; `diagnostic`/`buf_lines`/`marks` default `scope = 'all'`; `history`
defaults `scope = 'all'`; `explorer` defaults `cwd = nil` → current working directory; `manpages`
needs the `:Man` command, confirmed present on this system
(`nvim --headless -c "lua print(vim.fn.exists(':Man'))"` → `2`).

`plugin/40-lsp.lua` sets no custom `gr*` keymaps — Neovim 0.11+'s built-in defaults are active
as-is: `grn` rename, `gra` code action, `grr` references, `gri` implementation, `gO` document
symbols (plus `i_CTRL-S` signature help). None of these are LSP-picker-related `mini.clue` groups
already in this config.

## Goals / Non-Goals

**Goals**

- Wire up every `mini.extra` picker that (a) needs no module this config doesn't already have and
  (b) has a sensible default call (or, for `lsp`, a fixed small set of explicit scopes) — 27
  keymaps total: 15 under `<Leader>f`, 4 under `<Leader>g`, 8 under `<Leader>l`.
- `require("mini.extra").setup()` with no options (its `config` table is `{}` upstream — no
  options to set).
- Every keymap calls its picker with no `local_opts` beyond what the picker needs by contract
  (only `lsp`'s required `scope`) — no customization of scope/filter/sort beyond upstream
  defaults.

**Non-Goals**

- `gen_ai_spec` / `gen_highlighter` — not pickers.
- `hipatterns`, `visit_paths`, `visit_labels` pickers — dependencies not installed.
- `list` picker — no existing quickfix/loclist workflow to justify it.
- No second keymap for `git_files`/`git_hunks`/`buf_lines`/`diagnostic`/etc. covering their
  non-default scopes (e.g. `git_files scope='modified'`, `git_hunks scope='staged'`,
  `diagnostic scope='current'`) — each `mini.extra` picker auto-registers with `mini.pick`'s
  `:Pick` user command (confirmed: every picker function is reachable as
  `:Pick <name> key=value ...`), so any non-default scope is one `:Pick` command away without a
  dedicated keymap. Matches this repo's "don't build for hypothetical future need" convention.
- No new `mini.clue` triggers — `<Leader>g` and `<Leader>l` are already listed in
  `Config.leader_group_clues` and already covered by the existing generic
  `{ mode = "n"/"x", keys = "<Leader>" }` triggers in `plugin/60-mini.lua`'s `mini.clue.setup()`.
- No replacement of any existing `gr*` LSP keymap — the 8 new `<Leader>l*` keymaps are additive.

## Decisions

### 1. `require("mini.extra").setup()` placement and the 19 general/Git keymaps

```lua
-- See also:
-- - `:h mini.extra`
require("mini.extra").setup()

vim.keymap.set("n", "<Leader>fd", function()
  require("mini.extra").pickers.diagnostic()
end, { desc = "Diagnostics" })

vim.keymap.set("n", "<Leader>fe", function()
  require("mini.extra").pickers.explorer()
end, { desc = "File explorer (picker)" })

-- ... one closure per remaining <Leader>f/<Leader>g keymap, same shape ...
```

Placed immediately after the existing `mini.pick` block (same file, same lazy-`require`-inside-
the-closure style as every existing `mini.pick`/`mini.bufremove`/`mini.notify`/`mini.trailspace`/
`mini.files` keymap in this file) — `mini.extra`'s pickers call into `mini.pick` internally, so
`mini.pick.setup()` must run first, which the existing block ordering already guarantees.

`<Leader>fe` (`explorer`) is a distinct picker-style file browser (flat picker list, `..`-style
directory navigation via `choose`) from `mini.files`' `-`/`<Leader>ed` split-pane tree explorer —
kept as a separate keymap rather than replacing either; they serve different workflows (fast
fuzzy-jump vs. tree browsing/renaming/creating files).

Full 15-keymap `<Leader>f` table (picker → key → one-line desc):

| Picker | Key | Desc |
|---|---|---|
| `diagnostic` | `fd` | Diagnostics |
| `explorer` | `fe` | File explorer (picker) |
| `keymaps` | `fk` | Keymaps |
| `buf_lines` | `fl` | Buffer lines |
| `manpages` | `fm` | Manpages |
| `marks` | `fM` | Marks |
| `oldfiles` | `fo` | Old files |
| `options` | `fO` | Options |
| `registers` | `fR` | Registers |
| `spellsuggest` | `fs` | Spelling suggestions |
| `colorschemes` | `fT` | Colorschemes |
| `hl_groups` | `fx` | Highlight groups |
| `history` | `fy` | Command/search history |
| `commands` | `fC` | Commands |
| `treesitter` | `ft` | Treesitter nodes |

Full 4-keymap `<Leader>g` table:

| Picker | Key | Desc |
|---|---|---|
| `git_branches` | `gb` | Git branches |
| `git_commits` | `gc` | Git commits |
| `git_files` | `gf` | Git files (tracked) |
| `git_hunks` | `gh` | Git hunks (unstaged) |

**Collision check** (every key checked against every existing keymap in `plugin/20-keymaps.lua`,
`plugin/40-lsp.lua`, `plugin/60-mini.lua` as of this change): `<Leader>f` group existing leaves are
exactly `f`/`g`/`G`/`b`/`h`/`r`/`c` — none of the 15 new letters (`d`/`e`/`k`/`l`/`m`/`M`/`o`/`O`/
`R`/`s`/`T`/`x`/`y`/`C`/`t`) match any of those seven. `<Leader>g` and `<Leader>l` currently have
zero leaf keymaps, so their new letters can't collide with anything.

**Alternative considered**: put every new picker under `<Leader>f` (one big Find group, mirroring
how all seven `mini.pick` builtins already live there). Rejected per explicit user choice — Git
and LSP pickers map cleanly onto the `<Leader>g`/`<Leader>l` groups this config already declares
in `Config.leader_group_clues` but never populated, keeping `<Leader>f` from growing to ~22
entries and keeping git/LSP actions discoverable under their own themed prefix.

### 2. Letter assignment scheme within `<Leader>f`

Where a picker's first letter was already taken by an existing `mini.pick` keymap (`f` files,
`g`/`G` grep, `b` buffers, `h` help, `r` resume, `c` cli), an uppercase variant or a secondary
mnemonic letter was used instead — same pattern this config already established with
`fg`/`fG` (live vs. prompted grep). E.g. `manpages` takes lowercase `fm`; `marks` (also starting
with "m") takes uppercase `fM`. `oldfiles`/`options` similarly split lowercase/uppercase `fo`/`fO`.
`registers` couldn't take `fr` (already `resume`), so uppercase `fR`. No alternative considered in
detail beyond this — the specific letters are the part most open to the user's preference and are
called out explicitly for review before implementation.

### 3. `lsp` picker: all 8 scopes, additive to existing `gr*` defaults

```lua
vim.keymap.set("n", "<Leader>ld", function()
  require("mini.extra").pickers.lsp({ scope = "declaration" })
end, { desc = "LSP declaration" })

vim.keymap.set("n", "<Leader>lD", function()
  require("mini.extra").pickers.lsp({ scope = "definition" })
end, { desc = "LSP definition" })

vim.keymap.set("n", "<Leader>lo", function()
  require("mini.extra").pickers.lsp({ scope = "document_symbol" })
end, { desc = "LSP document symbols (outline)" })

vim.keymap.set("n", "<Leader>li", function()
  require("mini.extra").pickers.lsp({ scope = "implementation" })
end, { desc = "LSP implementation" })

vim.keymap.set("n", "<Leader>lr", function()
  require("mini.extra").pickers.lsp({ scope = "references" })
end, { desc = "LSP references" })

vim.keymap.set("n", "<Leader>lt", function()
  require("mini.extra").pickers.lsp({ scope = "type_definition" })
end, { desc = "LSP type definition" })

vim.keymap.set("n", "<Leader>lw", function()
  require("mini.extra").pickers.lsp({ scope = "workspace_symbol" })
end, { desc = "LSP workspace symbols" })

vim.keymap.set("n", "<Leader>lW", function()
  require("mini.extra").pickers.lsp({ scope = "workspace_symbol_live" })
end, { desc = "LSP workspace symbols (live)" })
```

User explicitly chose to map all 8 scopes even though `references`/`implementation`/
`document_symbol` already have built-in default keymaps (`grr`/`gri`/`gO`) — the new keymaps are a
different UI (a filterable `mini.pick` list) over the same LSP methods, not a replacement.
`declaration`/`type_definition`/`workspace_symbol`/`workspace_symbol_live` have **no** existing
default keymap in this config, so those four are net-new capability, not just a UI alternative.

Per `mini.extra`'s own doc comment, the `lsp` picker "doesn't return anything due to async nature
of `vim.lsp.buf` methods", and for `references`/`workspace_symbol`/`workspace_symbol_live` it
calls `vim.lsp.buf[scope](...)` directly rather than unconditionally opening a `mini.pick` window —
a `mini.pick` picker only appears if the LSP server returns a *list* of locations/symbols (per
`vim.lsp.LocationOpts.OnList` semantics); a single unambiguous result still jumps straight there,
same as the native `gr*` keymaps. This affects manual verification (`tasks.md` §4): confirming
these keymaps requires a codebase with multiple matching locations/symbols to actually observe a
picker window, not just any LSP-attached buffer.

**Alternative considered**: only map the four scopes with no existing default (`declaration`,
`type_definition`, `workspace_symbol`, `workspace_symbol_live`), leaving `references`/
`implementation`/`document_symbol` to their native `gr*`/`gO` keymaps only. Rejected per explicit
user choice in favor of full coverage — user wants the picker UI available for every LSP scope
`mini.extra` supports, even where a jump-first alternative already exists.

## Risks / Trade-offs

- **`fuzzy-finder` capability doesn't exist in `openspec/specs/` yet.** The change that introduces
  it (`add-mini-indentscope-statusline-pick`) is fully implemented in code (commit `66cf77d`) but
  not yet archived/synced — `openspec/specs/` has no `fuzzy-finder` directory today. This change's
  delta spec (`specs/fuzzy-finder/spec.md`) is therefore written as **ADDED Requirements** (as if
  introducing the capability fresh), even though it only makes sense layered on top of that other
  change's own ADDED requirements for the plain `mini.pick` builtins. **Whichever of the two
  changes gets archived first will sync cleanly; the second archival will need a manual merge**
  (combine both changes' ADDED requirements into one `fuzzy-finder/spec.md` rather than the second
  silently overwriting the first). Flagged here, not resolved — resolving the other change's
  archive status is out of scope for this proposal.
- **27 new keymaps is a lot to review at once.** Mitigated by grouping them into three small
  tables above (design.md Decision 1) rather than one long list, and by calling out explicitly
  that individual letters (Decision 2) are the most negotiable part if the user wants different
  mnemonics.
- **Two file-exploration UIs now exist** (`mini.files` tree explorer at `-`/`<Leader>ed`, and
  `mini.extra`'s `explorer` picker at `<Leader>fe`). Accepted — they're genuinely different
  interaction models (tree browse-and-edit vs. fuzzy-jump list), matching the precedent that
  `<Leader>ff` (picker "find files") and `<Leader>ed` (tree "explore directory") already coexist
  today for a similar reason.
- **`git_*` pickers assume a Git repository.** `H.validate_git(...)` errors clearly if the current
  directory isn't inside one (confirmed by reading the source: raises via `H.error` before
  spawning `git`) — acceptable, same class of environment-dependent behavior already accepted for
  `mini.pick`'s own `grep`/`files` git-vs-fallback logic.

## Open Questions

None — placement grouping, `lsp` picker scope coverage, and exclusion of the `list` picker were
each explicitly decided with the user via `AskUserQuestion` before this design was written. The
individual per-picker letter assignments (Decision 2) are the one area still open for the user's
requested review before implementation, per their ask to "approve any additional keybindings."
