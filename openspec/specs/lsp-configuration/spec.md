## Purpose

Defines LSP server enablement, diagnostic display/config, and per-buffer LSP-attach behavior
(`plugin/40-lsp.lua`), plus the per-server settings under `after/lsp/`.
## Requirements
### Requirement: Enabled LSP servers
The system SHALL enable the `lua_ls` and `neocmake` LSP servers via `vim.lsp.enable({...})`, each
configured by its own `after/lsp/<name>.lua` file (a `vim.lsp.Config` table) auto-loaded by
Neovim's native LSP client.

#### Scenario: Opening a Lua file
- **WHEN** the user opens a `.lua` file inside a directory containing one of `lua_ls`'s root
  markers (e.g. `.luarc.json`, `.git`)
- **THEN** `lua_ls` attaches, using LuaJIT runtime settings, the Neovim runtime + `pack` opt
  directories as library paths, code lens enabled, and inlay hints enabled (semicolons excluded)

#### Scenario: Opening a CMakeLists.txt file
- **WHEN** the user opens a `CMakeLists.txt` (or `.cmake`) file inside a directory containing one
  of `neocmake`'s root markers (e.g. `CMakeLists.txt`, `.git`)
- **THEN** `neocmake` attaches via `neocmakelsp stdio`, with formatting, linting, and
  package-in-cmake scanning enabled, and semantic tokens disabled

#### Scenario: Adding a new LSP server
- **WHEN** a new server name is added to the `vim.lsp.enable({...})` list in `plugin/40-lsp.lua`
  and, if non-default settings are needed, a matching `after/lsp/<name>.lua` file is added
- **THEN** Neovim's native LSP client attaches that server automatically for its declared
  filetypes/root markers, with no other wiring required

### Requirement: Diagnostic display
The system SHALL display diagnostics sorted by severity, in a rounded floating window
(source shown only when there are multiple sources), with only ERROR-severity diagnostics
underlined, and virtual text enabled by default (virtual lines disabled by default).

#### Scenario: A buffer has diagnostics from a single source
- **WHEN** a buffer has one or more diagnostics from exactly one LSP source
- **THEN** virtual text is shown without a source annotation, and only ERROR diagnostics are
  underlined

### Requirement: Diagnostic display-mode toggle
The system SHALL toggle diagnostic rendering between virtual text and virtual lines with
`<Leader>tv` in normal mode; exactly one of the two is active at a time.

#### Scenario: Switching to virtual lines
- **WHEN** virtual text is currently the active diagnostic display mode and the user presses
  `<Leader>tv`
- **THEN** virtual text is disabled and virtual lines is enabled

#### Scenario: Switching back to virtual text
- **WHEN** virtual lines is currently the active diagnostic display mode and the user presses
  `<Leader>tv`
- **THEN** virtual lines is disabled and virtual text is enabled

### Requirement: Diagnostics on/off toggle
The system SHALL toggle all diagnostics on/off with `<Leader>td` in normal mode.

#### Scenario: Disabling diagnostics
- **WHEN** diagnostics are currently enabled and the user presses `<Leader>td`
- **THEN** diagnostics are disabled and no longer shown

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

### Requirement: LSP-detach cleanup
The system SHALL, on `LspDetach`, remove the buffer's `LspHighlight_<bufnr>` and
`LspFormat_<bufnr>` augroups (if present) and clear any active reference highlights.

#### Scenario: An LSP client detaches from a buffer
- **WHEN** an LSP client detaches from a buffer that had document-highlight augroups registered
- **THEN** those augroups are removed and reference highlights are cleared, without erroring if
  they were never created

### Requirement: LSP picker keymaps under the Language group

The system SHALL provide a normal-mode keymap for each of `mini.extra`'s `lsp` picker scopes,
under the existing `<Leader>l` "+Language" group, living alongside (not replacing) Neovim's
built-in default LSP keymaps (`grn`/`gra`/`grr`/`gri`/`gO`):
- `<Leader>ld` opens `lsp` with `scope = "declaration"`
- `<Leader>lD` opens `lsp` with `scope = "definition"`
- `<Leader>lo` opens `lsp` with `scope = "document_symbol"`
- `<Leader>li` opens `lsp` with `scope = "implementation"`
- `<Leader>lr` opens `lsp` with `scope = "references"`
- `<Leader>lt` opens `lsp` with `scope = "type_definition"`
- `<Leader>lw` opens `lsp` with `scope = "workspace_symbol"`
- `<Leader>lW` opens `lsp` with `scope = "workspace_symbol_live"`

#### Scenario: Finding the declaration of the symbol under the cursor

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>ld`
- **THEN** if the server returns multiple locations, a `mini.pick` picker opens listing them;
  if it returns exactly one, the cursor jumps there directly

#### Scenario: Finding the definition of the symbol under the cursor

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>lD`
- **THEN** if the server returns multiple locations, a `mini.pick` picker opens listing them;
  if it returns exactly one, the cursor jumps there directly

#### Scenario: Browsing document symbols

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>lo`
- **THEN** a `mini.pick` picker opens listing the current buffer's symbols

#### Scenario: Finding implementations of the symbol under the cursor

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>li`
- **THEN** if the server returns multiple locations, a `mini.pick` picker opens listing them;
  if it returns exactly one, the cursor jumps there directly

#### Scenario: Finding references to the symbol under the cursor

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>lr`
- **THEN** a `mini.pick` picker opens listing reference locations (this scope always calls
  `vim.lsp.buf.references`, which itself decides whether to show a list or jump directly)

#### Scenario: Finding the type definition of the symbol under the cursor

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>lt`
- **THEN** if the server returns multiple locations, a `mini.pick` picker opens listing them;
  if it returns exactly one, the cursor jumps there directly

#### Scenario: Searching workspace symbols by a fixed query

- **WHEN** an LSP client supporting the relevant method is attached and the user presses
  `<Leader>lw`
- **THEN** a `mini.pick` picker opens listing workspace symbols matching an empty (all-symbols)
  query

#### Scenario: Searching workspace symbols interactively

- **WHEN** an LSP client supporting the relevant method is attached, the user presses
  `<Leader>lW`, and types a query
- **THEN** the picker's matches update live as the LSP server is re-queried with each keystroke,
  the same live-query pattern already used by `<Leader>fg`'s `grep_live`

