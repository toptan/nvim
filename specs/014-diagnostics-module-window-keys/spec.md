# Feature Specification: One Diagnostics Module, Aligned List and Window Keys

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-24

**Status**: Implemented

**Input**: User description: "Move the code from @lua/config/diagnostic_list.lua into
@lua/config/diagnostics.lua, also make the diagnostic types in loclist aligned. After code is
moved to diagnostics.lua, the diagnostic_list.lua should be deleted. Remap `<C-w>h/j/k/l` to
`<C-h/j/k/l>` for easier navigation inside neovim."

## Overview

Three small changes to the daily-driver config:

1. **One home for diagnostics.** Everything about diagnostics — how they are displayed, the
   three toggles, and the buffer/workspace diagnostics list (feature 013) — lives in a single
   module. The separate diagnostics-list module is removed. Behaviour is unchanged.
2. **Aligned diagnostics list.** In the list opened by `<Leader>ld` / `<Leader>lD`, the
   severity labels ("error", "warning", "info", "hint") line up in one column and the
   messages start in one column, so the list reads as a table instead of a ragged column.
3. **Faster window moves.** `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` move the cursor to the window
   to the left, below, above and to the right, doing what `<C-w>h/j/k/l` do with one key
   press instead of two.

## Clarifications

### Session 2026-11-24

- Q: In the diagnostics list, which parts should line up from row to row? → A: Both: the
  file/line/column part is padded so severity labels share a column, and labels are padded
  to the width of "warning" so messages share a column (severity stays after the location).
- Q: In which editor modes should `<C-h/j/k/l>` move between windows? → A: Normal mode
  only.
- Q: Should `<C-l>`'s clear-and-redraw be kept somewhere? → A: No; `<C-l>` only moves to
  the right window and `:redraw!` stays available.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read the diagnostics list as a table (Priority: P1)

As the editor's sole user, when I open the diagnostics list I want the severity of every
entry in the same column and every message starting in the same column, so that I can scan
severities and messages without my eye jumping left and right.

**Why this priority**: The only user-visible change to existing behaviour in this feature;
it improves a list used daily.

**Independent Test**: Open a Lua file with one error on line 3 and one warning on line 120;
press `<Leader>ld`. In the list, the "error" and "warning" labels start in the same screen
column, and both messages start in the same screen column.

**Acceptance Scenarios**:

1. **Given** a buffer with diagnostics of different severities, **When** I press
   `<Leader>ld`, **Then** every entry's severity label starts in the same column and every
   message starts in the same column.
2. **Given** diagnostics on lines and columns with different numbers of digits (e.g. line 9
   and line 1200, column 1 and column 45), **When** the list opens, **Then** labels and
   messages are still aligned.
3. **Given** diagnostics in files with names of different lengths, **When** I press
   `<Leader>lD`, **Then** labels and messages are aligned across all entries in the list.
4. **Given** the aligned list, **When** I look at the colours, **Then** the severity label
   and message of each entry still carry that severity's colour, and the padding added for
   alignment is not coloured.
5. **Given** the aligned list, **When** I press `<CR>` on an entry, **Then** I land on that
   entry's file, line and column exactly as before.

---

### User Story 2 - Move between windows with one key (Priority: P1)

As the user, I want `<C-h>`, `<C-j>`, `<C-k>` and `<C-l>` to move to the neighbouring window
left, below, above and right, so that I can move between splits (including into and out of
the diagnostics list) with a single key press.

**Why this priority**: Explicitly requested; used constantly with splits and the location
list.

**Independent Test**: Open a vertical split and a horizontal split; from each window press
the four keys and confirm the cursor moves to the expected neighbour. Open the diagnostics
list with `<Leader>ld`, jump to an entry with `<CR>`, then press `<C-j>` to return to the
list.

**Acceptance Scenarios**:

1. **Given** two side-by-side windows with the cursor in the left one, **When** I press
   `<C-l>` in Normal mode, **Then** the cursor moves to the right window; **When** I then
   press `<C-h>`, **Then** it moves back to the left window.
2. **Given** two stacked windows with the cursor in the top one, **When** I press `<C-j>`,
   **Then** the cursor moves to the bottom window; **When** I then press `<C-k>`, **Then**
   it moves back to the top window.
3. **Given** there is no window in the pressed direction, **When** I press the key, **Then**
   the cursor stays in the current window and no error is shown.
4. **Given** the cursor is in a location list or quickfix window, **When** I press one of
   the four keys, **Then** it moves to the neighbouring window the same way.
5. **Given** Normal mode, **When** I press `<C-w>` and pause, **Then** `<C-w>h/j/k/l` still
   work and are still listed in the key-clue window.

---

### User Story 3 - Diagnostics configured in one place (Priority: P2)

As the maintainer of the config, I want all diagnostics behaviour in one module and the
separate list module gone, so that I find and change diagnostics settings in one file.

**Why this priority**: Requested, but invisible while using the editor; its value is in
maintenance.

**Independent Test**: The separate diagnostics-list module no longer exists and nothing
refers to it; starting the editor headless produces no errors; `<Leader>ld`, `<Leader>lD`,
`<Leader>td`, `<Leader>tt`, `<Leader>tl`, and `<Esc>` in a location list all behave exactly
as before (apart from the alignment of User Story 1).

**Acceptance Scenarios**:

1. **Given** the change is applied, **When** I list the config's modules, **Then** there is
   no separate diagnostics-list module and the entry point no longer loads one.
2. **Given** the change is applied, **When** I use every diagnostics key from features 004
   and 013, **Then** each behaves as specified there.
3. **Given** the editor has just started on an empty buffer, **When** no diagnostics key has
   been pressed and no diagnostics have arrived, **Then** the diagnostic subsystem has not
   been loaded (as before).

### Edge Cases

- A single entry in the list: no padding after the location; only the label is padded to
  the width of "warning".
- Very long file names in the workspace list: alignment follows the longest name in the
  list, even if that pushes labels far right; long messages are not cut.
- File names or messages with multi-byte or wide characters: alignment is by screen width,
  not by byte count.
- A diagnostic message spanning several lines: still shown on one line (as before) and
  aligned like the rest.
- The diagnostics list is re-opened after the colour scheme changes: colours still cover
  exactly the label and the message, never the padding.
- `<C-l>` normally clears and redraws the screen; after this change that is no longer
  available on `<C-l>` (`:redraw!` still works). `<C-h>`, `<C-j>`, `<C-k>` lose their
  default Normal-mode meanings (move left / move down / nothing), which duplicate `h`/`j`.
- `<C-h/j/k/l>` in Insert, Visual, Command-line or Terminal mode keep their current
  behaviour; only Normal mode changes.
- The location list's `<Esc>` and `<CR>` behaviour (feature 013) is unaffected.
- The key-clue window shows descriptions for the four new keys if they are ever listed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: All diagnostics behaviour — display settings, the three toggles
  (`<Leader>td`, `<Leader>tt`, `<Leader>tl`), the buffer and workspace diagnostics list
  (`<Leader>ld`, `<Leader>lD`), its severity colouring, and `<Esc>` in location list windows
  — MUST live in the single diagnostics module.
- **FR-002**: The separate diagnostics-list module MUST be deleted, and no code file
  (entry point, other modules) and no README MUST refer to it any more. Spec documents of
  earlier features are a historical record and stay unchanged.
- **FR-003**: Apart from FR-004 and FR-005, the behaviour of every diagnostics key and of
  the list MUST be unchanged from features 004 and 013 (including ordering, colouring,
  focus, `<Esc>`/`<CR>`, the empty-list notice, and the 2-second workspace wait).
- **FR-004**: In lists filled by `<Leader>ld` and `<Leader>lD`, every entry's severity label
  MUST start in the same screen column, and every entry's message MUST start in the same
  screen column, regardless of file name length, line/column digit count, or severity. The
  entry order of parts stays file, line, column, severity, message: the location part is
  padded to the widest location in the list, and each label to the width of "warning".
- **FR-005**: The alignment MUST be computed per list from its own entries (padding only as
  wide as the widest entry in that list needs); messages MUST NOT be truncated.
- **FR-006**: The severity colour MUST cover exactly the label text and the message text;
  padding added for alignment MUST NOT be coloured.
- **FR-007**: In Normal mode, `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` MUST move the cursor to the
  window left, below, above and right of the current one, exactly as `<C-w>h`, `<C-w>j`,
  `<C-w>k`, `<C-w>l` do (including when no such window exists: no move, no error). Only
  Normal mode changes: Insert, Visual, Command-line and Terminal mode MUST keep their
  current meanings for these keys.
- **FR-008**: The four keys MUST work in every window, including location list, quickfix
  and help windows.
- **FR-009**: `<C-w>h/j/k/l` MUST keep working unchanged.
- **FR-010**: The four new keys MUST have descriptions.
- **FR-011**: No plugin MAY be added (Constitution Principle I).
- **FR-012**: The diagnostic subsystem MUST still not be loaded at startup; startup time on
  an empty buffer MUST stay under 100 ms and a headless start/quit MUST produce no errors.
- **FR-013**: The README MUST document the four window keys and show the aligned list
  format; references to the removed module, if any, MUST be updated.

### Key Entities

- **Diagnostics list entry**: one line in the location list: file, line, column, severity
  label, message; the label and message are coloured by severity.
- **Window key**: a single-key Normal-mode shortcut for a two-key window move.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a diagnostics list with entries of all four severities, line numbers from
  1 to 4 digits and at least two file names of different lengths, 100% of severity labels
  start in one column and 100% of messages start in one column.
- **SC-002**: Moving to a neighbouring window takes one key press instead of two, in all
  four directions.
- **SC-003**: Diagnostics behaviour is defined in exactly one module; zero references to
  the removed module remain in the code or the README.
- **SC-004**: Every acceptance scenario of features 004 and 013 still passes.
- **SC-005**: A headless start/quit exits with no errors, and startup time on an empty
  buffer stays below 100 ms.

## Assumptions

- "Diagnostic types aligned" means the severity column and the message column line up
  across entries; the file/line/column part is padded to a common width so that the
  severity labels share a column, and labels are padded to the width of the longest label
  ("warning") so that messages share a column.
- The window keys apply to Normal mode only; other modes keep their current meanings, and
  terminal-mode window navigation is out of scope.
- `<C-l>`'s default "clear and redraw" is dropped (not moved to another key); `:redraw!`
  remains available.
- The existing `<Esc>`-in-location-list behaviour moves into the diagnostics module along
  with the list, since it exists for the list.
- The README's existing description of the diagnostics list (feature 013) is updated rather
  than rewritten.
