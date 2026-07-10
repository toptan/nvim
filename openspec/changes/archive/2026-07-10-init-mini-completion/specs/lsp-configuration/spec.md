## MODIFIED Requirements

### Requirement: Per-buffer LSP-attach behavior
The system SHALL, on `LspAttach`, configure per-buffer behavior conditional on client
capabilities: if the client supports completion, disable `mini.completion`'s buffer-based
fallback completion for that buffer (via a buffer-local `vim.b.minicompletion_config` override)
so only LSP-sourced completions are offered there; expose an inlay-hint toggle keymap
(`<Leader>th`, buffer-local) if the client supports inlay hints; enable expression folding via
`vim.lsp.foldexpr()` if the client supports folding range; and, if the client supports document
highlight, highlight references on `CursorHold`/`CursorHoldI` and clear them on `CursorMoved`/
`CursorMovedI` (via a per-buffer augroup named `LspHighlight_<bufnr>`).

#### Scenario: A completion-capable server attaches
- **WHEN** an LSP client supporting `textDocument/completion` attaches to a buffer
- **THEN** that buffer's `vim.b.minicompletion_config` is set so buffer-based fallback
  completion is disabled for that buffer, leaving only LSP-sourced completions available

#### Scenario: An inlay-hint-capable server attaches
- **WHEN** an LSP client supporting `textDocument/inlayHint` attaches to a buffer
- **THEN** a buffer-local `<Leader>th` keymap is created that toggles inlay hints for that buffer

#### Scenario: Holding the cursor over a symbol
- **WHEN** an LSP client supporting `textDocument/documentHighlight` is attached and the cursor
  rests on a symbol
- **THEN** references to that symbol are highlighted, and clearing on cursor move removes the
  highlight
