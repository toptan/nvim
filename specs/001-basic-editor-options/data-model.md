# Data Model: Basic Editor Options

This feature has no persistent data. Its "data" is the catalogue of editor settings the
configuration sets at startup. Each row maps a requirement to the concrete setting and to how
the value is verified (see [quickstart.md](quickstart.md)).

## Entity: Global variable (`vim.g`)

Set before any other module runs.

| Name | Value | Requirement | Notes |
|------|-------|-------------|-------|
| `mapleader` | `" "` | FR-005 | Must precede every mapping |
| `maplocalleader` | `" "` | FR-005 | Must precede every mapping |
| `loaded_python3_provider` | `0` | FR-013 | |
| `loaded_node_provider` | `0` | FR-013 | |
| `loaded_ruby_provider` | `0` | FR-013 | |
| `loaded_perl_provider` | `0` | FR-013 | |
| `have_nerd_font` | `false` | FR-012 | Read by later features |

## Entity: Global option (`vim.opt` / `vim.o`)

Global defaults; buffer-local values from `.editorconfig` or ftplugins override them (FR-002a).

| Option | Value | Requirement |
|--------|-------|-------------|
| `expandtab` | `true` | FR-001 |
| `tabstop` | `4` | FR-002 |
| `shiftwidth` | `4` | FR-002 |
| `softtabstop` | `-1` (follow `shiftwidth`) | FR-002 |
| `number` | `true` | FR-003 |
| `relativenumber` | `true` | FR-003 |
| `scrolloff` | `8` | FR-004 |
| `cursorline` | `true` | FR-008 |
| `colorcolumn` | `"81"` | FR-009 |
| `signcolumn` | `"yes"` | FR-010 |
| `list` | `true` | FR-011 |
| `listchars` | `tab:» ,trail:·,nbsp:␣,extends:›,precedes:‹` | FR-011, FR-012 |

Options deliberately **not** set: `background` (FR-006, terminal detection decides),
`termguicolors` (auto-detected), `vim.g.editorconfig` (stays enabled, FR-002a).

## Entity: Colour scheme state

| Field | Value | Requirement |
|-------|-------|-------------|
| `vim.g.colors_name` | `"catppuccin"` | FR-006 |
| Palette | Mocha when `background=dark`, Latte when `light` | FR-006 |
| Transparent groups (`bg = NONE`) | `Normal`, `NormalNC`, `SignColumn`, `LineNr`, `CursorLineNr`, `FoldColumn`, `EndOfBuffer` | FR-007 |

### State transitions

```text
startup ──colorscheme catppuccin──▶ [loaded] ──ColorScheme──▶ transparency applied
[loaded] ──background changes (terminal detection)──▶ scheme reloads ──ColorScheme──▶ transparency re-applied
[loaded] ──:colorscheme <any>──▶ new scheme ──ColorScheme──▶ transparency re-applied
startup ──catppuccin missing──▶ error caught, default scheme kept, no startup error
```
