## ADDED Requirements

### Requirement: Delete buffer preserving window layout

The system SHALL delete the current buffer with `<Leader>bd` in normal mode, via
`mini.bufremove` (part of `mini.nvim`, configured in `plugin/60-mini.lua`), preserving the current
window layout (unlike plain `:bdelete`, which can close the window).

#### Scenario: Deleting a buffer with no unsaved changes

- **WHEN** the current buffer has no unsaved changes and the user presses `<Leader>bd`
- **THEN** the buffer is removed from the buffer list and the window shows another buffer, with
  window layout unchanged

### Requirement: Force-delete buffer preserving window layout

The system SHALL force-delete the current buffer, discarding unsaved changes, with `<Leader>bD`
in normal mode, via `mini.bufremove`, preserving the current window layout.

#### Scenario: Force-deleting a buffer with unsaved changes

- **WHEN** the current buffer has unsaved changes and the user presses `<Leader>bD`
- **THEN** the buffer is removed from the buffer list without a save/discard prompt, and window
  layout is unchanged
