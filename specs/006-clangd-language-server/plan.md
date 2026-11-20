# Implementation Plan: clangd Language Server with Built-in Formatting

**Branch**: `master` (no feature branch) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/006-clangd-language-server/spec.md`

## Summary

Enable clangd for `c`, `cpp`, `objc`, `objcpp` and `cuda` buffers through Neovim's built-in
LSP client (`lsp/clangd.lua` plus five new entries in the lazy filetype → server map in
`config.lsp`). clangd runs without flags, so its own compilation-database discovery, include
insertion and `.clang-format` handling apply. Neovim's default omni-completion applies the
inserted `#include` and expands argument placeholders on `<C-y>` (research R8). Its
formatting capabilities are kept: the
existing `<leader>lf` LSP path formats the whole buffer, and Neovim's attach default makes `gq`
use clangd range formatting. No plugin, no new key mapping, no change to `<leader>lf`.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: built-in `vim.lsp`. External: clangd (verified 23.1.6, Homebrew
LLVM), optional and on `PATH`. `clang-format` is used only for validation (SC-002).

**Storage**: N/A

**Testing**: manual and headless-scripted checks per [quickstart.md](quickstart.md);
`nvim --headless "+qa"`; `:checkhealth`; lua_ls diagnostics on the changed files

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: no startup cost (nothing loads before the first C-family buffer);
formatting is synchronous with the existing 3 s timeout

**Constraints**: startup < 100 ms; silent when clangd is missing; one undo step per format;
80-column Lua style from `.editorconfig`

**Scale/Scope**: 1 new server config (~15 lines), a one-line edit to `lsp.lua`, README

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Built-in `vim.lsp.config`/`enable`, default LSP omni-completion, LSP formatting and `formatexpr`; no nvim-lspconfig, no clangd_extensions, no conform.nvim | ✅ |
| II. Modular Lua | Server config in `lsp/clangd.lua`; activation stays in `config.lsp`; no new module, global or augroup | ✅ |
| III. Fast, Deferred Startup | Server enabled on the first C-family `FileType` | ✅ |
| IV. Reproducible & Fault-Tolerant | Missing clangd is silent and reported by `:checkhealth vim.lsp`; README lists it; no absolute paths or machine-specific database paths | ✅ |
| V. Consistent Style | Lua follows `.editorconfig`; no new keymaps; files must be free of lua_ls warnings | ✅ |
| Workflow | Spec Kit flow for new language support; small focused commits | ✅ |

**Post-design re-check**: still passes. The design adds only a data table and one map entry
per filetype; the existing `enabled` set (keyed by server name) keeps `vim.lsp.enable("clangd")`
to one call even though five filetypes trigger it.

## Project Structure

### Documentation (this feature)

```text
specs/006-clangd-language-server/
├── plan.md              # This file
├── research.md          # Phase 0: verified clangd behaviour and decisions
├── data-model.md        # Phase 1: filetype→server map, server config, <leader>lf dispatch
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── keymaps-and-lsp.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # unchanged
lsp/
├── lua_ls.lua           # unchanged
├── neocmake.lua         # unchanged
└── clangd.lua           # NEW: cmd, filetypes, root_markers
lua/config/
├── lsp.lua              # CHANGED: servers map gains c/cpp/objc/objcpp/cuda = "clangd"
├── gersemi.lua          # unchanged
└── diagnostics.lua      # unchanged
README.md                # CHANGED: requirements, <leader>lf row, C/C++ section
```

**Structure Decision**: Follow the existing layout: server definitions live in the runtime
`lsp/` directory, activation in `config.lsp`. clangd needs no behaviour of its own, so no new
module under `lua/config/`.

## Implementation Notes

1. **`lsp/clangd.lua`**: the table from [data-model.md](data-model.md), with a short header
   comment (as in `neocmake.lua`) explaining the root choice and that formatting is kept
   deliberately (research R2, R4).
2. **`lua/config/lsp.lua`**: extend
   `servers = { lua = "lua_ls", cmake = "neocmake", }` with
   `c`, `cpp`, `objc`, `objcpp`, `cuda` → `"clangd"`, wrapped to 80 columns. The `FileType`
   autocommand already uses `vim.tbl_keys(servers)` as its pattern and the `enabled` set is
   keyed by server name, so nothing else changes. Update the file's header comment if it
   lists formatters.
3. **README**: add clangd to Requirements (optional, `brew install llvm` or Xcode CLT), change
   the `<leader>lf` row to mention clangd and `.clang-format`, and add a short "C and C++"
   section: when it starts, root detection, compilation database lookup and the `.clangd` /
   symlink recipe for other build directories (research R3), `gq` formats through clangd,
   and the `.cache/` index location note (research R6).

## Complexity Tracking

No constitution violations; nothing to justify.
