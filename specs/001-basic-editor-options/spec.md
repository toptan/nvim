# Feature Specification: Basic Editor Options

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-18

**Status**: Ready for implementation

**Input**: User description: "Add basic options for neovim. No nerd font support, use spaces
instead of tabs, tabsize is 4, line numbers should be on as well as relative numbers. Scroll off
should be 8. Disable all providers (python, node, etc.). Global and local leader key should be
space. Set more visually appropriate listchars instead of the defaults. Current line should be
highlighted and color column should be set to 80th column. Set the color scheme to built-in
`catppuccin` color scheme. The background must be transparent. Sign column should be visible
always."

## Clarifications

### Session 2026-11-18

- Q: Which `catppuccin` colours should be used on top of the transparent background? → A:
  Follow the terminal — the editor's light/dark detection decides, and `catppuccin` matches it.
- Q: Which symbols should represent invisible characters? → A: tab `» `, trailing space `·`,
  non-breaking space `␣`, text past the right/left edge `›` / `‹`; no end-of-line marker.
- Q: Should the vertical marker sit on column 80 or on column 81? → A: Column 81 — the first
  character past the 80-character limit.
- Q: Should `.editorconfig` and language conventions override the 4-space default? → A: Yes —
  4 spaces is the default; `.editorconfig` and built-in language conventions win where they
  apply.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Predictable editing behaviour (Priority: P1)

As the editor's sole user, when I open any file I want indentation, navigation aids and the
leader key to behave the same way every time, so that my muscle memory works without
per-session tweaks.

**Why this priority**: These settings affect every keystroke and every file edited; without them
the editor is not usable as a daily driver.

**Independent Test**: Start the editor on a new file, type indented text, move around, and press
the leader key; all behaviour matches the requirements below without any other feature present.

**Acceptance Scenarios**:

1. **Given** a new empty buffer with no project-specific settings, **When** I press Tab in
   insert mode, **Then** 4 space characters are inserted and no tab character is written.
2. **Given** a buffer, **When** I indent or dedent a line with the indent commands, **Then**
   the line shifts by exactly 4 columns using spaces.
3. **Given** a buffer with more than 20 lines, **When** I view it, **Then** the current line
   shows its absolute line number and every other line shows its distance from the cursor.
4. **Given** a buffer taller than the window, **When** I move the cursor towards the top or
   bottom edge, **Then** at least 8 lines of context remain visible above/below the cursor
   (except at the start or end of the file).
5. **Given** the editor has started, **When** I inspect the leader and local leader keys,
   **Then** both are Space.

---

### User Story 2 - Clean, readable appearance (Priority: P2)

As the user, I want a consistent visual theme that blends with my terminal and highlights what
matters (current line, line-length limit, whitespace, signs) so that code is easy to read and
the layout never jumps.

**Why this priority**: Strongly affects comfort and readability but the editor is functional
without it.

**Independent Test**: Start the editor in a terminal with a background image or distinctive
background colour and open a file containing tabs, trailing spaces and long lines; check each
visual requirement.

**Acceptance Scenarios**:

1. **Given** the editor has started, **When** I check the active colour scheme, **Then** it is
   the built-in `catppuccin` scheme.
2. **Given** a terminal with a custom background, **When** the editor is open, **Then** the
   terminal background shows through the main editing area, the line-number column and the
   sign column.
3. **Given** a buffer, **When** the cursor is on a line, **Then** that line is highlighted, and
   a vertical marker is shown at column 81 (just past the 80-character limit).
4. **Given** a buffer with no diagnostics or signs, **When** diagnostics or signs appear later,
   **Then** the text does not shift horizontally because the sign column was already visible.
5. **Given** a file containing tab characters, trailing spaces and non-breaking spaces, **When**
   I view it, **Then** each is shown with a distinct, unobtrusive symbol, and all symbols
   render correctly in a standard (non-Nerd) monospace font.

---

### User Story 3 - Lean, dependency-free startup (Priority: P3)

As the user, I want the editor to skip external language providers and avoid icon-font glyphs
so that it starts fast, reports no provider warnings, and renders correctly in any terminal
font.

**Why this priority**: Improves startup and portability; no visible editing behaviour depends
on it.

**Independent Test**: Run the editor's health check on a machine without Python/Node/Ruby/Perl
host packages and confirm providers are reported as disabled rather than missing.

**Acceptance Scenarios**:

1. **Given** the editor has started, **When** I run the health check for providers, **Then**
   the Python 3, Node.js, Ruby and Perl providers are all reported as disabled.
2. **Given** a terminal using a font without Nerd Font glyphs, **When** I use the editor,
   **Then** no missing-glyph boxes or placeholder characters appear anywhere in the UI defined
   by this feature.

---

### Edge Cases

- A project `.editorconfig` or built-in language conventions (e.g. Makefiles requiring tabs,
  this repository's 2-space Lua) override the 4-space default for those buffers (FR-002a).
- If the colour scheme is reloaded or switched at runtime, the transparent background MUST be
  re-applied rather than lost.
- If the terminal's light/dark mode is detected late or changes during a session (switching
  between the light and dark palette), the transparent background MUST still be applied.
- If the terminal does not report its background (e.g. some tmux/SSH setups), the editor's
  own default (dark) applies; this is acceptable.
- If the `catppuccin` scheme is unavailable (older Neovim), startup MUST NOT error; the editor
  falls back to the default scheme.
- In very short windows (fewer than 17 lines), the 8-line scroll offset is capped by the window
  height and the cursor stays centred; this is acceptable.
- Leader key must be set before any key mapping is defined so that later mappings use Space.

## Requirements *(mandatory)*

### Functional Requirements

**Indentation**

- **FR-001**: By default the editor MUST insert spaces instead of tab characters when
  indenting.
- **FR-002**: By default the width of a tab character, an indent level, and a Tab key press in
  insert mode MUST all be 4 columns.
- **FR-002a**: A project's `.editorconfig` and the editor's built-in language conventions
  (e.g. tabs in Makefiles and Go) MUST take precedence over FR-001/FR-002 for the buffers they
  apply to; the configuration MUST NOT disable or override them.

**Navigation & numbering**

- **FR-003**: Absolute line numbers MUST be shown, combined with relative numbers (current line
  absolute, others relative).
- **FR-004**: A minimum of 8 lines of context MUST be kept above and below the cursor when
  scrolling vertically.
- **FR-005**: Both the global leader and the local leader key MUST be Space, and MUST be set
  before any key mapping is defined.

**Appearance**

- **FR-006**: The colour scheme MUST be the built-in `catppuccin` scheme. The light/dark
  background MUST NOT be forced by the configuration; the editor's automatic terminal
  detection decides it, and `catppuccin` uses its matching light or dark palette.
- **FR-007**: The background of the main editing area, line-number column, sign column and
  end-of-buffer area MUST be transparent (terminal background visible), and transparency MUST
  survive a colour scheme reload.
- **FR-008**: The line containing the cursor MUST be highlighted.
- **FR-009**: A colour column MUST be displayed at column 81, i.e. immediately after the
  80-character line limit, so a line of exactly 80 characters does not touch it.
- **FR-010**: The sign column MUST always be visible, even when no signs are present.
- **FR-011**: Invisible characters MUST be displayed with these symbols: tab `» `, trailing
  space `·`, non-breaking space `␣`, text extending past the right/left window edge (when
  wrapping is off) `›` / `‹`. Ends of lines and leading spaces MUST NOT be marked.
- **FR-012**: All symbols introduced by this feature MUST be standard Unicode characters that
  render in a common monospace font; Nerd Font glyphs MUST NOT be used, and the configuration
  MUST record that no Nerd Font is available so later features can respect it.

**Providers**

- **FR-013**: The Python 3, Node.js, Ruby and Perl providers MUST be disabled so the editor does
  not search for or load them.

**Robustness** (per Constitution Principle IV)

- **FR-014**: Starting the editor headlessly and quitting MUST produce no errors or warnings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the settings listed in FR-001–FR-013 are observable in a fresh session
  without any manual command.
- **SC-002**: Starting and immediately quitting the editor produces 0 error or warning messages.
- **SC-003**: The provider health check reports 0 provider warnings or errors (all four
  disabled).
- **SC-004**: Startup time on an empty buffer remains under 100 ms (Constitution Principle III).
- **SC-005**: When viewed in a font without Nerd Font glyphs, 0 missing-glyph boxes appear.

## Assumptions

- "Built-in `catppuccin`" refers to the colour scheme bundled with Neovim 0.12+ (verified
  present in Neovim 0.12.6); its flavour follows the editor's detected light/dark background.
- "All providers" means the four providers Neovim supports: Python 3, Node.js, Ruby and Perl.
- "Tabsize is 4" applies to tab display width, indent width and the soft Tab key width alike.
- Showing invisible characters is enabled by default for all buffers, since the request is to
  make them visually appropriate rather than hidden.
- No keymaps, plugins or LSP configuration are part of this feature.
