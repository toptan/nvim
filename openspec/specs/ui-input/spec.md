# ui-input Specification

## Purpose
TBD - created by archiving change add-mini-input-files-cursorword. Update Purpose after archive.

## Requirements

### Requirement: mini.input as the vim.ui.input implementation

The system SHALL handle all `vim.ui.input()` calls (e.g. LSP rename prompts, `:h input()`-style
plugin prompts routed through `vim.ui.input`) via `mini.input` (part of `mini.nvim`, configured in
`plugin/60-mini.lua`), with its default configuration (`scope = 'editor'`) — no custom handlers.

#### Scenario: A plugin or LSP feature requests text input

- **WHEN** any code path calls `vim.ui.input(...)` (e.g. an LSP `textDocument/rename` prompt)
- **THEN** the prompt is rendered via `mini.input` instead of the default command-line `input()`
  prompt, and the provided callback receives the entered text (or `nil` on cancel)
