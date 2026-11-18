# Research: Basic Editor Options

All findings below were verified against the installed Neovim 0.12.6 runtime
(`/opt/homebrew/Cellar/neovim/0.12.6/share/nvim/runtime`). No NEEDS CLARIFICATION items remain.

## R1. Built-in `catppuccin` and light/dark selection

- **Decision**: Load the bundled `catppuccin` scheme with `vim.cmd.colorscheme("catppuccin")` and
  never set `background`.
- **Rationale**: `colors/catppuccin.vim` is "Catppuccin Latte (for light) and Mocha (for dark)"
  and branches on `&background`; it does not set `background` itself. Neovim detects the
  terminal background at startup and updates `background`. Changing `background` while a
  scheme is active reloads the scheme (verified: `ColorScheme` fired again after
  `background=light`), so the palette follows the terminal automatically (FR-006).
- **Alternatives considered**: forcing `background=dark` (rejected by clarification);
  installing the `catppuccin/nvim` plugin (violates Principle I — the built-in scheme suffices).

## R2. Transparent background that survives reloads

- **Decision**: In a `ColorScheme` autocommand (augroup with `clear = true`), set `bg = "NONE"`
  on `Normal`, `NormalNC`, `SignColumn`, `LineNr`, `CursorLineNr`, `FoldColumn` and
  `EndOfBuffer`; create the autocommand *before* calling `colorscheme` so the first load is
  covered too.
- **Rationale**: Every scheme load — first load, `:colorscheme`, and the reload triggered by a
  `background` change (R1) — fires `ColorScheme`, so one hook covers FR-007 and both related
  edge cases. Clearing only `bg` keeps the scheme's foreground colours. `CursorLine` and
  `ColorColumn` keep their background so FR-008/FR-009 stay visible.
- **Alternatives considered**: setting highlights once after `colorscheme` (lost on any reload);
  a transparency plugin (Principle I).

## R3. Indentation defaults that yield to `.editorconfig` and filetype conventions

- **Decision**: Global options `expandtab = true`, `tabstop = 4`, `shiftwidth = 4`,
  `softtabstop = -1`. Leave `vim.g.editorconfig` at its default (enabled) and do not set any
  `*_recommended_style` globals.
- **Rationale**: Global options are defaults; filetype plugins and the built-in editorconfig
  handler set buffer-local values afterwards, so they win (FR-002a). Verified behaviour:
  - editorconfig `indent_size = n` sets `shiftwidth = n`, `softtabstop = -1`, and `tabstop = n`.
  - `ftplugin/make.vim` and `ftplugin/go.vim` set `noexpandtab softtabstop=0 shiftwidth=0`.
  `softtabstop = -1` makes the Tab key follow `shiftwidth`, so if a filetype changes only
  `shiftwidth` the Tab key still matches the indent width.
- **Alternatives considered**: `softtabstop = 4` (Tab key would disagree with a filetype's
  2-space indent); enforcing options in a `FileType` autocmd (rejected by clarification).

## R4. Disabling providers

- **Decision**: Set `vim.g.loaded_python3_provider`, `loaded_node_provider`,
  `loaded_ruby_provider` and `loaded_perl_provider` to `0` before anything else runs.
- **Rationale**: These are the documented switches (`:h provider`); with them set, Neovim skips
  host discovery and `:checkhealth vim.provider` reports each provider as disabled (FR-013,
  SC-003). They must be set early, before any plugin can trigger provider loading.
- **Alternatives considered**: none; this is the only supported mechanism.

## R5. Leader keys

- **Decision**: `vim.g.mapleader = " "` and `vim.g.maplocalleader = " "` as the first statements
  executed by the config.
- **Rationale**: `<Leader>` is expanded when a mapping is defined, so it must be set before any
  module defines mappings (FR-005).

## R6. Visible whitespace

- **Decision**: `list = true`, `listchars = { tab = "» ", trail = "·", nbsp = "␣",
  extends = "›", precedes = "‹" }`.
- **Rationale**: Matches the clarified symbol set (FR-011). `eol`, `lead`, `space` and
  `multispace` are left unset so line ends and leading spaces are not marked. All characters are
  in the Latin-1 / General Punctuation / Control Pictures Unicode blocks, present in common
  monospace fonts (FR-012).

## R7. Nerd Font flag

- **Decision**: `vim.g.have_nerd_font = false`.
- **Rationale**: A widely used convention that later plugin configs can read to choose
  ASCII/Unicode fallbacks instead of icons (FR-012, "record that no Nerd Font is available").

## R8. Colour column, cursor line, sign column, scroll offset, numbers

- **Decision**: `colorcolumn = "81"`, `cursorline = true`, `signcolumn = "yes"`,
  `scrolloff = 8`, `number = true`, `relativenumber = true`.
- **Rationale**: `"81"` is an absolute column, independent of `textwidth`. A relative value such
  as `"+1"` was rejected: editorconfig `max_line_length` sets `textwidth` per project, and with
  `textwidth = 0` (the default) `"+1"` shows no column at all. `signcolumn = "yes"` reserves a
  single sign column permanently (FR-010).

## R9. `termguicolors`

- **Decision**: Do not set it.
- **Rationale**: Neovim enables it automatically when the terminal supports true colour, and
  `catppuccin.vim` provides both GUI and 256-colour definitions.

## R10. Module layout and load order

- **Decision**: `init.lua` loads `config.options` and then `config.colorscheme`. Modules live
  under `lua/config/`.
- **Rationale**: The `config.` namespace prevents a clash with a plugin's top-level module
  name (e.g. a plugin shipping `lua/options.lua`). Options first guarantees that leader keys and
  provider flags are set before anything else (Principle II, FR-005, R4).
