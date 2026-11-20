# Feature Specification: clangd Language Server with Built-in Formatting

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Add clangd language server support. Code formatting is done via
clangd itself."

## Clarifications

### Session 2026-11-20

- Q: When clangd is attached, what should the built-in `gq` operator do in C-family buffers?
  → A: Keep the editor default: `gq` formats the selected lines through clangd's range
  formatting, honouring `.clang-format`.
- Q: Should accepting a completion automatically insert a missing `#include`? → A: Yes,
  keep clangd's default include-insertion behaviour; the configuration passes no option to
  change it. The editor's default LSP omni-completion applies clangd's extra edits when an
  item is accepted with `<C-y>`; no auto-trigger.
- Q: Should the configuration help clangd find a compilation database in non-standard build
  directories (e.g. `build-debug/`)? → A: No; rely on clangd's own discovery only. Such
  projects use a project `.clangd` file or a symlink, and the README documents how.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Language intelligence while editing C and C++ files (Priority: P1)

As the editor's sole user, when I open a C, C++ or Objective-C source or header file I want the
clangd language server to start automatically, so that I get diagnostics, completion, hover
documentation, go-to-definition and find-references while editing.

**Why this priority**: This is the core of the request; without the server there is no C/C++
support at all, and formatting (Story 2) is a part of the overall experience.

**Independent Test**: Open a `.cpp` file of a small CMake project that has a compilation
database, wait for the server to attach, then request completion on a member of a standard
library type, hover over a function, go to the definition of a function declared in a project
header, and introduce a type error.

**Acceptance Scenarios**:

1. **Given** clangd is installed, **When** I open a C, C++, Objective-C, Objective-C++ or CUDA
   file (source or header), **Then** the server attaches to the buffer within 5 seconds without
   any manual command.
2. **Given** the server is attached, **When** I request completion after typing the start of a
   member or identifier, **Then** matching symbols, including those from included headers, are
   offered; accepting a symbol (with `<C-y>`) from a header that is not yet included also
   inserts the corresponding `#include`, and a single undo removes it. Accepting a function
   inserts its parameters as placeholders that `<Tab>` moves between.
3. **Given** the server is attached, **When** I hover over a function or type, **Then** its
   signature and documentation are shown in the (bordered) hover popup.
4. **Given** the server is attached, **When** I go to the definition of a symbol declared in
   another file of the project, **Then** that file is opened at the definition.
5. **Given** the server is attached, **When** the code contains a compile error, **Then** a
   diagnostic is shown, governed by the existing diagnostic toggles (`<leader>td`,
   `<leader>tt`, `<leader>tl`).
6. **Given** the project provides a compilation database (`compile_commands.json`, possibly in
   a build directory) or `compile_flags.txt`, **When** I open a file of that project, **Then**
   include paths and compiler flags from it are honoured (no false "file not found" errors for
   project headers).
7. **Given** I have not opened any C-family file, **When** I start the editor on another file
   type or an empty buffer, **Then** clangd is not started.

---

### User Story 2 - Format C and C++ files with clangd (Priority: P2)

As the user, I want `<leader>lf` in a C-family buffer to format the whole file using clangd's
own formatting, so that code follows the project's `.clang-format` style exactly as
`clang-format` would apply it from the command line or in CI — without needing a separate
formatter integration.

**Why this priority**: Explicitly requested, but useful only once Story 1 provides the server.

**Independent Test**: Mis-indent and mis-space a few lines in a `.cpp` file of a project with a
`.clang-format`, press `<leader>lf`, and compare the buffer with the output of running
`clang-format` on the same content in the same project.

**Acceptance Scenarios**:

1. **Given** a C-family buffer with badly formatted code and clangd attached, **When** I press
   `<leader>lf` in normal mode, **Then** the whole buffer is reformatted by clangd.
2. **Given** the project has a `.clang-format` file (in the file's directory or a parent),
   **When** I press `<leader>lf`, **Then** the result honours that style.
3. **Given** the project has no `.clang-format` file, **When** I press `<leader>lf`, **Then**
   clangd's own fallback style is applied; this configuration supplies no style of its own.
4. **Given** an already formatted buffer, **When** I press `<leader>lf`, **Then** the buffer
   content is unchanged and the buffer is not marked modified.
5. **Given** I formatted a buffer, **When** I press undo once, **Then** the whole formatting
   change is reverted.
6. **Given** clangd is not installed or not attached, **When** I press `<leader>lf` in a
   C-family buffer, **Then** the buffer is unchanged and the existing single, non-blocking
   message says that no language server can format the buffer.
7. **Given** clangd is attached, **When** I use `gq` on a selection of lines, **Then** only
   those lines are reformatted by clangd following the applicable `.clang-format` style.

---

### Edge Cases

- If clangd is not installed, opening a C-family file MUST NOT raise an error or show a
  message; editing works without language features, and the missing server is reported only by
  the editor's health check (`:checkhealth`) — consistent with the Lua and CMake servers.
- If the project has no compilation database, the server still attaches and works with default
  flags; resulting spurious diagnostics are acceptable and no extra message is shown.
- If the compilation database lives in a build directory clangd does not search (anything other
  than the file's directory, its parents, or a `build/` subdirectory of those), it is not found
  and the previous bullet applies; the configuration does not search for it.
- If the server crashes or exits, the editor MUST stay usable and no repeated error messages
  are shown.
- A C-family file opened outside any project (no root marker found) still gets the server for
  that single file; indexing MUST NOT scan unrelated parts of the user's home directory.
- Header files (`.h`) are treated as C-family and get the server; whether a `.h` file is C or
  C++ follows the editor's own file-type detection.
- Pressing `<leader>lf` in a read-only C-family buffer MUST NOT modify it and produces at most
  one message, saying that the buffer is read-only (existing behaviour).
- Unsaved buffers are formatted from their current content, not from the file on disk.
- `<leader>lf` in non-C-family buffers keeps its current behaviour (Lua via its language
  server, CMake via gersemi).
- Opening Lua, CMake and C++ files in the same session runs all servers side by side; each
  attaches only to its own file types.

## Requirements *(mandatory)*

### Functional Requirements

**clangd language server**

- **FR-001**: The configuration MUST enable clangd for C, C++, Objective-C, Objective-C++ and
  CUDA buffers, started automatically when the first such buffer is opened and not before.
- **FR-002**: The server MUST provide its diagnostics, completion, hover, go-to-definition and
  find-references in those buffers; its diagnostics MUST obey the existing diagnostic toggles
  and display settings.
- **FR-003**: The server's project root MUST be determined from project markers (clangd
  configuration, compilation database, compile flags file, or the repository) containing the
  file, without hand-maintained absolute paths, so that it works unchanged on another machine
  (Constitution Principle IV).
- **FR-004**: The configuration MUST NOT pass compilation flags or a compilation-database path
  of its own; clangd's own discovery of `compile_commands.json` / `compile_flags.txt` is relied
  on.
- **FR-004a**: clangd's default behaviour options (including automatic `#include` insertion on
  completion) MUST be left unchanged; the configuration does not override them.
- **FR-004b**: In C-family buffers, accepting an LSP completion item MUST apply the item's
  extra edits (such as the `#include` insertion) and expand snippet items, such as function
  argument placeholders, which `<Tab>`/`<S-Tab>` (the editor's default snippet jumps) move
  between. Completion MUST still start only on request
  (`<C-x><C-o>`, no auto-trigger) and MUST NOT add key mappings. Completion in other file types
  MUST behave as before this feature.

**Formatting with clangd**

- **FR-005**: `<leader>lf` in a C-family buffer MUST format the entire buffer through clangd,
  using the buffer's current (possibly unsaved) content.
- **FR-006**: Formatting MUST follow the project's `.clang-format` when one applies to the
  file; otherwise clangd's fallback style applies. This configuration MUST NOT supply a
  formatting style of its own or derive one from `.editorconfig`.
- **FR-007**: A single undo MUST revert a formatting operation; formatting an already formatted
  buffer MUST leave it unmodified.
- **FR-008**: A separate formatter tool (e.g. a standalone `clang-format` invocation) MUST NOT
  be added; clangd is the only formatting path for C-family buffers.
- **FR-008a**: clangd's range formatting MUST remain enabled, so that the built-in `gq`
  operator formats the selected lines through clangd (the editor's default behaviour with an
  attached server); no special handling of `gq` is added.
- **FR-009**: `<leader>lf` in non-C-family buffers MUST behave as before this feature.

**Keymap scope**

- **FR-010**: The configuration MUST NOT add any key mapping; formatting reuses the existing
  `<leader>lf` mapping, and no language-server mappings are added on attach.

**Robustness and documentation**

- **FR-011**: Starting the editor headlessly and quitting MUST produce no errors or warnings,
  whether or not clangd is installed.
- **FR-012**: When clangd is not installed, no message MUST appear while editing; the editor's
  health check MUST report it as missing.
- **FR-013**: The README MUST list clangd as an optional external dependency and describe that
  `<leader>lf` formats C-family files through clangd using the project's `.clang-format`. It
  MUST also explain how to make a compilation database in a non-standard build directory
  visible to clangd (a project `.clangd` file naming the directory, or a symlink of
  `compile_commands.json` into the project root).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Opening a C-family file of a project attaches language features within 5 seconds
  in 100% of tries when the server is installed.
- **SC-002**: For any C-family file in a project with a `.clang-format`, the result of
  `<leader>lf` is identical to the output of `clang-format` from the same LLVM installation, run
  on the same content in the same project, in 100% of tries.
- **SC-003**: Formatting an already formatted file produces 0 changed lines.
- **SC-004**: In a project with a valid compilation database, opening a source file that
  compiles cleanly shows 0 diagnostics.
- **SC-005**: Startup time on an empty buffer remains under 100 ms (Constitution Principle III)
  and headless start/quit produces 0 messages, with or without clangd installed.
- **SC-006**: The set of user-defined key mappings grows by exactly 0.

## Assumptions

- clangd is installed separately by the user (e.g. via Homebrew's LLVM or Xcode command-line
  tools) and available on the path; the configuration does not install it.
- No plugin is required (Constitution Principle I): the editor's built-in language-server
  client is sufficient for clangd, including formatting.
- C-family buffers are those the editor itself recognises as the `c`, `cpp`, `objc`, `objcpp`
  or `cuda` file types; protocol-buffer and other files clangd can partially handle are out of
  scope.
- Generating a compilation database is the user's / build system's responsibility (e.g. CMake
  with `CMAKE_EXPORT_COMPILE_COMMANDS`); the configuration does not create, symlink or search
  for one beyond clangd's own discovery.
- clangd-specific extras (switch between source and header, inlay hints, AST view, type
  hierarchy commands) are out of scope; they may be added in a later feature.
- Applying completion extra edits (FR-004b) is the editor's default behaviour for every
  language server; this feature adds no completion settings.
- Format-on-save is out of scope; formatting happens only on request with `<leader>lf`, as for
  Lua and CMake.
- Range formatting via `<leader>lf` is out of scope; it always formats the whole buffer (range
  formatting is available through `gq`, see FR-008a).
- Additional linting (e.g. clang-tidy beyond what clangd reports from the project's own
  `.clang-tidy`) is out of scope.
