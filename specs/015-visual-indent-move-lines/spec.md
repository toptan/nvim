# Feature Specification: Sticky Visual Indent and Line Moving

**Feature Branch**: `master` (no feature branch; spec-kit tooling refers to the feature as
`015-visual-indent-move-lines` via `.specify/feature.json`)

**Created**: 2026-11-24

**Status**: Implemented

**Input**: User description: "Add keymaps for increasing/decreasing indent but visual mode
should not be exited. Add `<M-j>` and `<M-k>` mappings that move line/selection one line
below/up, if the selection is moved the visual mode should not be exited."

## Overview

Two small editing conveniences for the daily-driver config:

1. **Sticky indent.** Shifting a visual selection right or left keeps the selection active,
   so the user can press the shift key repeatedly to indent or dedent by several levels
   without reselecting the text each time.
2. **Move lines.** `<M-j>` and `<M-k>` (Alt+j / Alt+k) move the current line — or every
   line touched by the visual selection — one line down or up. When a selection is moved it
   stays selected, so the user can keep pressing the key to slide the block further.

## Clarifications

### Session 2026-11-24

- Q: When the terminal doesn't send Alt as Meta, which characters should also move lines
  down and up? → A: Also map `∆` (move down) and `˚` (move up) — the characters macOS US
  layout produces for Option+j / Option+k — in normal and visual mode only.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Indent a selection repeatedly (Priority: P1)

The user selects a block of lines in visual mode and presses the "indent" key (`>`) to shift
it right by one level. The selection stays active, so pressing `>` again shifts it another
level. The same works with `<` for shifting left. When done, the user leaves visual mode as
usual (e.g. `<Esc>`).

**Why this priority**: Re-indenting a block by more than one level is a frequent edit; today
the selection is lost after every shift and must be restored (`gv`) each time.

**Independent Test**: Select three lines with `V`, press `>` twice, then `<` once. The lines
end up indented by exactly one level and the editor is still in visual mode with the same
three lines selected.

**Acceptance Scenarios**:

1. **Given** three lines selected in linewise visual mode, **When** the user presses `>`,
   **Then** each selected line gains one indent level and the same three lines remain
   selected in visual mode.
2. **Given** an indented selection in visual mode, **When** the user presses `<`, **Then**
   each selected line loses one indent level and the selection remains active.
3. **Given** a selection in visual mode, **When** the user presses `>` with a count (e.g.
   `3>`), **Then** the lines are shifted by that many levels and the selection remains
   active.
4. **Given** a characterwise (`v`) or blockwise (`<C-v>`) selection, **When** the user
   presses `>` or `<`, **Then** the shift happens as it does in stock Neovim for that kind of
   selection and the editor remains in the same kind of visual mode with the same lines
   selected. The selection keeps its column positions, so its ends may no longer sit on the
   same characters after the text shifts.

---

### User Story 2 - Move a selection up and down (Priority: P1)

The user selects a block of lines and presses `<M-j>` to move it one line down, or `<M-k>` to
move it one line up. The text stays selected after each move, so repeated presses slide the
block several lines.

**Why this priority**: Reordering a block of code (moving a function argument, swapping
statements) is common and today needs cut, navigate, paste, and reselect.

**Independent Test**: In a five-line buffer `a b c d e` (one letter per line), select lines
`b`–`c` and press `<M-j>` twice. The buffer becomes `a d e b c` and lines `b`–`c` are still
selected in visual mode.

**Acceptance Scenarios**:

1. **Given** lines 2–3 selected in visual mode, **When** the user presses `<M-j>`, **Then**
   those lines swap places with line 4, and the moved lines (now 3–4) remain selected in
   visual mode.
2. **Given** lines 3–4 selected in visual mode, **When** the user presses `<M-k>`, **Then**
   those lines swap places with line 2, and the moved lines (now 2–3) remain selected.
3. **Given** a characterwise selection spanning part of two lines, **When** the user presses
   `<M-j>`, **Then** both whole lines move down by one and the editor stays in visual mode
   with the moved text selected.
4. **Given** a selection was moved several times, **When** the user presses `u` (undo) once
   after leaving visual mode, **Then** at most the last single move is undone (each move is
   one undo step).

---

### User Story 3 - Move the current line (Priority: P2)

In normal mode, the user presses `<M-j>` or `<M-k>` to move the line under the cursor one
line down or up. The cursor stays on the moved line.

**Why this priority**: Useful and expected alongside the visual-mode version, but a single
line can already be moved with `ddp` / `ddkP`, so it adds less than Stories 1 and 2.

**Independent Test**: In buffer `a b c`, place the cursor on `a` and press `<M-j>`; the
buffer becomes `b a c` with the cursor on `a`.

**Acceptance Scenarios**:

1. **Given** the cursor on line 2 in normal mode, **When** the user presses `<M-j>`, **Then**
   line 2 swaps with line 3 and the cursor is on the moved line (now line 3).
2. **Given** the cursor on line 2 in normal mode, **When** the user presses `<M-k>`, **Then**
   line 2 swaps with line 1 and the cursor is on the moved line (now line 1).
3. **Given** the cursor on a line, **When** the user presses `3<M-j>`, **Then** the line
   moves three lines down (or as far as the buffer allows).

### Edge Cases

- **Top / bottom of buffer**: pressing `<M-k>` when the line or selection already starts at
  line 1, or `<M-j>` when it already ends at the last line, leaves the buffer unchanged,
  shows no error message, and (in visual mode) keeps the selection active.
- **Count larger than available room**: the line or selection moves as far as possible
  toward the buffer edge instead of failing.
- **Indentation of moved lines**: moved lines keep their exact original indentation; they
  are not re-indented to match their new surroundings.
- **Shifting lines with no indentation left**: `<` on an unindented line leaves it unchanged
  (stock behaviour) and the selection stays active.
- **Read-only / non-modifiable buffers**: the keys behave like any other edit there —
  Neovim's usual "cannot modify" message, no extra errors, buffer unchanged.
- **Closed folds**: moving a line next to a closed fold moves it one buffer line, which
  may place it inside the fold's range, exactly as `:move` does; no special handling is
  required, and no error is shown.
- **Terminal Alt handling**: if the terminal does not send Alt+j / Alt+k as Meta keys, the
  characters it types instead on macOS US layout (`∆` for Option+j, `˚` for Option+k) act as
  `<M-j>` / `<M-k>`. Terminals that send Alt as an Esc prefix already work without extra
  mappings. Other keyboard layouts are not covered.
- **Typing `∆` / `˚` as text**: because the fallback characters are mapped only in normal
  and visual mode, they can still be typed literally in insert mode.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: In visual mode (characterwise, linewise and blockwise), `>` and `<` MUST shift
  the selected lines right / left by `count` (default 1) indent levels and MUST leave the
  editor in the same visual mode with the same lines selected (selection columns are kept
  as they were). FR-002 was merged into this requirement.
- **FR-003**: In normal mode, `<M-j>` MUST move the current line down by `count` (default 1)
  lines, and `<M-k>` MUST move it up by `count` lines; the cursor MUST stay on the moved
  line.
- **FR-004**: In visual mode, `<M-j>` MUST move all lines touched by the selection down by
  `count` (default 1) lines, and `<M-k>` MUST move them up by `count` lines.
- **FR-005**: After a visual-mode move, the editor MUST remain in the same visual mode with
  the moved lines selected.
- **FR-006**: A move that would go past the first or last line of the buffer MUST be clamped
  to the buffer edge; if no movement is possible the buffer MUST be left unchanged and no
  error message shown.
- **FR-007**: Moved lines MUST keep their original indentation.
- **FR-008**: Each single press of a move or shift key MUST be undoable as one undo step.
- **FR-008a**: In normal and visual mode, `∆` MUST behave exactly like `<M-j>` and `˚` MUST
  behave exactly like `<M-k>` (including count, clamping and keeping the selection), so the
  feature works when the terminal sends macOS Option+j / Option+k as plain characters. These
  characters MUST NOT be mapped in insert mode.
- **FR-009**: Every new mapping MUST have a description so it is discoverable in the
  key-hint popup and `:map` listings.
- **FR-010**: Normal-mode `>>`, `<<`, `>` / `<` with motions, and all other existing
  mappings MUST keep their current behaviour.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Indenting a selected block by N levels takes N key presses (`>` repeated N
  times) with no reselection, instead of 2N-1 presses today (`>` then `gv>` per level).
- **SC-002**: Moving a selected block K lines takes K key presses (`<M-j>` / `<M-k>` repeated
  K times) and the block is still selected afterwards.
- **SC-003**: All acceptance scenarios above pass when exercised by hand in a fresh editor
  session.
- **SC-004**: Pressing the move keys at the top or bottom of a buffer produces zero error
  messages.
- **SC-005**: Editor startup completes with no new errors or warnings, and startup time
  shows no noticeable regression.

## Assumptions

- "Increase/decrease indent" means the standard visual-mode `>` and `<` keys; no additional
  keys (e.g. `<Tab>` / `<S-Tab>` in visual mode) are introduced.
- `<M-j>` / `<M-k>` are mapped in normal and visual mode only; insert mode is out of scope.
- The terminal either delivers Alt+letter as a Meta key (or Esc prefix) to Neovim, or —
  on macOS without "Option as Meta" — types `∆` / `˚` using the US keyboard layout, which
  are mapped as fallbacks (FR-008a).
- `<M-j>`, `<M-k>`, `∆` and `˚` are not currently mapped in this config, so no existing binding is
  displaced.
- Moved lines are not auto-reindented; users who want that can follow up with `=` while the
  selection is still active.
