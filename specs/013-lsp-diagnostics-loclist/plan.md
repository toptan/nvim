# Implementation Plan: Diagnostics List in the Location List

**Branch**: `master` (no feature branch) | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/013-lsp-diagnostics-loclist/spec.md`

## Summary

Add `<leader>ld` (buffer) and `<leader>lD` (workspace) in Normal mode. They collect
diagnostics with `vim.diagnostic.get()`, drop disabled ones, sort them by severity, file,
line and column, and fill the location list of the current file window. Each entry gets a
pre-computed display line through a per-list `quickfixtextfunc`. The list then opens with
`:lopen` and takes focus. `<leader>lD` first sends `workspace/diagnostic` to attached
servers that support it and waits at most 2 s for the replies. Today none do: lua_ls
reports diagnostics for unopened files on its own, and clangd doesn't report them. A
decoration provider, registered on first use, colours each entry's severity label and
message with `DiagnosticError/Warn/Info/Hint`, only in lists made by these keys. A
`FileType qf` autocmd gives location list windows a buffer-local `<Esc>`, which closes the
list and focuses its owning window. `<CR>` keeps its built-in behaviour. Everything lives in
one new module, `lua/config/diagnostic_list.lua`.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: core only: `vim.diagnostic`, `vim.lsp` (client `requests`,
`vim.lsp.buf.workspace_diagnostics`), location list functions (`setloclist`,
`getloclist`, `:lopen`, `:lclose`), `nvim_set_decoration_provider`. Language servers
already configured (lua_ls, clangd, neocmakelsp).

**Storage**: none; a module-local table of display lines and highlight ranges per list id

**Testing**: manual and headless-scripted checks per [quickstart.md](quickstart.md)
(`screenattr()` for colours); `nvim --headless "+qa"`; `--startuptime`; `:checkhealth`;
lua_ls diagnostics

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: `<leader>ld` opens in < 0.5 s; `<leader>lD` in < 2.5 s (≤ 2 s
wait, skipped when no server supports pull workspace diagnostics); startup cost: two
keymaps and one autocmd (baseline startup 17.6 ms)

**Constraints**: startup < 100 ms; nothing from `vim.diagnostic`/`vim.lsp` loaded at
startup; never raise; global `<Esc>` and quickfix windows unchanged; 80-column Lua style

**Scale/Scope**: 1 new module (~150 lines), 1 line in `init.lua`, README rows and a short
section

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | No plugin; location list, diagnostics, LSP and decoration provider are core | ✅ |
| II. Modular Lua | One module `config.diagnostic_list` for one concern; `init.lua` gains one `require`; state in module locals; augroup `config_diagnostic_list` with `clear = true` | ✅ |
| III. Fast, Deferred Startup | Startup defines only two keymaps and one `FileType qf` autocmd; `vim.diagnostic`, `vim.lsp` and the decoration provider load on first key press | ✅ |
| IV. Reproducible & Fault-Tolerant | No external tools beyond the existing servers; no server or no diagnostics → one INFO notice; deleted files and closed windows are handled by validity checks, never by errors; headless start/quit clean | ✅ |
| V. Consistent Style | `.editorconfig` style; every mapping has `desc`; lua_ls-clean | ✅ |
| Constraints | Neovim 0.12 stable APIs only (`client.requests` is a documented field); no vendored code | ✅ |
| Workflow | Spec Kit flow; small commits (`docs:` for spec, `feat:` for code, `docs:` for README) | ✅ |

**Post-design re-check**: unchanged, all ✅. Research R2 replaced the private
diagnostic handler with public `vim.lsp.buf.workspace_diagnostics` plus polling of
`client.requests`. R3 keeps all colour work behind first use.

## Project Structure

### Documentation (this feature)

```text
specs/013-lsp-diagnostics-loclist/
├── plan.md              # This file
├── research.md          # Phase 0: decisions R1–R6
├── data-model.md        # Phase 1: diagnostic → entry mapping, sort, colours
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── diagnostic-list.md   # keys, autocmd, decoration provider, list properties
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                         # + require("config.diagnostic_list") after config.diagnostics
lua/config/diagnostic_list.lua   # NEW: keys, list building, colours, loclist <Esc>
README.md                        # + key rows and a "Diagnostics list" section
```

**Structure Decision**: Single new module beside the existing `config.diagnostics`
(display style and toggles), so each module keeps one concern. No changes to
`config.lsp`, `config.search` (global `<Esc>` is shadowed buffer-locally) or
`config.clue` (the existing `<Leader>l` "Language" group picks up the new `desc`s).

## Complexity Tracking

No constitution violations; nothing to justify.
