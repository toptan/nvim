## ADDED Requirements

### Requirement: mini.statusline default content

The system SHALL show a statusline via `mini.statusline` (part of `mini.nvim`, configured in
`plugin/60-mini.lua`) whose active-window content matches the module's own documented default
layout and order: mode indicator, git/diff info, diagnostics, LSP info, filename, fileinfo,
search count, and location — except for diagnostics coloring (see the next requirement). Inactive
windows SHALL use the module's default inactive content.

#### Scenario: Editing a file with git info and an attached LSP client

- **WHEN** a buffer has git status, a diff summary, and an attached LSP client
- **THEN** the statusline shows the mode indicator, git branch/diff summary, LSP client count,
  filename, file encoding/format info, search count, and cursor location, in that order

### Requirement: Diagnostics counts colored by severity

The system SHALL color each non-zero diagnostic severity count in the statusline with the same
highlight group used for that severity elsewhere in this config (sign column, virtual text):
`DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo`, `DiagnosticHint`. Each severity with a
non-zero count SHALL render as its own separately-colored segment; severities with zero count
SHALL be omitted entirely.

#### Scenario: Buffer has errors and warnings but no info/hints

- **WHEN** the current buffer has 2 error and 3 warning diagnostics, and no info or hint
  diagnostics
- **THEN** the statusline shows an error count segment colored with `DiagnosticError` and a
  warning count segment colored with `DiagnosticWarn`, with no info or hint segment shown

#### Scenario: Buffer has no diagnostics

- **WHEN** the current buffer has no diagnostics, or diagnostics are disabled for it
- **THEN** no diagnostics segment is shown at all
