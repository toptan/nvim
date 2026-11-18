# Implementation Plan: Basic Editor Options

**Branch**: `master` (no feature branch) | **Date**: 2026-11-18 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-basic-editor-options/spec.md`

## Summary

Set the editor's baseline: Space as leader, providers disabled, no Nerd Font, 4-space
indentation defaults that yield to `.editorconfig`/ftplugins, hybrid line numbers, scroll offset
8, cursor line, colour column at 81, permanent sign column, Unicode whitespace symbols, and the
built-in `catppuccin` scheme with a transparent background that is re-applied on every scheme
load. Implemented with two Lua modules loaded from a thin `init.lua`, no plugins.

## Technical Context

**Language/Version**: Lua (LuaJIT, as embedded in Neovim 0.12.6)

**Primary Dependencies**: Neovim 0.12+ core only (bundled `catppuccin` colour scheme, built-in
editorconfig support); no plugins

**Storage**: N/A

**Testing**: Headless Neovim checks (`nvim --headless`), `:checkhealth`, `--startuptime`;
see [quickstart.md](quickstart.md)

**Target Platform**: Neovim 0.12+ in a true-colour terminal, macOS primary

**Project Type**: Editor configuration (single Neovim config directory)

**Performance Goals**: Startup on an empty buffer < 100 ms (Constitution III, SC-004)

**Constraints**: No plugins, no Nerd Font glyphs, no startup errors, `background` never forced

**Scale/Scope**: 3 Lua files, ~60 lines total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Native-First | No plugin when core suffices | ✅ No plugins; bundled `catppuccin`, built-in editorconfig |
| II. Modular Lua | Lua only; thin `init.lua`; one concern per module; augroups with `clear = true` | ✅ `init.lua` only requires; `config.options` and `config.colorscheme`; augroup `config_transparency` |
| III. Fast, Deferred Startup | Only first-buffer essentials eager | ✅ Options and colorscheme are explicitly allowed to load eagerly |
| IV. Reproducible & Fault-Tolerant | Clean headless start; no errors if something is missing | ✅ `colorscheme` wrapped in `pcall`; no external tools needed; README documents the Neovim 0.12+ requirement (T015) |
| V. Consistent Style | `.editorconfig` formatting; `lua_ls` clean; keymaps have `desc` | ✅ No keymaps in scope; files follow 2-space/80-col/double quotes |
| Tech constraints | Stable 0.12+ APIs only; macOS-safe | ✅ Only stable `vim.opt`, `vim.g`, `vim.api` APIs |
| Workflow | Verify via headless start + `:checkhealth` | ✅ Covered by quickstart steps 1 and 3 |

**Post-design re-check (after Phase 1)**: ✅ All gates still pass. The design adds no plugins,
no new external dependencies, and no globals beyond the documented `vim.g` flags.

## Project Structure

### Documentation (this feature)

```text
specs/001-basic-editor-options/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (settings catalogue)
├── quickstart.md        # Phase 1 output (validation guide)
├── contracts/
│   └── editor-settings.md   # Guarantees for later features
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
init.lua                     # Entry point: require("config.options"), require("config.colorscheme")
lua/
└── config/
    ├── options.lua          # Leader keys, provider flags, have_nerd_font, all vim.opt settings
    └── colorscheme.lua      # Transparency ColorScheme autocmd + pcall(colorscheme "catppuccin")
```

**Structure Decision**: Single Neovim config directory. Modules are namespaced under
`lua/config/` to avoid clashing with plugin module names (research R10). Leader keys and
provider flags live at the top of `config.options`, which `init.lua` loads first, so they precede
every later module (FR-005, R4). Colour handling is a separate concern in
`config.colorscheme`, which registers its `ColorScheme` autocommand before loading the scheme
(R2).

## Complexity Tracking

No constitution violations; nothing to justify.
