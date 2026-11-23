# Implementation Plan: Tree-sitter Parsers and Syntax-Aware Text Objects

**Branch**: `master` (no feature branch) | **Date**: 2026-11-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/012-treesitter-plugins/spec.md`

## Summary

Add nvim-treesitter and nvim-treesitter-textobjects (`main` branches) with the built-in
`vim.pack`. They are registered at startup with a no-op loader and `confirm = false`, and
loaded with `:packadd` on the first `FileType` of a supported language. That first file also
starts one asynchronous `install()` of the 12 listed parsers. Buffers whose parser was missing
switch to tree-sitter when the install finishes. A `PackChanged` hook marks one `update()` per
plugin change, run at once if the plugins are loaded, otherwise after the first supported file's
install. If build tools are missing, no install or update runs and one warning per session
names them (Principle IV). Each supported buffer gets core tree-sitter highlighting, plus folding,
nvim-treesitter indentation and buffer-local text objects and jumps (`af/if`, `ac/ic`,
`aa/ia`, `]f/[f`, `]c/[c`), each only where the language ships the matching query. `]c/[c`
fall back to the built-in diff jumps in diff windows. Everything lives in one new module,
`lua/config/treesitter.lua`.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: `vim.pack`, `vim.treesitter` (core); nvim-treesitter `main`,
nvim-treesitter-textobjects `main`. External: `git`, `curl`, `tar`, C compiler,
`tree-sitter` CLI ≥ 0.26.1 (verified 0.27.0)

**Storage**: none in the repository; parsers and queries in `stdpath("data")/site`, plugins in
the `vim.pack` directory, lockfile uncommitted

**Testing**: manual and headless-scripted checks per [quickstart.md](quickstart.md);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: +≤ 3 ms startup (measured 1.5–3 ms for `vim.pack.add`); no plugin code
on an empty buffer; first-time install of all parsers ≈ 4 s in the background

**Constraints**: startup < 100 ms; one message of our own at most (missing build tools); never raise; buffer-local keys
only; 80-column Lua style

**Scale/Scope**: 1 new module (~150 lines), 1 line in `init.lua`, README section

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Plugins only for what core lacks (parser install/update, queries, TS indent, text objects); highlighting, folding and injections use core APIs; plugin manager is core `vim.pack`; one-line justification beside each spec | ✅ |
| II. Modular Lua | One module `config.treesitter` for the tightly related plugin group; `init.lua` gains one `require`; state in module locals and `vim.b`; augroup `config_treesitter` with `clear = true` | ✅ |
| III. Fast, Deferred Startup | Only `vim.pack.add` (no loading) at startup; plugin code, installs and mappings on the first supported `FileType` | ✅ (see note) |
| IV. Reproducible & Fault-Tolerant | `confirm = false` → clone + start installs plugins; parsers install on first file; `pcall` around every plugin call; missing build tools → no install, a single WARN per session, and `:checkhealth`; README lists tools | ✅ |
| V. Consistent Style | `.editorconfig` style; every mapping has `desc`; lua_ls-clean | ✅ |
| Constraints | Neovim 0.12 stable APIs only; lockfile uncommitted; no vendored code | ✅ |
| Workflow | Spec Kit flow (new plugins); small commits | ✅ |

Note on III: `vim.pack.add` itself must run at startup so that plugins install on a fresh clone
and `PackChanged` sees installs. It sources nothing (no-op `load`). Measured at 1.5–3 ms, so
the 100 ms budget is not at risk.

**Post-design re-check**: still passes. The design deliberately ignores the plugin's "does not
support lazy-loading" note. Research R3 shows the reason does not apply to these 12 languages
(no extra filetype registrations needed; `:TS*` commands appear only after the first
supported file, which is accepted). No complexity entries are needed.

## Project Structure

### Documentation (this feature)

```text
specs/012-treesitter-plugins/
├── plan.md              # This file
├── research.md          # Phase 0: verified plugin behaviour and decisions
├── data-model.md        # Phase 1: language list, filetype map, install/attach state
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── treesitter.md    # plugins, autocommands, key mappings, messages
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # + require("config.treesitter") (after config.lsp)
lua/config/
├── treesitter.lua       # NEW: vim.pack specs, PackChanged hook, FileType attach/detach,
│                        #      parser install/update, text objects and jumps
└── …                    # unchanged
README.md                # requirements (tools), Tree-sitter section, key mappings table
```

**Structure Decision**: a single new module, following the existing `lua/config/<concern>.lua`
layout. No `plugin/` or `ftplugin/` files: one `FileType` handler covers all ten filetypes and
keeps the language list in one place.

## Risks

- **Plugin API drift on `main`**: both plugins are under active rewrite. Mitigated by the
  machine-local lockfile and by `pcall` around calls. Quickstart §6 catches breakage.
- **Multi-line build errors** may cause a hit-enter prompt. That is the plugin's own output,
  accepted under FR-012 (research R7).
- **`*.h` detected as `cpp`**: C headers use the C++ parser (Neovim default). Acceptable,
  since it is a superset for highlighting.
- **Bundled parsers**: this Neovim build bundles some parsers (e.g. c, lua, python). The
  installed ones in `site/parser` come first on `runtimepath` and match the plugin's queries.

## Complexity Tracking

No constitution violations.
