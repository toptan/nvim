## ADDED Requirements

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
