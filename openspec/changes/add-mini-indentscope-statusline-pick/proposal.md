## Why

`mini.nvim` is already installed and configured for twelve other modules. Three more modules
round out the editing experience: no indent-scope visualization (`mini.indentscope`), no
statusline (`mini.statusline` — Neovim's plain built-in statusline shows only a bare ruler, no
git/diagnostics/LSP info), and no fuzzy finder (`mini.pick` — no way to quickly find files, grep,
browse buffers/help, or re-open the last search). Adding them extends the existing `mini.nvim`
dependency rather than introducing new plugins. The colorscheme (`lua/retro/init.lua`) already
defines highlight groups for `MiniIndentscopeSymbol`, the full `MiniStatusline*` set, and the full
`MiniPick*` set, so all three light up correctly with no colorscheme changes needed.

## What Changes

- Add `mini.indentscope`, configured only to disable its step animation
  (`draw.animation = gen_animation.none()`) — every other option (default mappings `ii`/`ai`
  textobjects, `[i`/`]i` motions; default `border`/`indent_at_cursor`/`n_lines`/`try_as_border`
  options) stays at its default.
- Add `mini.statusline` with a custom `content.active` function that mirrors the module's own
  documented default content function, but replaces the single flat-colored diagnostics section
  with one segment per severity level (error/warn/info/hint), each colored with the same
  `DiagnosticError`/`DiagnosticWarn`/`DiagnosticInfo`/`DiagnosticHint` highlight groups already
  used for diagnostics elsewhere in this config (sign column, virtual text) — matching the ask to
  give diagnostics counts "the same coloring... as for the default status line['s diagnostic
  coloring elsewhere]". Everything else (mode, git, diff, LSP, filename, fileinfo, location,
  search count) stays exactly as `mini.statusline`'s own default content function produces it.
- Add `mini.pick`, called with `setup()` and no custom options, plus six new keymaps under the
  existing (currently leaf-empty) `<Leader>f` "+Find" group, covering all seven of its builtin
  pickers:
  - `<Leader>ff` — `files`
  - `<Leader>fg` — `grep_live` (live grep)
  - `<Leader>fG` — `grep` (prompts for a fixed pattern first)
  - `<Leader>fb` — `buffers`
  - `<Leader>fh` — `help`
  - `<Leader>fr` — `resume` (re-open the last picker)
  - `<Leader>fc` — `cli` (pick from an arbitrary shell command's output)

## Capabilities

- **New Capabilities**:
  - `indent-scope` — `mini.indentscope` with animation disabled, otherwise default configuration.
  - `statusline` — `mini.statusline` with per-severity-colored diagnostics counts, otherwise
    default content.
  - `fuzzy-finder` — `mini.pick` default setup, plus `<Leader>ff`/`fg`/`fG`/`fb`/`fh`/`fr`/`fc`
    keymaps for its seven builtin pickers.

## Impact

- Modified file: `plugin/60-mini.lua` (three new `setup()` calls — one with a custom animation
  option, one with a custom `content.active` function — and six new keymaps).
- No `vim.pack.add` changes and no new `nvim-pack-lock.json` entry — `mini.nvim` is already
  declared.
- No colorscheme changes needed — `lua/retro/init.lua` already themes `MiniIndentscopeSymbol` and
  the full `MiniStatusline*`/`MiniPick*` group sets from when the colorscheme module was
  originally written.
- `mini.pick`'s `grep_live` and `grep` builtins use `rg` (ripgrep) if present on `PATH`, else `git
  grep`, else a slow pure-Lua fallback (`grep_live` errors instead of falling back, for
  performance reasons); `files` similarly prefers `fd`, then `git`, then a Lua fallback. This
  system has `rg` and `git` on `PATH` (no `fd`), so all seven pickers work without any additional
  tool installation.
- No changes to `vim.o.laststatus` — `mini.statusline` doesn't set it itself and this config
  doesn't set it either; it relies on Neovim's existing default.
- All six new keymaps land in the currently-unused `<Leader>f` group — no existing mapping is
  shadowed.
