# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim configuration (targets Neovim 0.12+), built on native features rather than a
plugin-manager framework: `vim.pack.add` for plugins (no lazy.nvim/packer), native `vim.lsp.enable`
for LSP, and `mini.completion` for completion. There is no build step and no test suite — the
config is validated by starting Neovim and exercising the feature by hand.

## Development workflow

- Reload after edits by restarting Neovim, or re-source the changed file with `:source %`
  (autocmds/keymaps redefine cleanly; option changes need a restart to fully verify).
- Format Lua with `stylua` (invoked via `conform.nvim`, keymap `<Leader>cf`); cmake files format
  with `gersemi`. There's no separate lint step — `stylua`/LSP diagnostics are it.
- Check for errors on startup with `nvim --headless -c 'qa'` or open `:checkhealth`.
- Treesitter parsers install automatically on first launch for languages listed in
  `plugin/50-plugins.lua`; after adding a language there, restart Neovim once and wait for
  installation to finish before opening a matching file.
- Plugins are pinned in `nvim-pack-lock.json` (rev/src pairs) and installed via `vim.pack.add` calls
  in `plugin/50-plugins.lua` — there is no separate lockfile-sync command; `vim.pack` manages this
  natively.

## Load order and architecture

Files in `plugin/` are sourced automatically by Neovim in lexical order, which is why they're
numerically prefixed. This ordering is load-bearing:

1. `init.lua` — sets globals (`_G.Config` table, `mapleader`, disabled providers) and two helpers
   used by later files: `Config.new_autocmd` (thin wrapper that pins autocmds to a single shared
   augroup) and `Config.on_packchanged` (reacts to `vim.pack` plugin updates, e.g. to trigger
   `:TSUpdate`). Also sets the default colorscheme. Anything global must be set here, not in
   `plugin/*`.
2. `plugin/10-options.lua` — core `vim.opt` settings.
3. `plugin/20-keymaps.lua` — keymaps not owned by a specific plugin/LSP feature, plus
   `Config.leader_group_clues`, a table of `<Leader>` prefix descriptions (e.g. `<Leader>g` =
   "+Git") consumed by whichever which-key-style plugin reads it.
4. `plugin/30-autocmds.lua` — misc autocmds (currently just yank highlighting).
5. `plugin/40-lsp.lua` — enables LSP servers, diagnostic config/toggles, and the `LspAttach`
   autocmd that wires per-buffer behavior (completion via `mini.completion`, inlay hints, native
   LSP folding, document highlight, format-on-save (currently commented out)).
6. `plugin/50-plugins.lua` — declares plugins via `vim.pack.add` and configures each one
   immediately after adding it (see `conform.nvim` and `nvim-treesitter` setup inline).

`after/lsp/<name>.lua` files are per-server LSP configs (`vim.lsp.Config` tables), auto-loaded by
Neovim's native LSP client when a server of that name is enabled in `plugin/40-lsp.lua`. To add a
new LSP server: add its name to the `vim.lsp.enable({...})` list in `plugin/40-lsp.lua` and, if it
needs non-default settings, add `after/lsp/<name>.lua`.

## Colorschemes (`colors/`, `lua/retro/`)

The four custom colorschemes (`retro`, `retroplus`, `defaultplus`, `habamaxplus`, `lunapercheplus`)
are thin wrappers around `lua/retro/init.lua`'s `M.load(opts)`, which layers modern highlight groups
(Tree-sitter `@*` captures, LSP/diagnostics, semantic tokens, floating windows, `mini.nvim` groups)
on top of a built-in base colorscheme (`default`, `habamax`, `lunaperche`, or `retrobox`) that
otherwise lacks them. Each `colors/*.lua` file is a one-line call into this shared module — don't
duplicate highlight-group logic there; extend `lua/retro/init.lua` instead.

- `opts.base` selects which built-in colorscheme to load first and which palette (keyed by the same
  name in the `palettes` table) to use.
- `opts.flavor` selects the Tree-sitter capture mapping: `"plus"` assigns catppuccin-style semantic
  roles (e.g. `@variable.builtin` -> red, `@property` -> lavender) via `treesitter_plus`; `"classic"`
  links captures to retrobox's original base groups (e.g. `@type` -> `Type`) via `treesitter_retro`,
  preserving the plain retrobox look.
- Palettes are hand-derived per base colorscheme/background combo to approximate that theme's
  existing hues under catppuccin's role names — when adding a palette entry, match the base theme's
  actual colors, don't import catppuccin's colors directly.
- The active default colorscheme is set in `init.lua` (`retroplus`).
