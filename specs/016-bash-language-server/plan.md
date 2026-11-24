# Implementation Plan: Bash Language Server

**Branch**: `master` (no feature branch) | **Date**: 2026-11-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/016-bash-language-server/spec.md`

## Summary

Enable the bash language server (bash-language-server; config name `bashls`, as in
nvim-lspconfig) for `sh` and `bash` buffers through Neovim's built-in
LSP client: a new `lsp/bashls.lua` plus two entries in the lazy filetype → server map in
`config.lsp`. The server runs with its defaults, so ShellCheck diagnostics and shfmt
formatting work when those tools are on `PATH`. `<leader>lf` uses the existing LSP path;
indentation comes from Neovim's `'shiftwidth'`/`'expandtab'`, i.e. `.editorconfig` when it
sets them, else the config's 4-space default (research R3). Because the server advertises
formatting even without shfmt, `on_init` turns the
capability off when `shfmt` is missing so the existing "cannot format" notice appears (R4).
Shell buffers also get tree-sitter via the `bash` parser: one `LANGUAGES` entry and two
`FILETYPES` entries in `config.treesitter` (R7). No plugin, no new key mapping.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: built-in `vim.lsp`; existing nvim-treesitter and
nvim-treesitter-textobjects. External, optional, on `PATH`: bash-language-server (verified
5.8.1), ShellCheck, shfmt (verified 3.14.1)

**Storage**: N/A

**Testing**: manual and headless-scripted checks per [quickstart.md](quickstart.md);
`nvim --headless "+qa"`; `:checkhealth`; lua_ls diagnostics on the changed files

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: no startup cost (nothing loads before the first shell buffer);
formatting synchronous with the existing 3 s timeout

**Constraints**: startup < 100 ms; silent when any tool is missing; one undo step per format;
80-column Lua style from `.editorconfig`

**Scale/Scope**: 1 new server config (~20 lines), 2-line edit to `lsp.lua`, 3-line edit to
`treesitter.lua`, README

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Built-in `vim.lsp.config`/`enable` and LSP formatting; no nvim-lspconfig, no conform.nvim or nvim-lint; tree-sitter reuses the already-justified plugins | ✅ |
| II. Modular Lua | Server config in `lsp/bashls.lua`; activation stays in `config.lsp`; parser data in `config.treesitter`; no new module, global or augroup | ✅ |
| III. Fast, Deferred Startup | Server enabled on the first `sh`/`bash` `FileType`; tree-sitter loads on first supported buffer as before | ✅ |
| IV. Reproducible & Fault-Tolerant | Missing server/ShellCheck/shfmt raise no errors (verified); shfmt absence handled with the single existing notice; README lists all three | ✅ |
| V. Consistent Style | Lua follows `.editorconfig`; no new keymaps; files must be free of lua_ls warnings | ✅ |
| Workflow | Spec Kit flow for new language support; small focused commits | ✅ |

**Post-design re-check**: still passes. The design adds data entries and one `on_init`
guard mirroring `neocmake.lua`; no dispatcher logic changes.

## Project Structure

### Documentation (this feature)

```text
specs/016-bash-language-server/
├── plan.md              # This file
├── research.md          # Phase 0: verified server behaviour and decisions
├── data-model.md        # Phase 1: map entries, server config, <leader>lf dispatch
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── keymaps-and-lsp.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
lsp/
├── bashls.lua           # NEW: cmd, filetypes, root_markers, on_init shfmt guard
├── clangd.lua           # unchanged
├── lua_ls.lua           # unchanged
└── neocmake.lua         # unchanged
lua/config/
├── lsp.lua              # CHANGED: servers map gains sh/bash = "bashls";
│                        #   <leader>lf undoes no-op format edits (research R3)
└── treesitter.lua       # CHANGED: LANGUAGES += "bash"; FILETYPES += sh/bash = "bash"
README.md                # CHANGED: requirements, <leader>lf row, Shell scripts section,
                         #          tree-sitter languages
```

**Structure Decision**: Follow the existing layout: server definitions in the runtime `lsp/`
directory, activation in `config.lsp`, parser data in `config.treesitter`. No new module.

## Implementation Notes

1. **`lsp/bashls.lua`**: the table from [data-model.md](data-model.md), with a header comment
   (as in `neocmake.lua`) explaining the root choice, that ShellCheck/shfmt are found on
   `PATH`, and why formatting is switched off without shfmt (R4). Keep the existing
   `server_capabilities` nil-check pattern.
2. **`lua/config/lsp.lua`**: add `sh = "bashls"` and `bash = "bashls"` to `servers`.
3. **`lua/config/treesitter.lua`**: add `"bash"` to `LANGUAGES` directly after `"asm"`, and
   `bash = "bash"`, `sh = "bash"` to `FILETYPES` directly after `asm = "asm"`, aligned as the
   existing entries.
4. **README**: Requirements entries for `bash-language-server` (`brew install
   bash-language-server`), `shellcheck` and `shfmt`, each optional with what is lost without
   it; `<leader>lf` row mentions shell scripts and `.editorconfig`; a short "Shell scripts"
   section (when the server starts, root, ShellCheck diagnostics, formatting via shfmt with
   indentation from `.editorconfig`, else 4 spaces, `gq` stays plain, zsh not covered);
   tree-sitter section adds "shell (sh/bash)" to the languages and to those with text
   objects (no classes).

## Implementation Deviations

- `<leader>lf` in `lua/config/lsp.lua` was changed although the plan kept it untouched:
  bashls resends the whole buffer when it is already formatted, which marked the buffer
  modified (US2-4). The format is now followed by an undo when it changed nothing; see
  research R3. lua_ls and clangd are unaffected (they send no edit in that case).

## Complexity Tracking

No constitution violations; nothing to justify.
