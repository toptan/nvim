# Implementation Plan: Next-Key Clues via mini.clue

**Branch**: `master` (no feature branch) | **Date**: 2026-11-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/011-mini-clue/spec.md`

## Summary

Add `nvim-mini/mini.clue` in a new module `lua/config/clue.lua`, installed through
`vim.pack.add` (`confirm = false`) and set up at startup (research R2) with the quick start's
11 triggers and 7 generated clue sets, plus two `<Leader>` group names (`+Language`,
`+Toggle`) in Normal and Visual mode (R3). Failure is wrapped in `pcall` with one WARN notice
(R1). `init.lua` requires the module last. The README gains a "Key clues" section and a
Plugins entry. A prototype confirmed every trigger, the group names, `expr` mappings and
headless silence (R4); startup grows by about 1.5 ms.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: `vim.pack` (built-in); `mini.clue` (`nvim-mini/mini.clue`,
prototyped at `7e27c16`); `git`

**Storage**: plugin checkout in `stdpath("data")/site/pack/core/opt/`; `nvim-pack-lock.json`
(git-ignored)

**Testing**: manual TUI checks per [quickstart.md](quickstart.md) (tmux-driven where useful);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: clue window after the plugin's 1 s default delay; startup +~1.5 ms
(10.4 → 11.9 ms measured, R2)

**Constraints**: startup < 100 ms; no headless output once installed; `.editorconfig` Lua
style; no globals created by the config (`MiniClue` is exported by the plugin); triggers and
clues exactly as in the spec (FR-002, FR-003, FR-003a)

**Scale/Scope**: one new module (~50 lines), one line in `init.lua`, README sections

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Adds a plugin. Justification comment beside `vim.pack.add`: core cannot show which keys may follow a partially typed sequence (R6). Uses built-in `vim.pack` | ✅ (justified) |
| II. Modular Lua | `config.clue` owns one plugin; `init.lua` gains one `require`; no autocommands of its own; no config-defined globals | ✅ |
| III. Fast, Deferred Startup | Loaded at startup, not on a trigger: the triggers are the keys the plugin must catch, so it must be set up before the first key (R2). Measured +1.5 ms; startup stays ~12 ms | ✅ (justified, see Complexity Tracking) |
| IV. Reproducible & Fault-Tolerant | Auto-install with `confirm = false`; `pcall` around add and setup; one non-blocking notice; keys still work; headless start/quit silent (verified) | ✅ |
| V. Consistent Style | `.editorconfig` style; lua_ls-clean; no new key mappings defined by the config (trigger mappings carry the plugin's own `desc`) | ✅ |
| Workflow | New plugin → Spec Kit flow; small focused commits | ✅ |

**Post-design re-check**: passes. Plugin and eager loading recorded in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/011-mini-clue/
├── plan.md              # This file
├── research.md          # Phase 0: prototype findings and decisions
├── data-model.md        # Phase 1: triggers, clues, states
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── clue.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # CHANGED: require("config.clue") added last
lua/config/
└── clue.lua             # NEW: vim.pack.add + setup({ triggers, clues }); pcall + WARN
README.md                # CHANGED: "Key clues" section; mini.clue under Plugins
```

**Structure Decision**: keep the existing `lua/config/` layout, as in features 009 and 010.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Plugin added (Principle I) | User explicitly requested `mini.clue`; core has no next-key hints | None exists in core |
| Loaded at startup, not on a trigger (Principle III) | Triggers must be installed before the first key press | `UIEnter` / `vim.schedule` deferral: measured no saving in `--startuptime` and adds a typeahead race (R2) |
