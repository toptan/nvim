## Context

`mini.completion` (from `mini.nvim`) is referenced but not yet installed or configured:
`plugin/40-lsp.lua`'s `LspAttach` handler already sets
`vim.bo[buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"` when a client supports
completion, anticipating this plugin. This change adds the plugin and its configuration, and
corrects that anticipatory wiring.

`mini.completion`'s relevant default config (for reference):

```lua
{
  lsp_completion = {
    source_func = 'completefunc', -- wires vim.bo.completefunc, NOT omnifunc
    auto_setup = true,            -- wires source_func on every buffer via BufEnter
    snippet_insert = nil,         -- nil => uses mini.snippets or vim.snippet.expand
  },
  fallback_action = '<C-n>',      -- built-in keyword completion, used when LSP yields nothing
  mappings = {
    force_twostep = '<C-Space>',  -- already the desired "force completion" key
    force_fallback = '<A-Space>',
  },
}
```

`H.get_config()` merges `vim.b.minicompletion_config` over the global config on every completion
request, so buffer-local overrides (e.g. per-LSP-attachment) are picked up dynamically without
re-running `setup()`.

## Goals / Non-Goals

**Goals**
- LSP is the only completion source; buffer-keyword fallback only applies where no LSP client
  with completion support is attached.
- No snippet expansion.
- `<Tab>`/`<S-Tab>` navigate the popup; `<Enter>` confirms; automatic trigger + `<C-Space>` to
  force.
- Nothing preselected unless there is exactly one match.
- Fix the existing dead/incorrect `omnifunc` wiring in `plugin/40-lsp.lua` as part of this change.

**Non-Goals**
- No signature-help or documentation-window styling changes (`window.info`/`window.signature`
  keep their defaults).
- No other `mini.nvim` modules are added in this change.

## Decisions

### 1. `source_func` stays default (`completefunc`); the old `omnifunc` line is replaced
`mini.completion`'s own `auto_setup` (default `true`) wires `vim.bo.completefunc` to
`MiniCompletion.completefunc_lsp` automatically on every buffer via its own `BufEnter`
autocommand — this is *not* conditional on an LSP client being attached, and that's fine: if no
client is attached, the LSP step yields nothing and `fallback_action` (buffer-keyword) applies,
which is the desired non-LSP behavior. The current `LspAttach` line setting `omnifunc` is
therefore both redundant (it's the wrong Vim option for how `mini.completion` triggers) and dead
weight, and is replaced by the fallback-disabling override below.

**Alternative considered**: keep the `omnifunc` line and add the new logic alongside it. Rejected
— it doesn't do anything useful for `mini.completion` and would read as a second, unrelated
completion mechanism.

### 2. Disabling buffer fallback per-buffer via `vim.b.minicompletion_config`
In `plugin/40-lsp.lua`'s `LspAttach` callback, when
`client:supports_method("textDocument/completion")`, set:

```lua
vim.b[buf].minicompletion_config = { fallback_action = function() end }
```

This buffer-local table is deep-merged over the global config on every completion request, so it
only affects buffers with a completion-capable client attached; other buffers keep the default
`<C-n>` fallback.

**Alternative considered**: a global `fallback_action = function() end` in `plugin/60-mini.lua`.
Rejected — it would also kill buffer-keyword completion in buffers with no LSP at all (e.g. plain
text files), which the user wants to keep.

### 3. Disabling snippets via a no-op `snippet_insert`
Set `lsp_completion.snippet_insert = function() end` in `plugin/60-mini.lua`. `mini.completion`
already inserts the plain filter/label text (not the raw `$1`-style snippet body) as the popup
entry's word for snippet-format items — `snippet_insert` only governs the *post-confirmation*
tabstop-expansion step, so a no-op here means "insert the plain text and stop," with no leftover
placeholder syntax.

### 4. Tab / Shift-Tab / Enter mappings (insert mode, expr-mappings)
```lua
local imap = function(lhs, rhs) vim.keymap.set("i", lhs, rhs, { expr = true }) end

imap("<Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end)
imap("<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end)
imap("<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "<C-y>"
  end
  return "<CR>"
end)
```
Checked against existing keymaps: `plugin/20-keymaps.lua` only maps `<Tab>`/`<S-Tab>` in normal
mode (buffer cycling); no existing mapping touches insert-mode `<Tab>`, `<S-Tab>`, `<CR>`, or
`<C-Space>`. No conflicts.

### 5. Preselecting the sole match
`mini.completion` sets `completeopt` to `menuone,noselect` (if not already set), which by itself
never preselects anything — including when there's only one match. There is no built-in
"preselect only if sole match" option, so this needs an explicit `CompleteChanged` autocommand in
`plugin/60-mini.lua`:

```lua
vim.api.nvim_create_autocmd("CompleteChanged", {
  callback = function()
    local info = vim.fn.complete_info({ "items", "selected" })
    if info.selected == -1 and #info.items == 1 then
      vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "n", false)
    end
  end,
})
```
This is the one piece of custom behavior not natively expressed by a `mini.completion` config
option — flagged here so it gets extra attention/testing during implementation (interaction with
the `<Tab>`→`<C-n>` mapping and with `force_fallback`/two-step completion should be manually
verified, e.g. does re-feeding `<C-n>` ever visibly flicker the popup).

## Risks / Trade-offs

- **Custom `CompleteChanged` auto-select** → not part of `mini.completion` itself, so a future
  `mini.nvim` update could change `complete_info()`/`CompleteChanged` timing. Mitigation: covered
  by the manual verification step in `tasks.md`; keep the logic isolated in one autocommand so
  it's easy to revisit.
- **Removing the `omnifunc` line** changes existing (currently inert) LSP-attach behavior.
  Mitigation: it was never functional for `mini.completion` in the first place (wrong option
  name), so there's no working behavior to regress.

## Open Questions

- None — scope is intentionally limited to `mini.completion`; other `mini.nvim` modules can be
  proposed as separate changes against `plugin/60-mini.lua` once it exists.
