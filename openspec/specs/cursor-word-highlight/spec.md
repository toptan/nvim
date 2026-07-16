# cursor-word-highlight Specification

## Purpose
TBD - created by archiving change add-mini-input-files-cursorword. Update Purpose after archive.

## Requirements

### Requirement: Highlight other occurrences of the word under the cursor

The system SHALL highlight other occurrences of the word currently under the cursor via
`mini.cursorword` (part of `mini.nvim`, configured in `plugin/60-mini.lua`) with its default
configuration (100ms delay before highlighting appears) — no custom options.

#### Scenario: Cursor rests on a word with other occurrences in the window

- **WHEN** the cursor stops on a word and that word appears elsewhere in the visible window, and
  the default delay has elapsed
- **THEN** every other occurrence of that word in the window is highlighted, and the occurrence
  under the cursor itself is highlighted distinctly (current vs. other occurrences)

#### Scenario: Cursor moves off the word

- **WHEN** the cursor moves to a position no longer on the previously highlighted word
- **THEN** the highlighting is removed
