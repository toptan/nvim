# Feature Specification: Diagnostics List in the Location List

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-24

**Status**: Implemented

**Input**: User description: "Add keymaps for LSP diagnostics `<Leader>ld` and LSP workspace
diagnostics `<Leader>lD` display in loclist. The loclist should gain focus. Pressing `<Esc>`
closes the loclist and focus is returned to the buffer. Pressing `Enter/Return` key on
selected item in loclist goes to that line in the file."

## Overview

Diagnostics are shown today only next to the line they belong to (virtual text, virtual lines)
or in a popup for the line under the cursor. There is no way to see all of them at once and
walk through them. This feature adds two keys in the existing `<Leader>l` ("Language") group:
`<Leader>ld` lists the diagnostics of the current buffer and `<Leader>lD` lists the
diagnostics of the whole workspace, both in the editor's location list for the current
window. The list takes focus so it can be browsed right away; `<Esc>` closes it and returns to
the buffer; `<CR>` jumps to the selected diagnostic.

## Clarifications

### Session 2026-11-24

- Q: Should `<Leader>lD` list only diagnostics already held, or ask servers to analyse the
  whole project first? → A: Ask servers that support it to analyse the whole project first,
  then list.
- Q: After `<CR>` jumps to the line, should the list stay open or close? → A: Stays open;
  focus moves to the file window.
- Q: When the project-wide check is slow, what should `<Leader>lD` do? → A: Wait up to about
  2 seconds, then open the list with what has arrived; later results appear on the next
  press.
- Q: How should entries in the diagnostics list be ordered? → A: By severity first (errors,
  warnings, info, hints), then file, line, column.
- Q: Which part of each list entry is coloured with its severity colour? → A: The severity
  label and the message; file name and line/column keep the list's usual colours.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - List the current buffer's diagnostics (Priority: P1)

As the editor's sole user, while editing a file that has diagnostics, I want one key to list
all of them, so that I can see every problem in the file at once and pick one to fix.

**Why this priority**: The core of the request and the most frequent use.

**Independent Test**: Open a Lua file with two deliberate errors and one warning; press
`<Leader>ld`. A list opens below the window with three entries (file, line, column, severity,
message), the cursor is in the list. Move to the second entry, press `<CR>`; the cursor is on
that diagnostic's line and column in the file.

**Acceptance Scenarios**:

1. **Given** a buffer with diagnostics, **When** I press `<Leader>ld` in Normal mode,
   **Then** the location list of the current window is filled with exactly that buffer's
   diagnostics, it opens, and the cursor moves into it.
2. **Given** the list is open and focused, **When** I press `<CR>` on an entry, **Then** the
   window the list belongs to shows that file with the cursor on the entry's line and column.
3. **Given** the list is open and focused, **When** I press `<Esc>`, **Then** the list closes
   and the cursor is back in the window it was opened from, at that window's current
   position (unchanged if no entry was jumped to).
4. **Given** a buffer with no diagnostics, **When** I press `<Leader>ld`, **Then** no empty
   list is opened, the cursor stays where it is, and a short notice says there are no
   diagnostics.

---

### User Story 2 - List the workspace's diagnostics (Priority: P1)

As the user, I want a second key that lists the diagnostics of every file the editor knows
diagnostics for, so that after a change I can see problems it caused in other files.

**Why this priority**: Explicitly requested alongside User Story 1; same interaction.

**Independent Test**: Open two Lua files, each with one error; from the first press
`<Leader>lD`. The list shows both errors, each with its own file name. Select the entry in
the second file and press `<CR>`; the window switches to the second file at that line.

**Acceptance Scenarios**:

1. **Given** diagnostics in several files, **When** I press `<Leader>lD`, **Then** the
   location list of the current window is filled with the diagnostics of all those files,
   errors first (then warnings, info, hints), it opens, and the cursor moves into it.
2. **Given** that list is focused, **When** I press `<CR>` on an entry for another file,
   **Then** the window the list belongs to opens that file at the entry's line and column.
3. **Given** that list is focused, **When** I press `<Esc>`, **Then** the list closes and the
   cursor returns to the window it was opened from, at that window's current position.
4. **Given** no diagnostics anywhere, **When** I press `<Leader>lD`, **Then** no empty list
   is opened and a short notice says there are no diagnostics.
5. **Given** a buffer whose language server can analyse the whole project, **When** I press
   `<Leader>lD`, **Then** that server is first asked to report diagnostics for every project
   file (including files not open), and the list includes them.
6. **Given** a language server that cannot analyse the whole project, **When** I press
   `<Leader>lD`, **Then** the list contains the diagnostics the editor already holds, with no
   error.

---

### User Story 3 - Discoverable from the key-clue window (Priority: P3)

As the user, I want both keys listed with clear descriptions under `<Leader>l` ("Language")
in the key-clue window, so that I can find them without looking them up.

**Why this priority**: Comes for free from giving the keys descriptions; low risk.

**Independent Test**: Press `<Leader>l` and wait; the clue window lists `d` and `D` with
descriptions that distinguish buffer and workspace diagnostics, beside the existing `f`.

**Acceptance Scenarios**:

1. **Given** Normal mode, **When** I press `<Leader>l` and pause, **Then** `d` and `D` are
   listed with distinct descriptions (e.g. "Buffer diagnostics" and "Workspace diagnostics").

### Edge Cases

- After `<CR>` jumps to the line, the list stays open and focus moves to the file window, so
  the next entry can be picked by returning to the list (the editor's usual behaviour).
- `<Esc>` in the list does not also clear search highlights; elsewhere `<Esc>` keeps its
  current behaviour (feature 002) unchanged.
- A location list opened by other means (e.g. `:lopen`) gets the same `<Esc>` and `<CR>`
  behaviour; quickfix list windows are left unchanged.
- Pressing the key again while the list is open refreshes its contents and focuses it; no
  second list window is opened.
- The project-wide check takes longer than 2 seconds: the list opens after 2 seconds with
  the diagnostics known so far; no error or warning is shown, and pressing `<Leader>lD`
  again shows the later results.
- The colour scheme is changed while the list is open: the entries take the new scheme's
  diagnostic colours without reopening the list.
- A location list filled by other means (e.g. `:lvimgrep`) is not coloured by severity; it
  keeps its usual look.
- The diagnostics change while the list is open (e.g. after saving a fix): the list is a
  snapshot and is not updated until the key is pressed again.
- Pressing `<Leader>ld` from inside the list window itself: no errors; the list is not
  replaced by the list's own (empty) diagnostics.
- A buffer with no language server attached, or diagnostics turned off with `<Leader>td`:
  treated as "no diagnostics", with the notice of User Story 1, scenario 4.
- Diagnostics from non-LSP sources: listed the same way as language-server diagnostics.
- An entry whose file has since been deleted or whose line no longer exists: `<CR>` raises no
  error-trace; the editor's usual message is shown.
- The list window is closed by other means (`:lclose`, `<C-w>c`): focus goes wherever the
  editor normally sends it; no errors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `<Leader>ld` in Normal mode MUST fill the current window's location list with
  all diagnostics of the current buffer, of every severity.
- **FR-002**: `<Leader>lD` in Normal mode MUST first ask every language server attached to
  the current buffer that supports it to report diagnostics for the whole project, then fill
  the current window's location list with all diagnostics the editor holds for every file,
  of every severity.
- **FR-002a**: `<Leader>lD` MUST wait for the project-wide results for at most 2 seconds,
  then open the list with whatever diagnostics the editor holds at that moment (no
  automatic updates afterwards); results arriving later MUST appear the next time the key
  is pressed. Servers without project-wide support MUST be skipped silently, and when no
  attached server supports it the list MUST open without waiting.
- **FR-003**: Each entry MUST show file, line, column, severity and message.
- **FR-003a**: In lists filled by these keys, each entry's severity label and message MUST
  be shown in the editor's standard colour for that severity (the plain diagnostic colours
  that the virtual-text and popup colours are based on, as set by the colour scheme). File name
  and line/column MUST keep the list's usual colours.
- **FR-004**: Entries MUST be ordered by severity (errors, then warnings, info, hints), then
  by file, line and column within each severity. The same order applies to both keys.
- **FR-005**: After filling the list, it MUST open and the cursor MUST move into it.
- **FR-006**: When there are no diagnostics to list, the list MUST NOT open, the cursor MUST
  NOT move, and a single non-blocking notice MUST say so.
- **FR-007**: In the location list window, `<Esc>` in Normal mode MUST close the list and
  return the cursor to the window the list belongs to, at that window's current position
  (the original position if no entry was jumped to, otherwise the last entry jumped to).
- **FR-008**: In the location list window, `<CR>` MUST move to the selected entry's file,
  line and column in the window the list belongs to, with the cursor there; the list window
  MUST stay open.
- **FR-009**: Opening the list again while it is open MUST reuse the same list window.
- **FR-010**: Both keys MUST have descriptions, so they appear in the key-clue window under
  the existing "Language" group.
- **FR-011**: No keys outside the location list window MAY change behaviour; in particular
  the global `<Esc>` (clear search highlight) MUST keep working in all other windows.
- **FR-012**: The feature MUST use only built-in editor functionality; no plugin MAY be
  added (Constitution Principle I).
- **FR-013**: Defining the keys MUST NOT load the diagnostic subsystem at startup; startup
  time on an empty buffer MUST stay under 100 ms and a headless start/quit MUST produce no
  errors.
- **FR-014**: The README MUST document `<Leader>ld`, `<Leader>lD` and the list keys.

### Key Entities

- **Diagnostic**: a problem reported for a position in a file: file, line, column,
  severity (error, warning, info, hint), message and source.
- **Location list**: the per-window list of positions the editor provides; filled here with
  diagnostics and shown in its own window below the window it belongs to.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From any buffer with diagnostics, the list is open and focused with one key
  press (two for the leader sequence), in under 0.5 seconds for `<Leader>ld` and under
  2.5 seconds for `<Leader>lD`.
- **SC-002**: The number of entries equals the number of diagnostics in scope in 100% of
  checks (buffer and workspace, sample of at least 3 files and 10 diagnostics).
- **SC-003**: `<CR>` lands on the exact line and column of the selected diagnostic in 100% of
  checks, including entries in files other than the current one.
- **SC-004**: `<Esc>` closes the list and returns the cursor to the window it belongs to, at
  that window's current position, in 100% of checks.
- **SC-004a**: In 100% of checked entries (at least one of each severity), the severity
  label and message have that severity's standard diagnostic colour (the plain colour the
  virtual-text and popup colours are based on), and file name and line/column do not.
- **SC-005**: With no diagnostics in scope, 0 empty lists are opened.
- **SC-006**: Headless start/quit produces 0 messages and startup time on an empty buffer
  stays under 100 ms.

## Assumptions

- "LSP diagnostics" means the editor's diagnostics for the buffer; today these come from
  language servers, and diagnostics from other sources are included too.
- "Workspace" means all files the editor holds diagnostics for after asking capable servers
  to analyse their whole project. Today no configured server takes such a request: lua_ls
  reports whole-project diagnostics on its own (unopened files included), and clangd does
  not report them at all, so for C/C++ only diagnostics already held are listed.
- The location list (per window) is used for both keys as requested, rather than the global
  quickfix list; each window keeps its own list.
- The list opens with the editor's default height and placement (below the current window).
- All severities are listed; filtering by severity is out of scope.
- Terminology: "workspace" names the key and its scope (every file the editor holds
  diagnostics for); "project-wide" is used only for the request sent to language servers.
- "Standard diagnostic colours" means the editor's diagnostic colours for error, warning,
  info and hint as defined by the active colour scheme; no new colours are introduced.
- The `<Esc>` and `<CR>` behaviour applies to every location list window, not only those
  filled by these keys, since the window type cannot tell them apart; quickfix list windows
  are left unchanged.
- The keys are Normal-mode only, like the existing `<Leader>lf`, `<Leader>td`, `<Leader>tt`
  and `<Leader>tl`.
- Leader is `<Space>` (set in the options module); this is unchanged.
