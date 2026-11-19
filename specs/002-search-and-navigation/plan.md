# Implementation Plan: Search, Yank Feedback and Buffer Navigation

**Branch**: `master` (no feature branch) | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-search-and-navigation/spec.md`

## Summary

Turn off incremental search, add smart-case matching, and widen the number column to 5 digits
(options only). Normal-mode `<Esc>` clears search highlights. After each search jump, a
`[current/total]` label is shown right-aligned on the current match's line. It is computed with
the built-in `searchcount()` and drawn as an extmark, and is removed on clear, edit or buffer
switch. `<Tab>`/`<S-Tab>` cycle file buffers in open order, skipping help, quickfix and terminal
buffers. Yanks flash via `vim.hl.on_yank()`. Core Neovim only, no plugins.

## Technical Context

**Language/Version**: Lua (LuaJIT, as embedded in Neovim 0.12.6)

**Primary Dependencies**: Neovim 0.12+ core only (`searchcount()`, extmarks, `vim.hl.on_yank`);
no plugins

**Storage**: N/A

**Testing**: Headless Neovim checks, manual scenarios, `--startuptime`; see
[quickstart.md](quickstart.md)

**Target Platform**: Neovim 0.12+ in a terminal, macOS primary

**Project Type**: Editor configuration (single Neovim config directory)

**Performance Goals**: Startup < 100 ms (Constitution III). Label refresh bounded by
`searchcount` `timeout = 100` ms and `maxcount = 999` (FR-009).

**Constraints**:
- No plugins.
- Normal-mode mappings only.
- `<C-i>` is deliberately sacrificed (FR-012a).
- The label never modifies buffer text.

**Scale/Scope**: 3 new Lua modules plus edits to `options.lua` and `init.lua`; ~120 lines

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Native-First | No plugin when core suffices | ✅ `searchcount`, extmarks and `vim.hl.on_yank` replace `nvim-hlslens`/bufferline-style plugins (R3, R8) |
| II. Modular Lua | Thin `init.lua`; one concern per module; named augroups with `clear = true` | ✅ `config.search`, `config.keymaps`, `config.autocmds`; augroups `config_search_count`, `config_yank_highlight` |
| III. Fast, Deferred Startup | Only first-buffer essentials eager | ✅ Eager work is limited to options, keymap and autocommand registration. Label logic runs only on search keys (R11) |
| IV. Reproducible & Fault-Tolerant | No startup errors; failures degrade silently | ✅ No external tools. `clear()`/`refresh()` never raise (contract). Headless start checked in quickstart §1 |
| V. Consistent Style | `.editorconfig`; `lua_ls` clean; every keymap has `desc` | ✅ Every mapping in the contract has a `desc` (FR-015) |
| Tech constraints | Stable 0.12 APIs only | ✅ All APIs verified on 0.12.6. Deprecated `vim.highlight` avoided (R9) |
| Workflow | Verify via headless start + `:checkhealth` + manual run | ✅ Quickstart §1–§8 |

**Post-design re-check (after Phase 1)**: ✅ All gates still pass. The only new state is
module-local (label buffer and extmark id). No new `vim.g` globals.

## Project Structure

### Documentation (this feature)

```text
specs/002-search-and-navigation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (settings, label states, cycle rules)
├── quickstart.md        # Phase 1 output (validation guide)
├── contracts/
│   └── keymaps-and-search.md   # Mappings and config.search API
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
init.lua                     # + require("config.search"), ("config.keymaps"), ("config.autocmds")
lua/
└── config/
    ├── options.lua          # + incsearch, ignorecase, smartcase, numberwidth, shortmess S
    ├── colorscheme.lua      # unchanged
    ├── search.lua           # NEW: position label, n/N/*/#/g*/g# wrappers, <Esc>, clear/refresh
    ├── keymaps.lua          # NEW: <Tab>/<S-Tab> file-buffer cycling
    └── autocmds.lua         # NEW: highlight on yank
```

**Structure Decision**:
- **Options** go into the existing `config.options`, which loads first.
- **`config.search`**: the label, the keys that trigger it and the key that clears it form one
  concern, so they live together and expose `clear()`/`refresh()` (contract).
- **`config.keymaps`** holds general-purpose mappings, starting with buffer cycling. Later
  features add their mappings there.
- **`config.autocmds`** holds small general autocommands, starting with the yank highlight.

## Complexity Tracking

No constitution violations; nothing to justify.
