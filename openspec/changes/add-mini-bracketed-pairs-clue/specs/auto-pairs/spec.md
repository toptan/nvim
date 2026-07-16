## ADDED Requirements

### Requirement: mini.pairs default auto-pairing

The system SHALL auto-insert matching bracket/quote pairs in insert mode using `mini.pairs`
(part of `mini.nvim`, configured in `plugin/60-mini.lua`) with its default configuration — no
custom mappings or per-filetype overrides.

#### Scenario: Typing an opening bracket or quote

- **WHEN** the user types `(`, `[`, `{`, `"`, `'`, or `` ` `` in insert mode (outside an excluded
  neighboring-character context)
- **THEN** the matching closing character is inserted immediately after, with the cursor
  positioned between the pair

#### Scenario: Typing a closing character right after its auto-inserted counterpart

- **WHEN** the cursor is immediately before an auto-inserted closing character and the user types
  that same closing character
- **THEN** the cursor moves past the existing closing character instead of inserting a duplicate

#### Scenario: Deleting an empty pair

- **WHEN** the cursor is between an auto-inserted opening and closing character with nothing
  between them, and the user presses `<BS>`
- **THEN** both characters are deleted together

#### Scenario: Splitting an empty pair with Enter

- **WHEN** the cursor is between an auto-inserted opening and closing bracket pair with nothing
  between them, no completion popup is visible, and the user presses `<Enter>`
- **THEN** the pair is split across two lines, with the cursor left indented on the line between
  them
