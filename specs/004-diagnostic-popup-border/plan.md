# Implementation Plan: Prominent Diagnostic Popup

**Branch**: `master` (no feature branch) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-diagnostic-popup-border/spec.md`

## Summary

Give every floating popup a visible border and make the diagnostic popup easier to read, using
core Neovim only:

- **Border on all popups**: `'winborder' = "rounded"` in `config.options`. It is the default
  border for every float that does not choose its own (R1).
- **Visible border colour**: the bundled catppuccin draws `FloatBorder` almost in the background
  colour, in both dark and light mode (R2). The existing `ColorScheme` autocommand in
  `config.colorscheme` re-derives it from `FloatTitle` fg on `NormalFloat` bg, so it follows
  the dark/light reload.
- **Diagnostic popup contents**: `config.diagnostics.setup()` adds
  `float = { title = " Diagnostics ", header = "", source = true }`. Severity colouring is
  already core behaviour (R3).
- No keymaps and no plugins. `vim.diagnostic` still loads lazily.

## Technical Context

**Language/Version**: Lua (LuaJIT, as embedded in Neovim 0.12.6)

**Primary Dependencies**: Neovim 0.12+ core (`'winborder'`, `vim.diagnostic.config` `float`
options, `nvim_get_hl`/`nvim_set_hl`). Colour scheme: bundled `catppuccin`.

**Storage**: N/A

**Testing**: Headless probes, manual scenarios, `--startuptime`, `:checkhealth`; see
[quickstart.md](quickstart.md)

**Target Platform**: Neovim 0.12+ in a terminal, macOS primary

**Project Type**: Editor configuration (single Neovim config directory)

**Performance Goals**: Startup unchanged. One option assignment, and one extra `nvim_set_hl` in
an existing autocommand. Must stay < 100 ms (Constitution III).

**Constraints**:
- No plugins.
- No key mapping changes.
- No Nerd Font glyphs.
- Explicit plugin borders are respected.
- `vim.diagnostic` must not load at startup.

**Scale/Scope**: 3 existing modules edited (`options`, `colorscheme`, `diagnostics`), ~20 lines.
No new files and no README change (no new dependency or mapping).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|-----------|------|--------|
| I. Native-First | No plugin when core suffices | ✅ `'winborder'` and `vim.diagnostic` float options; no UI plugin (R1, R3) |
| II. Modular Lua | One concern per module; named augroups with `clear = true` | ✅ The border option goes in `config.options`, the colour in `config.colorscheme` (inside the existing `config_transparency` augroup), and the popup contents in `config.diagnostics`. No new globals and no new augroups |
| III. Fast, Deferred Startup | Feature-tied code loads on trigger | ✅ The diagnostic float config rides the existing deferred `M.setup()`. The option and highlight cost is negligible |
| IV. Reproducible & Fault-Tolerant | No startup errors; graceful degradation | ✅ The highlight step skips if `FloatTitle` has no fg. Headless start is checked in quickstart §1 |
| V. Consistent Style | `.editorconfig`; `lua_ls` clean; keymaps have `desc` | ✅ No keymaps. The edited files must stay `lua_ls`-clean and format-stable (quickstart §6) |
| Tech constraints | Stable 0.12 APIs only | ✅ `'winborder'` is in 0.11+. All behaviour verified on 0.12.6 |
| Workflow | Verify via headless start + `:checkhealth` + manual run | ✅ Quickstart §1–§6 |

**Post-design re-check (after Phase 1)**: ✅ All gates still pass. Research changed one spec edge
case (popup when diagnostics are off) to match core behaviour instead of adding a mapping or a
monkey-patch (R4).

## Project Structure

### Documentation (this feature)

```text
specs/004-diagnostic-popup-border/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (border option, border colour, float style)
├── quickstart.md        # Phase 1 output (validation guide)
├── contracts/
│   └── popup-style.md   # What every popup and the diagnostic popup guarantee
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
lua/
└── config/
    ├── options.lua      # + vim.opt.winborder = "rounded"
    ├── colorscheme.lua  # + FloatBorder derived from FloatTitle/NormalFloat in ColorScheme autocmd
    └── diagnostics.lua  # + float = { title, header, source } in M.setup()
```

**Structure Decision**:
- Each change goes into the module that already owns its concern:
  - editor options → `config.options`
  - highlight adjustments → `config.colorscheme`
  - diagnostic display → `config.diagnostics`
- No new module is warranted for ~20 lines.

## Complexity Tracking

No constitution violations; nothing to justify.
