# Implementation Plan: One Diagnostics Module, Aligned List and Window Keys

**Branch**: `master` (no feature branch) | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/014-diagnostics-module-window-keys/spec.md`

## Summary

Three changes. (1) Move the code of `lua/config/diagnostic_list.lua` into
`lua/config/diagnostics.lua` below the toggles. The augroup is shared (one
`config_diagnostics` group with `clear = true`, created once at the top), the namespace is
renamed to `config_diagnostics`, and `M.setup()` stays exported for `lsp.lua`. Then delete
the old file and its `require` in `init.lua`. (2) Change `build()` to make two passes.
The first pass formats each entry's location (`file|lnum col col`) and finds the widest
one by screen width (`strdisplaywidth`). The second pass pads each location to that
width, adds one space, and pads the label to 7 (the width of "warning") before `| `.
Highlight ranges are byte offsets computed after padding, so they cover only the label
and the message. (3) In `lua/config/keymaps.lua`, add four Normal-mode mappings, `<C-h>`
→ `<C-w>h` and so on, each with a `desc`. The README gets the new keys, the aligned
format, the loss of `<C-l>` redraw, and `<C-j>` in place of `<C-w>j`.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: core only: `vim.diagnostic`, `vim.lsp`, location list functions,
`nvim_set_decoration_provider`, `vim.fn.strdisplaywidth`, `vim.keymap.set`

**Storage**: none; module-local table of list records per location list id (unchanged)

**Testing**: headless-scripted and manual checks per [quickstart.md](quickstart.md);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: list build stays linear in the number of diagnostics (one extra
pass); startup cost unchanged plus four keymaps

**Constraints**: startup < 100 ms; nothing from `vim.diagnostic`/`vim.lsp` loaded at
startup; Normal mode only for window keys; 80-column Lua style

**Scale/Scope**: `diagnostics.lua` grows to about 280 lines; one file deleted; one line
removed from `init.lua`; four mappings in `keymaps.lua`; README edits

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | No plugin; all core APIs | ✅ |
| II. Modular Lua | One module now owns one concern (diagnostics: display, toggles, list); window keys go to the general `keymaps.lua`; one augroup with `clear = true`; no new globals. The location list `<Esc>` applies to every location list, but it exists for the diagnostics list and moves with it (spec Assumptions) | ✅ |
| III. Fast, Deferred Startup | Merged code still defines only keymaps and autocmds at load; `vim.diagnostic`/`vim.lsp` stay untouched until a key press or `DiagnosticChanged` | ✅ |
| IV. Reproducible & Fault-Tolerant | No new external tools; window keys at an edge are no-ops (built-in behaviour); headless start/quit clean | ✅ |
| V. Consistent Style | `.editorconfig` style; every new mapping has `desc`; lua_ls-clean | ✅ |
| Constraints | Stable 0.12 APIs only | ✅ |
| Workflow | Spec Kit flow; commits split by concern (`refactor:` merge, `feat:` alignment, `feat:` window keys, `docs:` README) | ✅ |

**Post-design re-check**: unchanged, all ✅.

## Project Structure

### Documentation (this feature)

```text
specs/014-diagnostics-module-window-keys/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R1–R5
├── data-model.md        # Phase 1: aligned entry layout and highlight ranges
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── diagnostics-and-window-keys.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                       # drop require("config.diagnostic_list")
lua/config/
├── diagnostics.lua            # display + toggles + diagnostics list (merged, aligned)
├── diagnostic_list.lua        # DELETED
└── keymaps.lua                # + <C-h>/<C-j>/<C-k>/<C-l>
README.md                      # key rows, list format, <C-l> note
```

**Structure Decision**: The existing flat `lua/config/` layout. Diagnostics stays one
module, and the window keys join the general key mappings.

## Complexity Tracking

No violations.
