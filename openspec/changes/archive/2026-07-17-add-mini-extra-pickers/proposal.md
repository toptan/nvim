## Why

`mini.pick` (added in `add-mini-indentscope-statusline-pick`) only wires up its seven *builtin*
pickers (`files`/`grep`/`grep_live`/`buffers`/`help`/`resume`/`cli`). `mini.extra` — part of the
same already-installed `mini.nvim` — supplies 24 additional `MiniExtra.pickers.*` sources (Git
files/branches/commits/hunks, LSP declarations/definitions/references/symbols, diagnostics, old
files, marks, registers, options, keymaps, colorschemes, and more) that reuse the same `mini.pick`
UI. The user asked for only the *pickers* part of `mini.extra` (not its other exports,
`gen_ai_spec`/`gen_highlighter`) wired up as new keymaps.

## What Changes

- Add `require("mini.extra").setup()` (no options) to `plugin/60-mini.lua`, placed after the
  existing `mini.pick` setup/keymap block.
- Add keymaps for 19 of `mini.extra`'s pickers that need no capability this config lacks, split
  across three existing (currently leaf-empty or partially-empty) leader groups:
  - **`<Leader>f` "+Find"** (15 new keymaps, alongside the existing `ff`/`fg`/`fG`/`fb`/`fh`/`fr`/
    `fc`): `fd` diagnostic, `fe` explorer, `fk` keymaps, `fl` buf_lines, `fm` manpages, `fM` marks,
    `fo` oldfiles, `fO` options, `fR` registers, `fs` spellsuggest, `fT` colorschemes, `fx`
    hl_groups, `fy` history, `fC` commands, `ft` treesitter.
  - **`<Leader>g` "+Git"** (4 new keymaps, group currently has no leaf keymaps): `gb`
    git_branches, `gc` git_commits, `gf` git_files, `gh` git_hunks.
  - **`<Leader>l` "+Language"** (8 new keymaps, group currently has no leaf keymaps): one per
    `mini.extra`'s `lsp` picker scope — `ld` declaration, `lD` definition, `lo` document_symbol,
    `li` implementation, `lr` references, `lt` type_definition, `lw` workspace_symbol, `lW`
    workspace_symbol_live.
- These 8 LSP-picker keymaps live **alongside**, not instead of, Neovim's existing built-in
  default LSP keymaps (`grr`/`gri`/`gO`/`gra`/`grn`, Neovim 0.11+) — same underlying LSP methods,
  different UI (a `mini.pick` list vs. jump-straight-to-single-result).
- Update `CLAUDE.md`'s `plugin/60-mini.lua` load-order bullet to mention `mini.extra`.

## Capabilities

- **Modified Capabilities**:
  - `fuzzy-finder` — adds `mini.extra` setup and 19 new pickers (general + Git) reachable via
    `<Leader>f*`/`<Leader>g*`. (Written as **ADDED** Requirements in this change's delta spec: the
    `fuzzy-finder` capability doesn't exist yet in `openspec/specs/` because the change that
    introduced it, `add-mini-indentscope-statusline-pick`, is implemented but not yet
    archived/synced — see Risks in `design.md`.)
  - `lsp-configuration` — adds 8 new `<Leader>l*` keymaps for `mini.extra`'s `lsp` picker scopes,
    documented as a new requirement alongside the existing LSP-attach/diagnostic requirements.

## Non-Goals (this change)

- `mini.extra.gen_ai_spec` and `mini.extra.gen_highlighter` — not pickers, not requested.
- `hipatterns` picker — requires `mini.hipatterns`, not installed.
- `visit_paths` / `visit_labels` pickers — require `mini.visits`, not installed. (Note:
  `Config.leader_group_clues` already reserves an unused `<Leader>v` "+Visits" group — natural
  home for these two in a future change that adds `mini.visits`.)
- `list` picker (quickfix/location/jump/change scopes) — no existing quickfix/loclist workflow in
  this config to hook it into; can be added later if one emerges.

## Impact

- Modified file: `plugin/60-mini.lua` (one new `setup()` call, 27 new keymaps).
- Modified file: `CLAUDE.md` (load-order bullet).
- No `vim.pack.add` or `nvim-pack-lock.json` changes — `mini.extra` ships inside the already-pinned
  `mini.nvim`.
- No colorscheme changes — pickers reuse `MiniPick*` highlight groups already themed for
  `mini.pick`.
- All 27 new keymaps land in groups with no existing leaf keymaps at those specific letters (see
  `design.md` for the full collision check against `ff`/`fg`/`fG`/`fb`/`fh`/`fr`/`fc` and every
  other keymap currently defined in `plugin/20-keymaps.lua` / `plugin/40-lsp.lua` /
  `plugin/60-mini.lua`).
- `git_*` pickers shell out to `git` (already required by `mini.pick`'s own `files`/`grep`
  fallback chain, confirmed present on this system).
