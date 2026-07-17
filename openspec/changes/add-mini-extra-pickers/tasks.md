## 1. Add mini.extra

- [x] 1.1 In `plugin/60-mini.lua`, add `require("mini.extra").setup()` (no options), placed after
      the existing `mini.pick` `setup()`/keymap block

## 2. Add general-picker keymaps under `<Leader>f`

- [x] 2.1 `<Leader>fd` → `require("mini.extra").pickers.diagnostic()`
- [x] 2.2 `<Leader>fe` → `require("mini.extra").pickers.explorer()`
- [x] 2.3 `<Leader>fk` → `require("mini.extra").pickers.keymaps()`
- [x] 2.4 `<Leader>fl` → `require("mini.extra").pickers.buf_lines()`
- [x] 2.5 `<Leader>fm` → `require("mini.extra").pickers.manpages()`
- [x] 2.6 `<Leader>fM` → `require("mini.extra").pickers.marks()`
- [x] 2.7 `<Leader>fo` → `require("mini.extra").pickers.oldfiles()`
- [x] 2.8 `<Leader>fO` → `require("mini.extra").pickers.options()`
- [x] 2.9 `<Leader>fR` → `require("mini.extra").pickers.registers()`
- [x] 2.10 `<Leader>fs` → `require("mini.extra").pickers.spellsuggest()`
- [x] 2.11 `<Leader>fT` → `require("mini.extra").pickers.colorschemes()`
- [x] 2.12 `<Leader>fx` → `require("mini.extra").pickers.hl_groups()`
- [x] 2.13 `<Leader>fy` → `require("mini.extra").pickers.history()`
- [x] 2.14 `<Leader>fC` → `require("mini.extra").pickers.commands()`
- [x] 2.15 `<Leader>ft` → `require("mini.extra").pickers.treesitter()`

## 3. Add Git-picker keymaps under `<Leader>g`

- [x] 3.1 `<Leader>gb` → `require("mini.extra").pickers.git_branches()`
- [x] 3.2 `<Leader>gc` → `require("mini.extra").pickers.git_commits()`
- [x] 3.3 `<Leader>gf` → `require("mini.extra").pickers.git_files()`
- [x] 3.4 `<Leader>gh` → `require("mini.extra").pickers.git_hunks()`

## 4. Add LSP-picker keymaps under `<Leader>l`

- [x] 4.1 `<Leader>ld` → `require("mini.extra").pickers.lsp({ scope = "declaration" })`
- [x] 4.2 `<Leader>lD` → `require("mini.extra").pickers.lsp({ scope = "definition" })`
- [x] 4.3 `<Leader>lo` → `require("mini.extra").pickers.lsp({ scope = "document_symbol" })`
- [x] 4.4 `<Leader>li` → `require("mini.extra").pickers.lsp({ scope = "implementation" })`
- [x] 4.5 `<Leader>lr` → `require("mini.extra").pickers.lsp({ scope = "references" })`
- [x] 4.6 `<Leader>lt` → `require("mini.extra").pickers.lsp({ scope = "type_definition" })`
- [x] 4.7 `<Leader>lw` → `require("mini.extra").pickers.lsp({ scope = "workspace_symbol" })`
- [x] 4.8 `<Leader>lW` →
      `require("mini.extra").pickers.lsp({ scope = "workspace_symbol_live" })`

## 5. Manual verification

Drive via `nvim --headless --listen <socket>` + `nvim --server <socket> --remote-send`, so real
key sequences can be observed via RPC (same approach as the prior `mini.pick` change).

- [x] 5.1 `nvim --headless -c 'qa'` reports no startup errors after `mini.extra.setup()` and all 27
      keymaps are added
- [x] 5.2 `<Leader>fd`/`fe`/`fk`/`fl`/`fm`/`fM`/`fo`/`fO`/`fR`/`fs`/`fT`/`fx`/`fy`/`fC`/`ft` each
      open the expected picker (verify by picker window title / first listed item matches the
      requirement's description)
- [x] 5.3 In a Git repository: `<Leader>gb`/`gc`/`gf`/`gh` each open the expected Git picker;
      `gf` lists only tracked files, `gh` lists only unstaged hunks
- [x] 5.4 Outside a Git repository: `<Leader>gb` (or any `git_*` keymap) errors clearly rather than
      silently doing nothing (`H.validate_git` behavior)
- [x] 5.5 In a Lua file attached to `lua_ls` with a symbol that has multiple references: `<Leader>lr`
      opens a `mini.pick` picker listing them (not an immediate jump)
- [x] 5.6 In the same buffer, a symbol with exactly one reference: `<Leader>lr` jumps directly with
      no picker window shown
- [x] 5.7 `<Leader>lo` opens a picker listing the current buffer's document symbols
- [x] 5.8 `<Leader>lw` opens a picker listing all workspace symbols (empty query); `<Leader>lW`
      opens a picker whose matches update as a query is typed
- [x] 5.9 `mini.clue`'s `<Leader>` popup shows populated `g` and `l` groups (previously empty) with
      no changes needed to `mini.clue.setup()`'s trigger list
- [x] 5.10 `:checkhealth mini.nvim` shows no new errors beyond the pre-existing "No healthcheck
      found" (expected, per prior `mini.nvim` changes)

## 6. Docs

- [x] 6.1 Update `CLAUDE.md`'s load-order section (item on `plugin/60-mini.lua`) to mention
      `mini.extra` alongside the modules already listed there
