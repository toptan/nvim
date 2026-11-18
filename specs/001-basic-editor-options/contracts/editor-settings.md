# Contract: Editor Settings Guarantees

What later features (keymaps, plugins, LSP, UI) may rely on once this feature is in place.

## Load order

1. `init.lua` requires `config.options` first, then `config.colorscheme`.
2. Any module required after `config.options` can assume:
   - `vim.g.mapleader == " "` and `vim.g.maplocalleader == " "`.
   - All four providers are disabled; modules MUST NOT rely on Python, Node.js, Ruby or Perl
     remote plugins.
   - `vim.g.have_nerd_font == false`; modules MUST use ASCII/Unicode symbols, not Nerd Font
     icons, when this flag is false.

## Colour scheme

- After startup `vim.g.colors_name == "catppuccin"` (unless the scheme is unavailable, in which
  case the default scheme remains and no error is raised).
- The `ColorScheme` autocommand in augroup `config_transparency` clears the background of the
  transparent groups listed in [data-model.md](../data-model.md) on every scheme load.
  - Modules that add their own highlight overrides SHOULD do so in their own `ColorScheme`
    autocommand so overrides also survive reloads.
  - Floating-window groups (`NormalFloat`, `FloatBorder`) are **not** made transparent; later
    UI features decide that.

## Options

- Global indentation defaults (`expandtab`, `tabstop=4`, `shiftwidth=4`, `softtabstop=-1`) may
  be overridden buffer-locally. Modules MUST NOT reset them globally.
- `signcolumn="yes"` reserves exactly one sign column; features that need more (e.g. git signs
  plus diagnostics) MUST share it rather than widening it.
