# Research: Next-Key Clues via mini.clue

All findings come from a prototype run on 2026-11-22: Neovim 0.12.6, `nvim-mini/mini.clue` at
`7e27c16`, the real configuration, and a throw-away data directory (`XDG_DATA_HOME`). TUI
behaviour was checked by driving Neovim in tmux. No NEEDS CLARIFICATION items remained in the
Technical Context.

## R1. Install and setup pattern

- **Decision**: `pcall(vim.pack.add, { "https://github.com/nvim-mini/mini.clue" },
  { confirm = false })`, then `pcall` around `require("mini.clue").setup({...})`. On failure,
  one scheduled WARN notification. This is the same pattern as `config.notifications`
  (feature 009).
- **Rationale**: matches the existing plugins; meets FR-007 and FR-008. The standalone repo
  (not the whole `mini.nvim`) keeps "only the clue module" (spec Assumptions).
- **Alternatives considered**: installing `mini.nvim` (pulls every module; rejected).

## R2. When to load

- **Decision**: load eagerly when the module is required from `init.lua` (last line).
- **Rationale**: the triggers are the very keys that need clues, so they must exist before
  the first key press; there is no later event to defer to. Measured (median of 5, headless,
  `--startuptime`): 10.4 ms without the plugin, 11.9 ms with it (`require('mini.clue')`
  0.9 ms, `setup()` 1.6 ms in isolation). Well under 100 ms.
- **Alternatives considered**: `UIEnter` + `once`: in Neovim 0.12's TUI the `UIEnter`
  autocommands still run before `--- NVIM STARTED ---` (measured), so nothing is saved, and
  headless runs would never install the plugin. `vim.schedule` from the module: same cost,
  only a small race with typeahead. Both rejected.

## R3. Triggers and clue sets

- **Decision**: copy the quick start verbatim (11 trigger entries = 18 mode/key pairs; 7
  `gen_clues` sets), plus two clue entries:
  `{ mode = { "n", "x" }, keys = "<Leader>l", desc = "+Language" }` and
  `{ mode = { "n", "x" }, keys = "<Leader>t", desc = "+Toggle" }`.
- **Rationale**: FR-002, FR-003, FR-003a. The leading `+` is the plugin's convention for a
  group (it also shows unnamed groups as `+N` and LSP's `gr` as `+LSP`), so the names read
  consistently with the built-in clue sets; the group's name is still "Language" / "Toggle".
  The window title after `<Space>l` shows `+Language` (observed).
- **Alternatives considered**: `desc = "Language"` without `+`: indistinguishable from a
  single command in the window; rejected.

## R4. Behaviour verified in the prototype

| Check | Result |
|-------|--------|
| `g` + pause (Normal) | Window lists the `g` clues, including LSP's `gO` and `+LSP` for `gr` (buffer-local LSP mappings co-exist with the trigger) |
| `<Space>` (Normal) | `l  +Language`, `t  +Toggle`; then `l` → `f  Format buffer` |
| `<Space>` (Visual) | `l  +Language`, `t  +Toggle` |
| `<Space>l` (Visual, no mappings beneath) | No window, no error; keys fall through (`<Space>l` moves the cursor two columns); Visual mode stays active |
| `z` (Normal) | `z` clues window |
| `g*` (expr mapping from `config.search`) | Searches as before (`search hit BOTTOM`), counter logic unaffected |
| `<C-r>` (Insert, Command-line) | Register list with contents |
| `<C-x>` (Insert) | Built-in completion sub-modes |
| Headless start/quit with plugin installed | 0 bytes of output |
| Trigger mappings | Buffer-local, `nowait`, `desc = 'Query keys after "…"'` |

The Visual-mode fall-through is accepted: it meets the spec's edge case (no error, Visual mode
intact) and goes away once Visual-mode `<Leader>l…` / `<Leader>t…` mappings exist.

## R5. Interaction with existing configuration

- **Decision**: no changes to other modules.
- **Rationale**: `'timeoutlen'` is not set by the config and the plugin does not rely on it.
  No config mapping uses a trigger key as its whole left-hand side; `<Tab>`, `<S-Tab>`, `<Esc>`
  (Normal) and the Insert-mode completion keys of feature 010 are not triggers. `g*` / `g#`
  are reached through the `g` trigger and still run their `expr` mappings (R4). Neovim's own
  buffer-local LSP mappings (`gO`, `K`, `gr*`) are longer than or different from the triggers
  and stay reachable.
- **Alternatives considered**: calling `MiniClue.ensure_buf_triggers()` on `LspAttach`: not
  needed, since no buffer-local mapping overrides a trigger (verified in R4).

## R6. Plugin justification (Principle I)

- **Decision**: comment beside `vim.pack.add`: "core Neovim cannot show which keys may follow
  a partially typed key sequence; it only waits for 'timeoutlen'."
- **Alternatives considered**: none in core; `which-key.nvim` is heavier and not what was
  requested.
