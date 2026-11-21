# Implementation Plan: Notifications via mini.notify

**Branch**: `master` (no feature branch) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-mini-notify-popup/spec.md`

## Summary

Replace the hand-written popup in `lua/config/notifications.lua` (~300 lines) with a short
module that installs `nvim-mini/mini.notify` through `vim.pack.add` (`confirm = false`) and calls
`require("mini.notify").setup()` with defaults; `setup()` itself replaces `vim.notify`
(research R2). Both steps are wrapped in `pcall`, so a missing plugin leaves the built-in
`vim.notify` in place (R5). The module stays first after `config.options` in `init.lua` so every
later notification reaches the plugin. The README's Notifications section is rewritten and the
plugin listed. This is the configuration's first `vim.pack` plugin.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: `vim.pack` (built-in); `mini.notify` (`nvim-mini/mini.notify`,
prototyped at `95531373`); `git` (needed by `vim.pack`)

**Storage**: plugin checkout in `stdpath("data")/site/pack/core/opt/`; `nvim-pack-lock.json`
(git-ignored); notification history in plugin memory

**Testing**: manual TUI checks per [quickstart.md](quickstart.md) (tmux-driven where useful);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: popup within one event-loop tick; ~2 ms added startup (measured, R6)

**Constraints**: startup < 100 ms; no headless output once the plugin is installed (first
install prints progress, research R5); `.editorconfig` Lua style; no globals created by the
config; no new mappings

**Scale/Scope**: one module rewritten (~300 → ~15 lines), `init.lua` comment touched, README
section rewritten

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Adds a plugin. Justification comment beside `vim.pack.add`: core Neovim has no notification popup, and the plugin replaces ~300 lines of custom code. Uses built-in `vim.pack`, not a plugin manager. Experimental `ui2` still rejected (008 R1) | ✅ (justified) |
| II. Modular Lua | `config.notifications` owns exactly one plugin; `init.lua` unchanged except its comment; no config-defined globals (`MiniNotify` is exported by the plugin) and no augroups needed | ✅ |
| III. Fast, Deferred Startup | Loaded eagerly — justified: notifications may come from any module from startup on (R6). Cost ≈ 2 ms measured | ✅ (justified) |
| IV. Reproducible & Fault-Tolerant | Auto-install with `confirm = false`; `pcall` around add and setup; fallback to built-in `vim.notify`; `git` is a documented dependency; headless silent after first install | ✅ |
| V. Consistent Style | `.editorconfig` style; lua_ls-clean; no mappings added | ✅ |
| Workflow | Plugin replacement → Spec Kit flow; small focused commits | ✅ |

**Post-design re-check**: passes. Eager loading and the added plugin are recorded in
Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/009-mini-notify-popup/
├── plan.md              # This file
├── research.md          # Phase 0: prototype findings and decisions
├── data-model.md        # Phase 1: plugin spec, levels, states
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── notifications.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # CHANGED: comment above require("config.notifications") only
lua/config/
└── notifications.lua    # REWRITTEN: vim.pack.add mini.notify + setup(), with pcall
README.md                # CHANGED: Notifications section; plugin listed with git requirement
```

**Structure Decision**: keep the existing `lua/config/` layout; one plugin does not warrant a
separate `lua/plugins/` directory (research R6).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Plugin added (Principle I) | User explicitly requested `mini.notify`; core has no popup | Keeping the custom popup: ~300 lines to maintain, which the user wants gone |
| Eager load at startup (Principle III) | Notifications from any module, including during startup, must reach the plugin | Lazy wrapper on first `vim.notify`: custom code for ~0.4 ms gain |
