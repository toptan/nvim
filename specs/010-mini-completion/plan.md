# Implementation Plan: Completion via mini.completion

**Branch**: `master` (no feature branch) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/010-mini-completion/spec.md`

## Summary

Replace the hand-written completion in `lua/config/completion.lua` (258 lines) with
`nvim-mini/mini.completion`, installed through `vim.pack.add` (`confirm = false`) and set up
with defaults on the first `InsertEnter` (research R5). The plugin provides automatic LSP-first
completion with buffer-word fallback in every buffer, re-requests for incomplete lists,
trigger characters, info and signature windows, and `<C-Space>` (R2). The module keeps only the
`<Tab>` / `<S-Tab>` / `<CR>` mappings and adds `<C-@>` → the plugin's trigger (R4). In
`config.options`, `'completeopt'` drops `popup` (duplicate info window, R3) and `'shortmess'`
gains `c`. The README's Completion and Plugins sections are rewritten.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: `vim.pack` (built-in); `mini.completion`
(`nvim-mini/mini.completion`, prototyped at `cdf8bdf`); `vim.snippet` (built-in); `git`

**Storage**: plugin checkout in `stdpath("data")/site/pack/core/opt/`; `nvim-pack-lock.json`
(git-ignored)

**Testing**: manual TUI checks per [quickstart.md](quickstart.md) (tmux-driven where useful);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: menu ≤ 100 ms after a pause (plugin default debounce) plus server time;
startup unchanged (~12 ms, measured, R5)

**Constraints**: startup < 100 ms; no headless output once installed; `.editorconfig` Lua
style; no globals created by the config (`MiniCompletion` is exported by the plugin); every
mapping has `desc`

**Scale/Scope**: one module rewritten (258 → ~60 lines), two option lines in
`config.options`, README sections rewritten

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Adds a plugin. Justification comment beside `vim.pack.add`: core's `'autocomplete'` + `vim.lsp.completion` needed ~250 lines of workarounds (ranking, incomplete lists, trigger characters) to merge server and buffer suggestions; the plugin does this natively. Uses built-in `vim.pack`, `vim.snippet`, the built-in popup menu | ✅ (justified) |
| II. Modular Lua | `config.completion` owns one plugin plus its keys; `InsertEnter` autocommand in augroup `config_completion` (`clear = true`); no config-defined globals | ✅ |
| III. Fast, Deferred Startup | Plugin loaded on first `InsertEnter`, not at startup (R5); startup measured unchanged | ✅ |
| IV. Reproducible & Fault-Tolerant | Auto-install with `confirm = false`; `pcall` around add and setup; one non-blocking notice; built-in completion keys still work; headless start/quit clean (verified) | ✅ |
| V. Consistent Style | `.editorconfig` style; lua_ls-clean; all mappings keep/get `desc` | ✅ |
| Workflow | Plugin replacement → Spec Kit flow; small focused commits | ✅ |

**Post-design re-check**: passes. The added plugin is recorded in Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/010-mini-completion/
├── plan.md              # This file
├── research.md          # Phase 0: prototype findings and decisions
├── data-model.md        # Phase 1: plugin spec, options, states
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── completion.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # unchanged (require("config.completion") stays last)
lua/config/
├── completion.lua       # REWRITTEN: lazy vim.pack.add + setup(); <Tab>/<S-Tab>/<CR>/<C-@>
└── options.lua          # CHANGED: 'completeopt' without popup; 'shortmess' += c
README.md                # CHANGED: Completion section; plugin listed; Popups mentions Info/Signature
```

**Structure Decision**: keep the existing `lua/config/` layout, as in feature 009.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Plugin added (Principle I) | User explicitly requested `mini.completion`; core needs ~250 lines of workarounds for the same behaviour | Keeping the custom code: the maintenance burden the user wants gone |
