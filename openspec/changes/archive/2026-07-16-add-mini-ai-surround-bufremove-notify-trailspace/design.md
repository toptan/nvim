## Context

`plugin/60-mini.lua` currently configures `mini.completion`, `mini.pairs`, `mini.bracketed`, and
`mini.clue`. `plugin/20-keymaps.lua` defines `Config.leader_group_clues`, including `b` "+Buffer"
and `o` "+Other" groups that currently have no leaf keymaps under them, and `c` "+Code" which has
only `<Leader>cf` (format, via `conform.nvim`).

`nvim-treesitter-textobjects` is already declared in `plugin/50-plugins.lua` (added alongside
`nvim-treesitter`) but nothing in the config currently calls its Lua API or reads its query files —
it is a dead dependency today. It ships per-language `queries/<lang>/textobjects.scm` files
defining captures like `@function.outer`/`@function.inner` and `@class.outer`/`@class.inner`.
`MiniAi.gen_spec.treesitter()` reads exactly this kind of query (via `vim.treesitter.query.get`,
using Neovim's builtin query runtime path lookup, not `nvim-treesitter-textobjects`'s own Lua
module) to build custom textobjects. This means `mini.ai` can consume that plugin's query files
directly without configuring its Lua-side move/select keymaps at all.

Relevant default configs (for reference; full listings are in each module's source under
`mini.nvim`'s own `lua/mini/*.lua`):

```lua
-- mini.ai
mappings = {
  around = 'a', inside = 'i',
  around_next = 'an', inside_next = 'in',   -- overrides Neovim>=0.12 built-in v_an/v_in
  around_last = 'al', inside_last = 'il',   -- overrides Neovim>=0.13 built-in al/il
  goto_left = 'g[', goto_right = 'g]',
}
```
`mini.ai`'s own docs (`:h MiniAi-default-an-in`) describe the `an`/`in`/`al`/`il` override as
deliberate, for usability/backwards-compatibility, and document three ways to avoid it (remap
Neovim's own `an`/`in` first, use `gen_spec.treesitter()` for next/last-like behavior, or rename
`mini.ai`'s mappings to e.g. `aN`/`iN`/`aL`/`iL`).

```lua
-- mini.surround
mappings = {
  add = 'sa', delete = 'sd', find = 'sf', find_left = 'sF',
  highlight = 'sh', replace = 'sr',
  suffix_last = 'l', suffix_next = 'n',
}
```
All surround mappings are two-key sequences beginning with a bare `s`, which is also Neovim's
built-in substitute-character command.

```lua
-- mini.bufremove
-- No default mappings at all; `MiniBufremove.delete(buf_id, force)` and
-- `MiniBufremove.unshow`/`.wipeout` are library functions the user maps themselves.
```

```lua
-- mini.notify
lsp_progress = { enable = true, level = 'INFO', duration_last = 1000 }
-- No default mappings; `MiniNotify.make_notify()` and `.show_history()` are library functions.
```

```lua
-- mini.trailspace
only_in_normal_buffers = true
-- No default mappings; `MiniTrailspace.trim()` is a library function.
```

## Goals / Non-Goals

**Goals**
- `mini.surround`: zero custom configuration, upstream defaults only (explicit user instruction).
- `mini.ai`: upstream default mappings, plus `custom_textobjects` for function (`f`) and class
  (`c`) via `gen_spec.treesitter()`, reusing `nvim-treesitter-textobjects`'s bundled query files.
- `mini.bufremove`: `<Leader>bd` (delete, preserve window) / `<Leader>bD` (force delete) under the
  existing `<Leader>b` group.
- `mini.notify`: becomes the `vim.notify` backend; `<Leader>on` shows notification history under
  the existing `<Leader>o` group.
- `mini.trailspace`: upstream default highlighting; `<Leader>cw` manually trims trailing
  whitespace, under the existing `<Leader>c` group.

**Non-Goals**
- No new `mini.clue` triggers for `s` (surround) or `a`/`i` (textobjects) — keeps the trigger set
  intentionally minimal, per the precedent set when `mini.clue` was first configured.
- No custom `mini.ai` textobjects beyond function/class (no call, loop, or comment captures).
- No `mini.surround` remap away from its `s`-prefixed defaults — the delay on bare `s` is an
  accepted trade-off (explicit user instruction; see Risks).
- No `mini.ai` remap of `an`/`in`/`al`/`il` — the override of Neovim's built-in incremental
  selection is an accepted trade-off (explicit user decision; see Risks).
- No `mini.bufremove` keymaps for `unshow`/`wipeout` — only delete/force-delete.
- No `mini.notify` customization of `content.format`/`content.sort`/`window`, and
  `lsp_progress.enable` stays at its default (`true`).
- No auto-trim-on-save for `mini.trailspace` — trimming stays a deliberate, manual action.
- No configuration of `nvim-treesitter-textobjects`'s own Lua module/keymaps — only its bundled
  query files are consumed, via `mini.ai`.

## Decisions

### 1. `mini.ai`: defaults + treesitter function/class textobjects, pcall-wrapped

```lua
local function treesitter_textobject(captures)
  -- `gen_spec.treesitter()` errors (rather than reporting "no match") when the buffer's
  -- language has no parser or no `textobjects.scm` query defining the requested captures.
  -- Swallow that so `af`/`if`/`ac`/`ic` degrade to "nothing found" on unsupported filetypes.
  local spec = require("mini.ai").gen_spec.treesitter(captures)
  return function(...)
    local ok, res = pcall(spec, ...)
    if not ok then
      return {}
    end
    return res
  end
end

require("mini.ai").setup({
  custom_textobjects = {
    f = treesitter_textobject({ a = "@function.outer", i = "@function.inner" }),
    c = treesitter_textobject({ a = "@class.outer", i = "@class.inner" }),
  },
})
```
This keeps every default mapping (`a`/`i`, `an`/`in`/`al`/`il`, `g[`/`g]`) and adds `af`/`if`
(around/inside function) and `ac`/`ic` (around/inside class) as treesitter-powered textobjects,
usable with any operator (e.g. `daf`, `vic`, `cif`).

**Discovered during implementation**: `gen_spec.treesitter()` does not degrade gracefully on its
own. When the buffer's language has no attached treesitter parser at all, or has a parser but no
`textobjects.scm` query defining the requested captures, it raises a Lua error (surfaced to the
user as an `E5108` traceback) instead of mini.ai's normal "no textobject found" message. Verified
directly: a `vimdoc`-filetype buffer (parser attached, no `textobjects.scm` captures for
`@function.*`/`@class.*`) threw `(mini.ai) Can not get query for buffer 1 and language "vimdoc"`
on `daf`, and a buffer with no filetype/parser threw `Can not get parser for buffer 1 and language
""`. This directly contradicted the original proposal's assumption (an accepted "silent no-op"
risk) and the `text-objects` spec's "no error is raised" scenario, so `treesitter_textobject()`
above pcall-wraps the generated spec to restore that intended behavior — re-verified after the fix
that the same `vimdoc` buffer now shows mini.ai's own harmless "No textobject "af" found ..."
message instead.

**Alternative considered**: `custom_textobjects = {}` (matching the "defaults only" precedent set
by `mini.pairs`/`mini.bracketed`). Rejected — `nvim-treesitter-textobjects` is already an installed
dependency that otherwise does nothing; this is the natural, zero-new-dependency way to make use
of it, and function/class are the two textobjects most commonly reached for beyond `mini.ai`'s
built-in bracket/quote/tag/argument set.

**Alternative considered**: configure `nvim-treesitter-textobjects`'s own `.setup()` with its
native `move`/`select` keymaps (its intended usage pattern) instead of routing through `mini.ai`.
Rejected — that would introduce a second, differently-shaped textobject/motion framework alongside
`mini.ai`'s `a`/`i` one for largely overlapping functionality (e.g. `]f`/`[f` function-navigation
vs. `af`/`if` function-textobject); `gen_spec.treesitter()` lets `mini.ai` consume the same query
files without that duplication.

**Alternative considered**: remap `an`/`in`/`al`/`il` to `aN`/`iN`/`aL`/`iL` (mini.ai's own
suggested alternative) to preserve Neovim's built-in incremental selection. Rejected per explicit
user decision — kept as upstream defaults; see Risks.

### 2. `mini.surround`: `setup()` with no arguments

```lua
require("mini.surround").setup()
```
Matches the user's explicit instruction to use the plugin's own defaults, with no remapping away
from the `s`-prefixed mappings.

### 3. `mini.bufremove`: `<Leader>bd` / `<Leader>bD`, configured in `plugin/60-mini.lua`

```lua
require("mini.bufremove").setup()

vim.keymap.set("n", "<Leader>bd", function()
  require("mini.bufremove").delete(0, false)
end, { desc = "Delete buffer" })

vim.keymap.set("n", "<Leader>bD", function()
  require("mini.bufremove").delete(0, true)
end, { desc = "Force delete buffer" })
```
Placed in `plugin/60-mini.lua` rather than `plugin/20-keymaps.lua`: per `CLAUDE.md`,
`20-keymaps.lua` holds keymaps "not owned by a specific plugin/LSP feature"; these are owned by
`mini.bufremove` specifically (they call its API directly), matching how the existing
`mini.completion`-driven insert-mode mappings already live alongside that module's `setup()` in
`60-mini.lua` rather than in `20-keymaps.lua`.

**Alternative considered**: different letters (e.g. `bc`/`bx` for "close"/"force-close").
Rejected per explicit user approval of the `bd`/`bD` proposal — `d` for "delete" matches the
underlying `MiniBufremove.delete()` function name and Neovim's own `:bdelete` naming.

### 4. `mini.notify`: `vim.notify` backend + `<Leader>on` history

```lua
require("mini.notify").setup()
vim.notify = require("mini.notify").make_notify()

vim.keymap.set("n", "<Leader>on", require("mini.notify").show_history, { desc = "Notification history" })
```
`lsp_progress.enable` stays at its default `true`, so LSP progress notifications (already produced
by the servers enabled in `plugin/40-lsp.lua`) automatically render through `mini.notify` with no
changes needed in `40-lsp.lua`.

**Alternative considered**: no keybinding, notification history reachable only via an ad hoc
`:lua require('mini.notify').show_history()`. Rejected per explicit user approval of `<Leader>on`.

### 5. `mini.trailspace`: default highlighting + `<Leader>cw` manual trim

```lua
require("mini.trailspace").setup()

vim.keymap.set("n", "<Leader>cw", function()
  require("mini.trailspace").trim()
end, { desc = "Trim trailing whitespace" })
```
Placed under `<Leader>c` "+Code" rather than `<Leader>t` "+Toggle": trimming is a one-shot,
deliberate action (like `<Leader>cf` format), not a persistent on/off toggle like the existing
`tf`/`tl`/`tv`/`td`/`th` entries.

**Alternative considered**: `<Leader>tw` under the Toggle group. Rejected per explicit user
approval of the Code-group placement.

**Alternative considered**: auto-trim on `BufWritePre`. Rejected per explicit user approval of
manual-only trimming — avoids surprising diffs in files edited by tools that don't strip trailing
whitespace themselves.

## Risks / Trade-offs

- **`mini.surround`'s `s`-prefixed mappings delay the built-in `s` (substitute-char) command** by
  `timeoutlen` while Neovim waits to see if a longer `sa`/`sd`/`sf`/`sF`/`sh`/`sr` sequence
  follows. Accepted per explicit instruction to use upstream defaults; no mitigation applied.
- **`mini.ai`'s `an`/`in`/`al`/`il` override Neovim's built-in incremental-selection mappings of
  the same name** (added in Neovim 0.12/0.13, which this config already targets per `CLAUDE.md`).
  Accepted per explicit user decision to keep upstream defaults; native incremental selection via
  those exact keys is no longer reachable. Mitigation: none applied (by choice) — if wanted later,
  `mini.ai`'s own docs describe copying the built-in mappings to different keys before calling
  `setup()`.
- **Treesitter function/class textobjects depend on a `textobjects.scm` query file existing for
  the buffer's language** among runtime queries (as shipped by `nvim-treesitter-textobjects` for
  many, but not all, languages). Of the languages in `plugin/50-plugins.lua`'s `languages` list,
  `c`, `cmake`, `cpp`, `lua`, `markdown`, `python`, and `vim` have a bundled query; `asm`,
  `editorconfig`, `markdown_inline`, `regex`, and `vimdoc` do not (verified by listing
  `nvim-treesitter-textobjects`'s `queries/` directory). Without the `treesitter_textobject()`
  pcall wrapper in Decision 1, missing coverage surfaces as a Lua error instead of a silent
  not-found — see that decision's "Discovered during implementation" note.
- **`mini.notify` replacing `vim.notify` changes the visual style of every notification in the
  editor** (LSP progress, plugin warnings, `vim.notify()` calls from any source), not just ones
  added by this change — a global, always-on behavior change rather than an opt-in keybinding.
  Accepted as the intended purpose of adding the module.

## Open Questions

None — all keybinding and default-vs-override decisions above were reviewed and approved before
writing this design.
