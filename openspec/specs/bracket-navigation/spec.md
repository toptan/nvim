# bracket-navigation Specification

## Purpose
TBD - created by archiving change add-mini-bracketed-pairs-clue. Update Purpose after archive.

## Requirements

### Requirement: mini.bracketed default bracket navigation

The system SHALL provide `[x`/`]x` navigation mappings (previous/next, with uppercase `[X`/`]X`
first/last variants) via `mini.bracketed` (part of `mini.nvim`, configured in
`plugin/60-mini.lua`) with its default configuration — no custom target list or per-mapping
overrides. Targets are available in normal, visual, and operator-pending mode as shipped by
`mini.bracketed`'s defaults (buffer, comment, conflict, diagnostic, file, indent, jump, location
list, oldfile, quickfix list, treesitter node, undo state, window, yank).

#### Scenario: Navigating buffers

- **WHEN** multiple buffers are open and the user presses `]b` (or `[b`) in normal mode
- **THEN** the next (or previous) buffer becomes active

#### Scenario: Navigating a target with no next/previous entry

- **WHEN** the user presses a `mini.bracketed` mapping (e.g. `]q` for the quickfix list) while
  that target has no applicable next/previous entry
- **THEN** no navigation occurs and no error is raised
