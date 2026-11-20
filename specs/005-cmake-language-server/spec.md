# Feature Specification: CMake Language Server with Gersemi Formatting

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Add support for neocmakelsp language server. The code formatting
should not be done by neocmakelsp, it should be done by gersemi."

## Clarifications

### Session 2026-11-20

- Q: When neocmakelsp is attached, what should the built-in `gq` operator do in CMake buffers?
  → A: neocmakelsp's formatting is disabled entirely; `gq` falls back to the editor's plain
  text formatting, and `<leader>lf` (gersemi) is the only way to format CMake code.
- Q: Which style applies when a CMake project has no gersemi configuration of its own? → A:
  gersemi's own defaults (or a gersemi configuration found in a parent directory); this
  config does not translate `.editorconfig` settings or supply a style of its own.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Language intelligence while editing CMake files (Priority: P1)

As the editor's sole user, when I open a CMake file (`CMakeLists.txt` or a `*.cmake` module) I
want a CMake language server (neocmakelsp) to start automatically, so that I get diagnostics,
completion of commands and variables, hover documentation and go-to-definition while editing
build scripts.

**Why this priority**: This is the core of the request; without the server there is no CMake
support at all, and formatting (Story 2) is only a part of the overall experience.

**Independent Test**: Open a `CMakeLists.txt` of a small CMake project, wait for the server to
attach, then request completion after typing `add_`, hover over a built-in command, go to the
definition of a function defined in an included `*.cmake` file, and introduce a syntax error.

**Acceptance Scenarios**:

1. **Given** neocmakelsp is installed, **When** I open a `CMakeLists.txt` or `*.cmake` file,
   **Then** the server attaches to the buffer within 5 seconds without any manual command.
2. **Given** the server is attached, **When** I request completion after typing the start of a
   built-in command name, **Then** matching CMake commands are offered.
3. **Given** the server is attached, **When** I hover over a built-in CMake command, **Then**
   its documentation is shown in the (bordered) hover popup.
4. **Given** the server is attached, **When** I go to the definition of a function or macro
   defined in another file of the project, **Then** that file is opened at the definition.
5. **Given** the server is attached, **When** the file contains a syntax error, **Then** a
   diagnostic is shown, governed by the existing diagnostic toggles (`<leader>td`,
   `<leader>tt`, `<leader>tl`).
6. **Given** I have not opened any CMake file, **When** I start the editor on another file type
   or an empty buffer, **Then** the CMake language server is not started.

---

### User Story 2 - Format CMake files with gersemi (Priority: P2)

As the user, I want `<leader>lf` in a CMake buffer to format the whole file with gersemi — not
with the language server's own formatter — so that CMake code follows gersemi's style (and the
project's gersemi configuration, if any) the same way it does in the command line and CI.

**Why this priority**: Explicitly requested, but it depends on CMake buffers being recognised
and is useful only after Story 1 provides the editing experience.

**Independent Test**: Mis-indent and mis-case a few commands in a `CMakeLists.txt`, press
`<leader>lf`, and compare the buffer with the output of running gersemi on the same file from
the command line.

**Acceptance Scenarios**:

1. **Given** a CMake buffer with badly formatted code and gersemi installed, **When** I press
   `<leader>lf` in normal mode, **Then** the whole buffer is replaced by exactly what gersemi
   produces for that content.
2. **Given** the project has its own gersemi configuration file, **When** I press `<leader>lf`,
   **Then** the result honours that configuration (identical to running gersemi in that
   project from the command line).
3. **Given** neocmakelsp is attached, **When** I press `<leader>lf`, **Then** neocmakelsp's
   formatter is never used, neither instead of nor in addition to gersemi; **When** I use `gq`
   on a selection, **Then** the editor's plain text formatting is applied, not neocmakelsp's.
4. **Given** an already formatted buffer, **When** I press `<leader>lf`, **Then** the buffer
   content is unchanged and the buffer is not marked modified.
5. **Given** I formatted a buffer, **When** I press undo once, **Then** the whole formatting
   change is reverted.
6. **Given** the buffer contains code gersemi cannot parse, **When** I press `<leader>lf`,
   **Then** the buffer is left unchanged and a single, non-blocking message reports the gersemi
   error.
7. **Given** gersemi is not installed, **When** I press `<leader>lf` in a CMake buffer,
   **Then** the buffer is unchanged and a single, non-blocking message says that gersemi is
   not available.

---

### Edge Cases

- If neocmakelsp is not installed, opening a CMake file MUST NOT raise an error or show a
  message; CMake editing works without language features, and the missing server is reported
  only by the editor's health check (`:checkhealth`) — consistent with the Lua language server.
- If gersemi is not installed, nothing is reported until `<leader>lf` is pressed in a CMake
  buffer (see Story 2, scenario 7); editor start and opening CMake files stay silent.
- If the server crashes or exits, the editor MUST stay usable and no repeated error messages
  are shown.
- A CMake file opened outside any CMake project (no project root found) still gets the server
  for that single file; analysis MUST NOT scan unrelated parts of the user's home directory.
- Pressing `<leader>lf` in a read-only CMake buffer MUST NOT modify it and produces at most one
  message, saying that the buffer is read-only (same behaviour as for Lua).
- Unsaved buffers and buffers without a file name are formatted from their current content,
  not from the file on disk.
- `<leader>lf` in non-CMake buffers keeps its current behaviour (formatting via the attached
  language server); Lua formatting is unaffected.
- Opening Lua and CMake files in the same session runs both servers side by side; each attaches
  only to its own file type.

## Requirements *(mandatory)*

### Functional Requirements

**CMake language server**

- **FR-001**: The configuration MUST enable neocmakelsp for CMake buffers (`CMakeLists.txt`
  and `*.cmake`), started automatically when the first CMake buffer is opened and not before.
- **FR-002**: The server MUST provide its diagnostics, completion, hover and go-to-definition
  in CMake buffers; its diagnostics MUST obey the existing diagnostic toggles and display
  settings.
- **FR-003**: The server's project root MUST be determined from the CMake project (or the
  repository) containing the file, without hand-maintained absolute paths, so that it works
  unchanged on another machine (Constitution Principle IV).
- **FR-004**: neocmakelsp's formatting (whole-buffer and range) MUST be disabled entirely, so
  that no editor formatting path uses it — neither `<leader>lf` nor the built-in `gq` operator.
  In CMake buffers `gq` MUST fall back to the editor's plain text formatting.

**Formatting with gersemi**

- **FR-005**: `<leader>lf` in a CMake buffer MUST format the entire buffer with gersemi, using
  the buffer's current (possibly unsaved) content.
- **FR-006**: gersemi MUST pick up the project's own gersemi configuration when one exists for
  the file being formatted (in its directory or a parent); otherwise gersemi's own defaults
  apply. This configuration MUST NOT supply gersemi style options of its own or derive them
  from `.editorconfig`.
- **FR-007**: If gersemi fails (not installed, parse error, or any other error), the buffer
  MUST remain unchanged and exactly one non-blocking message MUST explain the reason.
- **FR-008**: A single undo MUST revert a gersemi formatting operation; formatting an already
  formatted buffer MUST leave it unmodified.
- **FR-009**: `<leader>lf` in non-CMake buffers MUST behave as before this feature.

**Keymap scope**

- **FR-010**: The configuration MUST NOT add any key mapping; formatting reuses the existing
  `<leader>lf` mapping, and no language-server mappings are added on attach.

**Robustness and documentation**

- **FR-011**: Starting the editor headlessly and quitting MUST produce no errors or warnings,
  whether or not neocmakelsp and gersemi are installed.
- **FR-012**: When neocmakelsp is not installed, no message MUST appear while editing; the
  editor's health check MUST report it as missing.
- **FR-013**: The README MUST list neocmakelsp and gersemi as optional external dependencies
  and describe that `<leader>lf` formats CMake files with gersemi.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Opening a CMake file of a project attaches CMake language features within 5
  seconds in 100% of tries when the server is installed.
- **SC-002**: For any CMake file, the result of `<leader>lf` is byte-for-byte identical to the
  output of gersemi run on the same content in the same project, in 100% of tries.
- **SC-003**: Across all formatting requests in CMake buffers, the CMake language server's
  formatter is used 0 times.
- **SC-004**: Formatting an already formatted CMake file produces 0 changed lines.
- **SC-005**: Startup time on an empty buffer remains under 100 ms (Constitution Principle III)
  and headless start/quit produces 0 messages, with or without the CMake tools installed.
- **SC-006**: The set of user-defined key mappings grows by exactly 0.

## Assumptions

- neocmakelsp and gersemi are installed separately by the user (e.g. via a system or Python
  package manager) and available on the path; the configuration does not install them.
- No plugin is required (Constitution Principle I): the editor's built-in language-server
  client is sufficient for neocmakelsp, and gersemi can be invoked directly as an external
  command for formatting.
- CMake buffers are those the editor itself recognises as the CMake file type
  (`CMakeLists.txt`, `*.cmake`); other CMake-related files (e.g. `CMakePresets.json`,
  `CMakeCache.txt`) are out of scope.
- gersemi's own configuration discovery (a `.gersemirc` in the file's directory or a parent)
  is relied on; the editor configuration supplies no gersemi settings of its own.
- Format-on-save is out of scope; formatting happens only on request with `<leader>lf`, as for
  Lua.
- Range formatting is out of scope; `<leader>lf` always formats the whole buffer.
- Linting beyond what neocmakelsp reports (e.g. a separate CMake linter) is out of scope.
