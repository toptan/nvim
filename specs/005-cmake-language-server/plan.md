# Implementation Plan: CMake Language Server with Gersemi Formatting

**Branch**: `master` (no feature branch) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/005-cmake-language-server/spec.md`

## Summary

Enable neocmakelsp for `cmake` buffers through Neovim's built-in LSP client (`lsp/neocmake.lua`
plus a lazy `vim.lsp.enable` on the first `FileType cmake`). Its formatting capabilities are
removed in `on_init`, so no formatting path, including `gq`, can reach it. `<leader>lf` in CMake
buffers instead runs gersemi on the buffer text through stdin, with `--stdin-filepath` so that
the project's `.gersemirc` is found, and applies only the changed hunks as a single undo step.
No plugin and no new key mapping.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: built-in `vim.lsp`, `vim.system`, `vim.text.diff`. External: neocmakelsp
≥ 0.11 (verified 0.11.2), gersemi (verified 0.29.2). Both are optional and on `PATH`.

**Storage**: N/A

**Testing**: manual and headless-scripted checks per [quickstart.md](quickstart.md);
`nvim --headless "+qa"`; `:checkhealth`; lua_ls diagnostics on the changed files

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: no startup cost (nothing loads before the first CMake buffer);
gersemi run ≈ 80 ms, with a 5 s timeout

**Constraints**: startup < 100 ms; silent when tools are missing; one undo step per format;
80-column Lua style from `.editorconfig`

**Scale/Scope**: 1 new server config, 1 new module (~60 lines), small edits to `lsp.lua` and
README

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Built-in `vim.lsp.config`/`enable`, `vim.system`, `vim.text.diff`; no nvim-lspconfig, no conform.nvim | ✅ |
| II. Modular Lua | Server config in `lsp/neocmake.lua`; gersemi logic in its own module `config.gersemi`; activation stays in `config.lsp` (single concern: LSP activation and `<leader>lf`); the existing `config_lsp` augroup has `clear = true` | ✅ |
| III. Fast, Deferred Startup | Server enabled on the first `FileType cmake`; `config.gersemi` required only on key press | ✅ |
| IV. Reproducible & Fault-Tolerant | `executable()` check before running gersemi; missing neocmakelsp is silent and reported by `:checkhealth vim.lsp`; README lists both tools; no absolute paths | ✅ |
| V. Consistent Style | Lua follows `.editorconfig`; the reused `<leader>lf` keeps its `desc`; files must be free of lua_ls warnings | ✅ |
| Workflow | Spec Kit flow for new language support; small focused commits | ✅ |

**Post-design re-check**: still passes. The design adds no plugin, no global state and no eager
loading. The `FileType` autocommand loses `once = true` but stays in the cleared `config_lsp`
augroup, and a per-server "enabled" set keeps `vim.lsp.enable` to one call per server.

## Project Structure

### Documentation (this feature)

```text
specs/005-cmake-language-server/
├── plan.md              # This file
├── research.md          # Phase 0: verified tool behaviour and decisions
├── data-model.md        # Phase 1: filetype→server map, server config, format request states
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
└── neocmake.lua         # NEW: cmd, filetypes, root_markers, on_init disabling formatting
lua/config/
├── lsp.lua              # CHANGED: FileType {lua, cmake} → enable matching server once;
│                        #          <leader>lf dispatches cmake buffers to config.gersemi
├── gersemi.lua          # NEW: format(bufnr) via gersemi on stdin, apply diff hunks
└── diagnostics.lua      # unchanged (setup() already idempotent)
README.md                # CHANGED: requirements, <leader>lf row, CMake section
```

**Structure Decision**: Follow the existing layout. Server definitions live in the runtime
`lsp/` directory, where `vim.lsp.config` finds them automatically, and editor behaviour lives
in single-concern modules under `lua/config/`. The gersemi logic gets its own module so that
`config.lsp` stays small and gersemi can be removed or replaced in isolation.

## Implementation Notes

1. **`lsp/neocmake.lua`**: see [data-model.md](data-model.md). `on_init(client)` sets
   `client.server_capabilities.documentFormattingProvider`,
   `documentRangeFormattingProvider` and `documentOnTypeFormattingProvider` to `false`
   (research R3).
2. **`lua/config/lsp.lua`**: replace the `pattern = "lua", once = true` autocommand with
   `pattern = { "lua", "cmake" }` and a `servers = { lua = "lua_ls", cmake = "neocmake" }`
   map, plus a local `enabled` set. The callback runs `diagnostics.setup()` and enables the
   server for `args.match` only if it is not yet in the set. In `<leader>lf`, after the
   read-only check, `if vim.bo.filetype == "cmake" then require("config.gersemi").format(0)
   return end`.
3. **`lua/config/gersemi.lua`**: implement the request and outcome states from
   data-model.md and research R4–R6. Run synchronously with `vim.system(cmd, { stdin, cwd,
   text = true }):wait(5000)`; a timeout shows up as `code == 124` (the process is killed
   with signal 9). Apply the hunks from
   `vim.text.diff(old, new, { result_type = "indices" })` in reverse order.
4. **README**: add neocmakelsp and gersemi to Requirements (optional, with install hints),
   change the `<leader>lf` row to "with its language server, or gersemi for CMake", and add a
   short "CMake" section (root detection, `.gersemirc`, `gq` is plain text formatting).

## Complexity Tracking

No constitution violations; nothing to justify.
