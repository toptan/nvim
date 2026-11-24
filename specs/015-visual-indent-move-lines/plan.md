# Implementation Plan: Sticky Visual Indent and Line Moving

**Branch**: `master` (no feature branch) | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/015-visual-indent-move-lines/spec.md`

## Summary

Visual-mode `>` / `<` shift the selection and keep it selected. `<M-j>` / `<M-k>` (and the
macOS Option fallbacks `∆` / `˚`) move the current line or the selected lines down / up by
`count`, stopping at the buffer edge, and keep visual selections selected. Everything goes
into the existing `lua/config/keymaps.lua` using core Neovim only: `>gv` / `<gv` for
indenting and a small Lua helper around `:move` for moving lines. A headless prototype
([research.md](research.md)) showed that this approach meets every acceptance scenario.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12.6

**Primary Dependencies**: None, only core Neovim (`vim.keymap.set`, `:move`, `gv`)

**Storage**: N/A

**Testing**: Manual exercise per [quickstart.md](quickstart.md) plus headless
`nvim --headless` scripts driving the keys with `nvim_feedkeys`; `nvim --headless "+qa"`

**Target Platform**: Neovim in a terminal; macOS primary, Linux supported

**Project Type**: Personal editor configuration (single Lua config tree)

**Performance Goals**: Each key press acts instantly; no measurable startup cost (adds
6 mappings + 1 local function at startup)

**Constraints**: 80-column Lua, double quotes, trailing separators, `desc` on every mapping;
no plugins

**Scale/Scope**: About 40 lines in one existing module, plus a README section

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Result |
|-----------|-------|--------|
| I. Native-First | Built from `:move`, `gv` and `>`/`<` only; no plugin | PASS |
| II. Modular Lua | Goes into the existing single-concern `keymaps.lua`; no globals, no autocommands | PASS |
| III. Fast, Deferred Startup | Defining core keymaps eagerly is explicitly allowed; cost is negligible | PASS |
| IV. Reproducible & Fault-Tolerant | No external tools; moves at the buffer edge are no-ops, so no errors; `nvim --headless "+qa"` stays clean | PASS |
| V. Consistent Style | `.editorconfig` style; every mapping has a `desc` | PASS |
| Technical constraints | No nightly-only APIs; `∆`/`˚` mappings are harmless on Linux (just unused characters in normal and visual mode) | PASS |

**Post-design re-check**: PASS, because the design adds nothing beyond the above.

## Project Structure

### Documentation (this feature)

```text
specs/015-visual-indent-move-lines/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── editing-keys.md  # Phase 1 output: the key mapping contract
└── tasks.md             # Phase 2 output (/speckit-tasks, not created here)
```

### Source Code (repository root)

```text
lua/config/
└── keymaps.lua   # + visual >/< (sticky), move_lines() helper, <M-j>/<M-k>/∆/˚
README.md         # + rows in the "Key mappings" table
```

**Structure Decision**: Extend `lua/config/keymaps.lua`, the module that already owns
general-purpose key mappings. No new module is needed.

## Complexity Tracking

No constitution violations to justify.
