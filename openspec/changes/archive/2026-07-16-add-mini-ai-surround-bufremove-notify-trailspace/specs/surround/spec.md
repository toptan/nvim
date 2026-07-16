## ADDED Requirements

### Requirement: mini.surround default surround editing

The system SHALL provide surround add/delete/replace/find/highlight operators via `mini.surround`
(part of `mini.nvim`, configured in `plugin/60-mini.lua`) with its default mappings: `sa` (add),
`sd` (delete), `sr` (replace), `sf`/`sF` (find right/left), `sh` (highlight), and `l`/`n` next/prev
search suffixes — no custom options.

#### Scenario: Adding a surrounding

- **WHEN** the user selects text in visual mode (or types `sa` followed by a textobject/motion in
  normal mode) and then types a surrounding identifier (e.g. `)`, `"`, `t` for tag)
- **THEN** the selected/targeted region is wrapped in that surrounding

#### Scenario: Deleting a surrounding

- **WHEN** the cursor is inside or on a surrounding and the user types `sd` followed by that
  surrounding's identifier
- **THEN** the surrounding is removed, leaving its contents in place

#### Scenario: Replacing a surrounding

- **WHEN** the cursor is inside or on a surrounding and the user types `sr` followed by the
  existing surrounding's identifier and then the new one
- **THEN** the existing surrounding is replaced by the new one

#### Scenario: Bare `s` still available for substitute after the default timeout

- **WHEN** the user presses `s` in normal mode and does not follow it with a recognized
  `mini.surround` suffix within `timeoutlen`
- **THEN** Neovim's built-in substitute-character command runs as before
