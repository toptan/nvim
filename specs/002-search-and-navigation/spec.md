# Feature Specification: Search, Yank Feedback and Buffer Navigation

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "Yanked text should be highlighted, also search highlights should
be turned off by pressing `Escape` key in normal mode. On the left hand side where the row
numbers are there should be enough space to show 5 digits. It should be possible to circle
through buffers with `Tab` and circle backwards via `Shift + Tab`. Incremental search should be
turned off and smart when it comes to case sensitivity. Next to the current search occurrence
there should be label/text `[occurence/total occurences]`. Once search is closed the labels
should dissapear."

## Clarifications

### Session 2026-11-19

- Q: Where should the `[current/total]` label appear? → A: Right-aligned at the window's right
  edge on the line containing the current match.
- Q: How should the Tab / Ctrl+I conflict be handled? → A: Accept the loss — Tab cycles
  buffers and jump-forward is left without a key; Ctrl+O (jump back) is unaffected.
- Q: Should the label stay when the cursor moves off the match by ordinary motions? → A: Yes —
  it stays on that match until highlights are cleared, the buffer is edited, or another buffer
  is shown.
- Q: In what order should Tab cycle buffers? → A: Fixed order, by when each buffer was opened
  (the editor's buffer list order).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Search that tells me where I am (Priority: P1)

As the editor's sole user, when I search for text I want case handling to "do what I mean",
the match highlights to go away with a single key press, and a label next to the current match
telling me which occurrence I am on out of how many, so that I can navigate results without
counting or running extra commands.

**Why this priority**: Searching is one of the most frequent navigation actions; the position
label and quick clearing of highlights remove the most common friction.

**Independent Test**: Open a file with several occurrences of a word in mixed case, search for
it in lower case and then with a capital letter, step through matches, and press Escape; check
each requirement below.

**Acceptance Scenarios**:

1. **Given** a buffer containing `foo`, `Foo` and `FOO`, **When** I search for `foo`, **Then**
   all three are matched (case ignored).
2. **Given** the same buffer, **When** I search for `Foo`, **Then** only `Foo` is matched
   (case respected because the pattern contains an upper-case letter).
3. **Given** I am typing a search pattern, **When** I have not yet confirmed it, **Then** the
   cursor does not jump and no match is highlighted ahead of time.
4. **Given** a confirmed search with 7 matches and the cursor on the 3rd, **When** I look at
   the current match, **Then** a label `[3/7]` is shown right-aligned at the window's edge on
   that match's line.
5. **Given** a label is shown, **When** I jump to the next or previous match (including
   wrapping past the end/start of the file, and searching for the word under the cursor),
   **Then** the label moves to the new current match and its number updates; the previous
   label is removed, so only one exists at a time.
6. **Given** search matches are highlighted, **When** I press Escape in normal mode, **Then**
   all match highlights and the position label disappear, and they reappear when I jump to
   the next match again.
7. **Given** a label is shown on the current match, **When** I move the cursor elsewhere with
   ordinary motions (not a search jump), **Then** the label stays on that match unchanged.

---

### User Story 2 - Fast switching between open buffers (Priority: P2)

As the user, I want to cycle forwards through my open buffers with Tab and backwards with
Shift+Tab, wrapping around at either end, so that moving between a handful of open files takes
a single key press.

**Why this priority**: Frequent when working on several files, but the editor remains usable
with the built-in buffer commands.

**Independent Test**: Open three files, press Tab repeatedly in normal mode and observe the
order, then press Shift+Tab repeatedly.

**Acceptance Scenarios**:

1. **Given** buffers A, B and C are open and A is shown, **When** I press Tab in normal mode
   three times, **Then** the window shows B, then C, then A again.
2. **Given** the same buffers with A shown, **When** I press Shift+Tab, **Then** the window
   shows C (wrap backwards), then B.
3. **Given** only one buffer is open, **When** I press Tab or Shift+Tab, **Then** nothing
   changes and no error is shown.
4. **Given** I am in insert mode, **When** I press Tab, **Then** indentation is inserted as
   before (buffer cycling applies to normal mode only).

---

### User Story 3 - Visual feedback and roomy line numbers (Priority: P3)

As the user, I want a brief highlight over the text I just yanked and a line-number column wide
enough for 5-digit line numbers, so that I can confirm what was copied and the text never
shifts sideways while scrolling large files.

**Why this priority**: Comfort improvements; no workflow depends on them.

**Independent Test**: Yank a word, a line and a visual selection and watch for the highlight;
open a file with more than 10 000 lines and scroll from the top to the bottom while watching
the text's left edge.

**Acceptance Scenarios**:

1. **Given** a buffer, **When** I yank text by any yank command (word, line, visual
   selection), **Then** exactly the yanked region is briefly highlighted and the highlight
   then disappears on its own.
2. **Given** I delete or change text, **When** the operation completes, **Then** no yank
   highlight is shown.
3. **Given** a file with up to 99 999 lines, **When** I scroll from the first line to the last,
   **Then** the line-number column keeps the same width and the text does not shift
   horizontally.

---

### Edge Cases

- In terminals, Tab and Ctrl+I send the same key code; remapping Tab therefore also takes over
  Ctrl+I's "jump forward in the jump list" in normal mode. This trade-off is accepted:
  jump-forward is not remapped elsewhere, and Ctrl+O (jump back) keeps working.
- Only file buffers (FR-010) take part in cycling; unlisted and special buffers are skipped.
  From a special buffer, Tab/Shift+Tab go to the nearest file buffer in that direction.
- Pressing Escape in normal mode when there is no active search highlight MUST do nothing
  visible and MUST NOT ring an error.
- Very large match counts or huge files: see FR-009.
- If the search pattern has no matches, no label is shown (the editor's normal "pattern not
  found" message applies).
- If the current match is scrolled out of view, the label is not visible either; it is shown
  again when the match is on screen.
- If a search uses an offset that leaves the cursor outside the match (e.g. `/foo/+1`,
  `/foo/e+1`), no label is shown; offsets that stay inside the match (e.g. `/foo/e`) show it
  normally.
- If the match's line is as wide as the window, the label may cover the line's last visible
  characters; this is acceptable, as the label disappears when search is cleared.
- The position label is decoration only: it MUST NOT be inserted into the file, copied by a
  yank, or change the line's content.
- Editing the buffer while a label is shown MUST NOT leave a stale label on the wrong line; the
  label is removed or refreshed.
- Files with more than 99 999 lines may widen the number column beyond 5 digits; this is
  acceptable.

## Requirements *(mandatory)*

### Functional Requirements

**Search behaviour**

- **FR-001**: Incremental search MUST be off: while a search pattern is being typed the cursor
  MUST NOT move and matches MUST NOT be previewed.
- **FR-002**: Search MUST ignore case unless the pattern contains at least one upper-case
  letter, in which case it MUST be case-sensitive ("smart case").
- **FR-003**: After a search is confirmed, all matches MUST be highlighted.
- **FR-004**: Pressing Escape in normal mode MUST clear the search match highlights without
  forgetting the last search pattern (jumping to the next match shows them again).

**Search position label**

- **FR-005**: When the cursor is on a search match after a search or a jump to the next/previous
  match, a label in the form `[current/total]` MUST be shown next to that match, where
  `current` is the 1-based index of the match and `total` the number of matches in the buffer.
  The label MUST be displayed right-aligned at the window's right edge on the line containing
  the match, without shifting or overlapping the line's text on screen where the line is short
  enough to leave room.
- **FR-006**: At most one label MUST exist at a time; it MUST follow the current match on
  every next/previous jump, including word-under-cursor searches. If the same buffer is shown
  in several windows, the label appears in each of them on the match's line.
- **FR-007**: The label MUST disappear when search highlights are cleared (Escape in normal
  mode, or the equivalent clear-highlight command) and when the buffer is edited or the
  window switched to another buffer. Moving the cursor away from the match with ordinary
  motions MUST NOT remove or move the label.
- **FR-008**: The label MUST be visual decoration only and MUST NOT modify buffer content.
- **FR-009**: Determining the total MUST take no longer than 100 ms per search jump; above
  999 matches the label MAY show the total as a lower bound (e.g. `>999`), and if counting
  runs out of time the label MAY show `[?/?]`.

**Buffer cycling**

- **FR-010**: In normal mode, Tab MUST switch the current window to the next file buffer and
  Shift+Tab to the previous one, wrapping from last to first and first to last. A *file
  buffer* is a listed buffer that is not a special buffer (help, quickfix, terminal, file
  explorer). The order is the fixed order in which buffers were opened; switching buffers
  MUST NOT reorder it.
- **FR-011**: With a single file buffer, Tab and Shift+Tab MUST do nothing and show no error.
- **FR-012**: Tab in insert mode and other modes MUST keep its existing behaviour.
- **FR-012a**: Jump-forward (Ctrl+I) is intentionally given up in normal mode and MUST NOT be
  remapped to another key; Ctrl+O (jump back) MUST keep its default behaviour.

**Yank feedback**

- **FR-013**: After any yank, the yanked region MUST be highlighted briefly (well under a
  second) and the highlight MUST clear automatically; deletes and changes MUST NOT trigger it.

**Line-number column**

- **FR-014**: The line-number column MUST always reserve enough width to display 5-digit line
  numbers (plus the usual separating space), so its width does not change for files up to
  99 999 lines.

**Conventions** (per Constitution Principles II, IV and V)

- **FR-015**: Every new key mapping MUST carry a human-readable description.
- **FR-016**: Starting the editor headlessly and quitting MUST still produce no errors or
  warnings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For any search with N matches, stepping through all of them shows a label whose
  index goes 1 … N (or wraps accordingly) and is correct in 100% of steps.
- **SC-002**: A single Escape press removes 100% of search highlights and labels.
- **SC-003**: With 3 open files, every buffer is reachable in at most 2 Tab or Shift+Tab presses.
- **SC-004**: Every yank produces a visible highlight that disappears on its own in under 1
  second.
- **SC-005**: Scrolling a 50 000-line file from top to bottom produces 0 horizontal shifts of
  the text.
- **SC-006**: Startup time on an empty buffer remains under 100 ms and headless start/quit
  produces 0 messages (Constitution Principles III and IV).
- **SC-007**: On a 50 000-line file, each search jump shows its label with no perceptible
  delay (counting bounded to 100 ms).

## Assumptions

- "Search is closed" means the search highlights are cleared (by Escape or the equivalent
  command); see FR-007 for the full set of events that remove the label.
- Search highlighting stays on after a confirmed search (Neovim's default); Escape is the way
  to dismiss it.
- Escape in normal mode keeps any other default effect it already has (e.g. cancelling a
  pending count or operator).
- The yank highlight uses the editor's built-in highlight-on-yank facility and the colour
  scheme's default yank/visual highlight colour; duration of about 150–300 ms is acceptable.
- "5 digits" refers to the line-number column; the relative/absolute numbering from feature
  001 is unchanged.
- The label applies to searches with `/`, `?`, `n`, `N`, `*` and `#`; substitute commands and
  other pattern-based commands are out of scope.
- No plugins are expected to be required (Constitution Principle I); the editor's built-in
  search count and inline decorations are assumed sufficient.
