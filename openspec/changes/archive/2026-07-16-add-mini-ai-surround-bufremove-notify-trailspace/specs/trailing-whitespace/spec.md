## ADDED Requirements

### Requirement: Trailing whitespace highlighting

The system SHALL highlight trailing whitespace in normal buffers (`buftype == ""`) via
`mini.trailspace` (part of `mini.nvim`, configured in `plugin/60-mini.lua`) with its default
configuration (`only_in_normal_buffers = true`) — no custom options.

#### Scenario: A normal buffer contains trailing whitespace

- **WHEN** a line in a normal buffer ends with one or more whitespace characters
- **THEN** the trailing whitespace is visually highlighted

#### Scenario: A non-normal buffer contains trailing whitespace

- **WHEN** a line in a non-normal buffer (e.g. a terminal or floating scratch buffer with
  non-empty `buftype`) ends with whitespace
- **THEN** the trailing whitespace is NOT highlighted

### Requirement: Manual trailing-whitespace trim

The system SHALL trim trailing whitespace from the current buffer with `<Leader>cw` in normal
mode, via `mini.trailspace`'s `trim()`. Trimming SHALL only happen on explicit invocation of this
keymap — never automatically on save or any other event.

#### Scenario: Trimming a buffer with trailing whitespace

- **WHEN** the current buffer contains one or more lines with trailing whitespace and the user
  presses `<Leader>cw`
- **THEN** the trailing whitespace is removed from every line in the buffer

#### Scenario: Saving a file does not trim automatically

- **WHEN** the current buffer contains trailing whitespace and the user saves the file without
  pressing `<Leader>cw`
- **THEN** the trailing whitespace remains in the saved file
