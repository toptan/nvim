## Why

`plugin/40-lsp.lua` already references `MiniCompletion.completefunc_lsp` (it sets it as `omnifunc`
on `LspAttach` when a client supports completion), but `mini.completion` is never added as a
plugin and never configured — the reference is currently dead code, and there is no completion UI
at all. Per user conventions, all `mini.nvim` module configuration is to live in a new
`plugin/60-mini.lua` file.

## What Changes

- Add `mini.nvim` as a plugin (via `vim.pack.add`) and require only its `completion` module.
- Configure `mini.completion` in a new `plugin/60-mini.lua`:
  - LSP-sourced completion only — no snippet expansion (`lsp_completion.snippet_insert` set to a
    no-op).
  - Buffer-based fallback completion (Vim's built-in keyword completion) allowed only in buffers
    with no LSP client attached; disabled per-buffer when an LSP client with completion support is
    attached.
  - Insert-mode `<Tab>` / `<S-Tab>` move the popup selection down/up when the popup is visible,
    and behave as plain `<Tab>`/`<S-Tab>` otherwise.
  - Insert-mode `<Enter>` confirms the currently selected popup entry; otherwise behaves as a
    normal `<CR>`.
  - Completion triggers automatically as the user types; `<C-Space>` forces it on demand.
  - No item is preselected, **except** when exactly one candidate matches — that sole candidate is
    auto-selected so `<Enter>` confirms it immediately.
- **Modify** `plugin/40-lsp.lua`'s `LspAttach` handler: replace the current (incorrect —
  `mini.completion`'s auto-wiring uses `completefunc`, not `omnifunc`) manual omnifunc assignment
  with setting the buffer-local `vim.b.minicompletion_config.fallback_action` override described
  above.

## Capabilities

- **New Capabilities**: `completion` — a new `openspec/specs/completion/spec.md` covering
  `mini.completion`'s setup and behavior.
- **Modified Capabilities**:
  - `lsp-configuration` — the "Per-buffer LSP-attach behavior" requirement's completion-wiring
    clause changes from setting `omnifunc` to disabling completion fallback via
    `vim.b.minicompletion_config`.
  - `plugin-management` — adds `mini.nvim` to the set of declared/pinned plugins and documents
    that `mini.*` module setup lives in `plugin/60-mini.lua`.

## Impact

- New file: `plugin/60-mini.lua`.
- Modified file: `plugin/40-lsp.lua` (`LspAttach` callback only).
- `nvim-pack-lock.json` gains a `mini.nvim` entry once installed.
- No other plugin or keymap currently uses `<Tab>`/`<S-Tab>`/`<CR>` in insert mode, and
  `<C-Space>` is unbound today, so none of the new insert-mode mappings conflict with existing
  keymaps (`plugin/20-keymaps.lua` only maps `<Tab>`/`<S-Tab>` in normal mode, for buffer
  cycling).
