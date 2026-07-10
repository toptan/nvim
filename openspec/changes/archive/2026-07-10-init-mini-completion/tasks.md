## 1. Add the plugin

- [x] 1.1 Create `plugin/60-mini.lua` and add `mini.nvim` via `vim.pack.add`
- [x] 1.2 Restart Neovim once and confirm `mini.nvim` installs and `nvim-pack-lock.json` gains an
      entry for it

## 2. Configure mini.completion

- [x] 2.1 In `plugin/60-mini.lua`, call `require("mini.completion").setup({...})` with:
      - `lsp_completion.snippet_insert = function() end` (no snippet expansion)
      - `mappings.force_twostep = "<C-Space>"` (explicit, matches default)
- [x] 2.2 Add the insert-mode `<Tab>`/`<S-Tab>`/`<CR>` expr-mappings (see `design.md` §4)
- [x] 2.3 Add the `CompleteChanged` autocommand that auto-selects a sole match (see `design.md`
      §5)

## 3. Wire LSP-attach behavior

- [x] 3.1 In `plugin/40-lsp.lua`'s `LspAttach` callback, replace the
      `vim.bo[buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"` line with setting
      `vim.b[buf].minicompletion_config = { fallback_action = function() end }` when
      `client:supports_method("textDocument/completion")`

## 4. Manual verification

Driven end-to-end via `nvim --headless --listen <socket>` + `nvim --server <socket> --remote-send`
so real Insert-mode typing and async LSP completion could be observed via RPC.

- [x] 4.1 In a buffer with an LSP client attached (e.g. a Lua file): type to trigger completion
      automatically; confirm no buffer-keyword fallback appears when LSP returns zero matches
- [x] 4.2 In a buffer with no LSP client attached (e.g. plain text): confirm buffer-keyword
      completion (`<C-n>`-style fallback) still works
- [x] 4.3 Confirm `<Tab>`/`<S-Tab>` move the popup selection down/up, and behave normally when the
      popup is closed
- [x] 4.4 Confirm `<Enter>` accepts the selected item, and inserts a plain newline when nothing is
      selected
- [x] 4.5 Confirm `<C-Space>` forces a completion request on demand
- [x] 4.6 Confirm a completion item with `insertTextFormat = Snippet` is inserted as plain text
      with no tabstop/placeholder expansion
- [x] 4.7 Confirm that with exactly one matching candidate it is auto-selected (Enter accepts
      immediately), and that with two or more candidates none is preselected
- [x] 4.8 `:checkhealth mini.completion` — mini.nvim ships no per-module healthcheck (reports "No
      healthcheck found"), so this doesn't apply; no startup errors were observed in any of the
      manual runs above instead.

## 5. Docs

- [x] 5.1 Update `CLAUDE.md`'s load-order section to mention `plugin/60-mini.lua`
