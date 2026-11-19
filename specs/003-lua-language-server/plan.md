# Implementation Plan: Lua Language Server and Diagnostic Toggles

**Branch**: `master` (no feature branch) | **Date**: 2026-11-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-lua-language-server/spec.md`

## Summary

Add `lua_ls` through Neovim's native LSP client:

- **Server definition**: `lsp/lua_ls.lua`. Its `on_init` hook injects `$VIMRUNTIME` and the
  paths of every `vim.pack` plugin as libraries, plus LuaJIT and `lua/?.lua` resolution,
  unless the project has its own `.luarc.json(c)`.
- **Start-up**: the server is enabled on the first `FileType lua`, so startup cost is
  unchanged.
- **Diagnostic toggles**: three global toggles (`<leader>td/tt/tl`) built on
  `vim.diagnostic.enable`/`config`. The display starts with virtual text on and virtual lines
  off.
- **Formatting**: `<leader>lf` formats synchronously with `vim.lsp.buf.format`, using lua_ls's
  built-in `.editorconfig`-aware formatter. It shows a clear message when the buffer is
  read-only or nothing can format it.
- **Missing server**: handled silently by core and reported by `:checkhealth vim.lsp`.
- No plugins.

## Technical Context

**Language/Version**: Lua (LuaJIT, as embedded in Neovim 0.12.6)

**Primary Dependencies**: Neovim 0.12+ core (`vim.lsp.config`/`enable`, `vim.diagnostic`,
`vim.lsp.buf.format`, `vim.pack.get`). External: `lua-language-server` 3.x (verified 3.19.2).

**Storage**: N/A

**Testing**: Headless Neovim probes, manual scenarios, `--startuptime`, `:checkhealth`; see
[quickstart.md](quickstart.md)

**Target Platform**: Neovim 0.12+ in a terminal, macOS primary

**Project Type**: Editor configuration (single Neovim config directory)

**Performance Goals**: Startup unchanged (measured baseline ≈ 8 ms; eager LSP would add
≈ 4.5 ms, so it is deferred, R2). Must stay < 100 ms (Constitution III).

**Constraints**:
- No plugins.
- Exactly four new mappings, all normal mode.
- No hard-coded absolute paths.
- No message when the server is missing.

**Scale/Scope**: 1 runtime file (`lsp/lua_ls.lua`), 2 new modules, `init.lua` and README
edits; ~120 lines

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Native-First | No plugin when core suffices | ✅ Native `vim.lsp.config`/`enable` and `lsp/` file instead of `nvim-lspconfig`. `on_init` library injection instead of `lazydev.nvim`. Server formatter instead of `conform.nvim` (R1, R3, R6) |
| II. Modular Lua | Thin `init.lua`; one concern per module; named augroups with `clear = true` | ✅ `config.lsp` (enable + format key) and `config.diagnostics` (display + toggles). Augroups `config_lsp` (deferred enable) and `config_diagnostics` (one-time `DiagnosticChanged` setup), each in the module that owns the concern. `init.lua` gains two `require`s only |
| III. Fast, Deferred Startup | Filetype-tied features load on trigger | ✅ `vim.lsp` and `vim.diagnostic` load on first `FileType lua` or first key press. Startup measured unchanged (R2) |
| IV. Reproducible & Fault-Tolerant | No startup errors; missing tools degrade silently; deps in README | ✅ Paths found at run time (`$VIMRUNTIME`, `vim.pack.get`). Missing server is silent (R7). `vim.pack.get` is `pcall`-wrapped. README lists `lua-language-server` (FR-019) |
| V. Consistent Style | `.editorconfig`; `lua_ls` clean; every keymap has `desc` | ✅ This feature makes the `lua_ls` gate checkable. Quickstart §8 requires 0 diagnostics and format-stable files. All four mappings have `desc` |
| Tech constraints | Stable 0.12 APIs only | ✅ All APIs used were verified on 0.12.6 |
| Workflow | Verify via headless start + `:checkhealth` + manual run | ✅ Quickstart §1–§8 |

**Post-design re-check (after Phase 1)**: ✅ All gates still pass. The only new module state is
a `did_setup` flag in `config.diagnostics`. There are no new `vim.g` globals, and no
buffer-local or `LspAttach` mappings.

## Project Structure

### Documentation (this feature)

```text
specs/003-lua-language-server/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (server config, display state, format outcomes)
├── quickstart.md        # Phase 1 output (validation guide)
├── contracts/
│   └── keymaps-and-lsp.md   # Mappings, messages, config.diagnostics API, server guarantees
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
init.lua                     # + require("config.diagnostics"), require("config.lsp")
lsp/
└── lua_ls.lua               # NEW: native server config; on_init runtime/plugin injection
lua/
└── config/
    ├── options.lua          # unchanged
    ├── colorscheme.lua      # unchanged
    ├── search.lua           # unchanged
    ├── keymaps.lua          # unchanged
    ├── autocmds.lua         # unchanged
    ├── diagnostics.lua      # NEW: setup() + <leader>td/tt/tl
    └── lsp.lua              # NEW: deferred enable on FileType lua + <leader>lf
README.md                    # + lua-language-server requirement, four mappings
```

**Structure Decision**:
- **`lsp/lua_ls.lua`** sits at the root because Neovim picks up `lsp/<name>.lua` from the
  runtimepath automatically. It holds only the server definition.
- **`config.diagnostics`** owns how diagnostics are displayed and the three toggles. Its
  one-time `DiagnosticChanged` autocommand (augroup `config_diagnostics`) applies the initial
  display for any diagnostics source.
- **`config.lsp`** owns language-server activation and server-backed actions (`<leader>lf`).
  Its `FileType` hook calls `require("config.diagnostics").setup()` before enabling the
  server.
- The four mappings live in their concern modules rather than `config.keymaps`, which stays
  for general-purpose mappings. This follows the `config.search` precedent.

## Complexity Tracking

No constitution violations; nothing to justify.
