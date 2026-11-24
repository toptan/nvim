# Feature Specification: Bash Language Server

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-24

**Status**: Draft

**Input**: User description: "Add bash-language-server enablemend and setup to the
configuration."

## Clarifications

### Session 2026-11-24

- Q: Should this feature also add tree-sitter support for shell scripts (a `bash` parser for
  highlighting, folding, indentation and text objects)? → A: Yes; `sh` and `bash` buffers get
  tree-sitter support like the other configured languages.
- Q: Without `.editorconfig` indentation settings, should `<leader>lf` use shfmt's default
  (tabs) or the editor's indentation? → A: The editor's indentation (4 spaces by default); the
  server always takes indentation from the editor.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Language intelligence while editing shell scripts (Priority: P1)

As the editor's sole user, when I open a shell script I want the bash language server to start
automatically, so that I get completion, hover documentation, go-to-definition,
find-references, rename and diagnostics while editing.

**Why this priority**: This is the core of the request; without the server there is no shell
script language support at all.

**Independent Test**: Open a `.sh` file that defines and calls a function and uses a few
variables, wait for the server to attach, then request completion of a command and of a
variable, hover over a built-in command, go to the definition of the function from a call
site, and rename a variable.

**Acceptance Scenarios**:

1. **Given** the bash language server is installed, **When** I open a file the editor
   recognises as a `sh` or `bash` script (by extension such as `.sh`/`.bash`, by a `bash`/`sh`
   shebang, or a file such as `.bashrc`), **Then** the server attaches to the buffer within
   5 seconds without any manual command.
2. **Given** the server is attached, **When** I request completion after typing the start of a
   command, function or variable name, **Then** matching built-ins, commands on the path,
   functions and variables from the script are offered.
3. **Given** the server is attached, **When** I hover over a built-in command or a function
   defined in the script, **Then** its documentation (or the function's definition context) is
   shown in the bordered hover popup.
4. **Given** the server is attached, **When** I go to the definition of a function or variable,
   including one defined in a file the script `source`s, **Then** the cursor moves to its
   definition, opening that file if needed.
5. **Given** the server is attached, **When** I rename a variable or function, **Then** every
   reference in the script is renamed in one step.
6. **Given** the server is attached and ShellCheck is installed, **When** the script contains
   a common mistake (e.g. an unquoted variable expansion), **Then** a diagnostic is shown,
   governed by the existing diagnostic toggles (`<leader>td`, `<leader>tt`, `<leader>tl`) and
   listed by `<leader>ld`.
7. **Given** I have not opened any shell script, **When** I start the editor on another file
   type or an empty buffer, **Then** the bash language server is not started.

---

### User Story 2 - Format shell scripts with `<leader>lf` (Priority: P2)

As the user, I want `<leader>lf` in a shell script to format the whole file through the bash
language server, so that shell scripts follow the project's `.editorconfig` just as Lua files
do, without a separate formatter integration.

**Why this priority**: Formatting completes the "setup" part of the request, but it is useful
only once Story 1 provides the server.

**Independent Test**: Mis-indent a few lines of a `.sh` file in a project with an
`.editorconfig` setting a 2-space indent for shell files, press `<leader>lf`, and confirm the
buffer is re-indented with 2 spaces.

**Acceptance Scenarios**:

1. **Given** a shell script buffer with badly indented code, the server attached and shfmt
   installed, **When** I press `<leader>lf` in normal mode, **Then** the whole buffer is
   reformatted as a single undo step.
2. **Given** the project has an `.editorconfig` (next to the file or in a parent directory)
   with indentation settings for the file, **When** I press `<leader>lf`, **Then** the result
   honours those settings.
3. **Given** shfmt is not installed, **When** I press `<leader>lf` in a shell script, **Then**
   the buffer is left unchanged and a single non-blocking notice says the buffer cannot be
   formatted; no error is raised.
4. **Given** an already formatted buffer, **When** I press `<leader>lf`, **Then** the buffer is
   unchanged and not marked modified.
5. **Given** a script in a directory with no `.editorconfig` indentation settings, **When** I
   press `<leader>lf`, **Then** the buffer is indented with the editor's default indentation
   (4 spaces), not shfmt's own default (tabs).

---

### User Story 3 - Tree-sitter support for shell scripts (Priority: P3)

As the user, I want shell scripts to get the same tree-sitter highlighting, folding,
indentation and text objects as the other languages in this configuration, so that editing
shell scripts looks and behaves consistently.

**Why this priority**: It improves consistency but is independent of the language server and
not part of the original request.

**Independent Test**: Open a `.sh` file containing a function, an `if` block and a here-doc,
confirm tree-sitter is the active highlighter for the buffer, fold the function, and select
the function with the function text object.

**Acceptance Scenarios**:

1. **Given** the tree-sitter prerequisites are available, **When** I open the first shell
   script, **Then** the shell parser is installed in the background like the other parsers, and
   the buffer switches to tree-sitter highlighting once it is ready.
2. **Given** the parser is installed, **When** I open a `sh` or `bash` buffer, **Then**
   highlighting, folding, indentation, and the text objects and jumps work as they do for the
   other configured languages; where shell has no such construct (e.g. classes) the key does
   nothing.
3. **Given** the tree-sitter prerequisites are missing, **When** I open a shell script,
   **Then** the existing single warning about missing tools is shown and the buffer keeps the
   editor's built-in highlighting.

---

### Edge Cases

- **Server not installed**: opening a shell script raises no error; the script is edited as
  before without language features, and the editor's language-server health check reports the
  server as missing.
- **ShellCheck not installed**: the server still provides completion, hover, navigation and
  rename; only ShellCheck diagnostics are absent, with no error or repeated notice.
- **shfmt not installed**: covered by Story 2, scenario 3.
- **zsh and other shells**: files the editor recognises as `zsh`, `fish` or other non-POSIX
  shells do not start the bash language server.
- **Scripts without extension**: a file with a `#!/bin/bash`, `#!/usr/bin/env bash` or
  `#!/bin/sh` shebang starts the server once the editor has recognised its file type.
- **Many scripts in one session**: opening further shell scripts reuses the running server for
  the same project root; no duplicate servers are started.
- **Script outside any project**: a script not inside a git repository still gets language
  features, working on the single file.
- **Read-only buffer**: `<leader>lf` behaves as for other file types (notice, no change).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The configuration MUST start the bash language server automatically for buffers
  whose file type is `sh` or `bash`, on the first such buffer rather than at editor startup.
- **FR-002**: The server MUST NOT be started for any other file type, including `zsh`.
- **FR-003**: The server's project root MUST be the enclosing git repository when there is one;
  otherwise the server MUST work on the single file.
- **FR-004**: When attached, the existing language-server keys and features (completion menu,
  hover, go-to-definition, references, rename, code actions, document symbols, diagnostics
  list) MUST work in shell script buffers without shell-specific key mappings.
- **FR-005**: When ShellCheck is available, its findings MUST be shown as diagnostics and
  follow the existing diagnostic display and toggles; when it is not available, nothing MUST
  fail or notify.
- **FR-006**: `<leader>lf` MUST format the whole shell script buffer through the bash language
  server (which uses shfmt). Indentation MUST follow the buffer's indentation settings, which
  come from the project's `.editorconfig` when it sets them and otherwise from this
  configuration's defaults (4 spaces); other shfmt style options MUST come only from
  `.editorconfig` or shfmt's defaults.
- **FR-007**: When the buffer cannot be formatted (shfmt missing or server not attached),
  `<leader>lf` MUST show the existing single "cannot format" notice and leave the buffer
  unchanged.
- **FR-008**: A missing bash language server, ShellCheck or shfmt MUST NOT produce errors at
  startup or when opening a shell script (Constitution Principle IV).
- **FR-009**: The README MUST list the bash language server as an optional external
  dependency, together with ShellCheck (diagnostics) and shfmt (formatting), stating what is
  lost without each, and MUST include a short section describing the shell script support.
- **FR-010**: No plugin MUST be added for this feature (Constitution Principle I).
- **FR-011**: The shell (`bash`) tree-sitter parser MUST be added to the configured parsers and
  used for buffers of file type `sh` and `bash`, providing highlighting, folding, indentation
  and text objects through the existing tree-sitter setup, with its existing install-on-demand
  and missing-tool behaviour.
- **FR-012**: The README's tree-sitter section MUST list shell scripts among the supported
  languages and among the languages with text objects and jumps.

### Key Entities

- **Shell script buffer**: a buffer the editor recognises as file type `sh` or `bash`; the unit
  the server attaches to.
- **Bash language server**: the external program providing language features for shell
  scripts; optionally delegates diagnostics to ShellCheck and formatting to shfmt.
- **Project root**: the git repository containing the script, or none (single-file mode).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of attempts, opening a shell script with the server installed yields
  working completion, hover and go-to-definition within 5 seconds, with no manual command.
- **SC-002**: Starting the editor on an empty buffer or a non-shell file shows no measurable
  startup-time increase (within normal run-to-run variation) compared to before the change.
- **SC-003**: With any combination of the server, ShellCheck and shfmt missing, opening and
  editing a shell script produces zero error messages and the editor's headless start exits
  cleanly.
- **SC-004**: In a project whose `.editorconfig` sets the indentation for shell files,
  formatting a mis-indented script with `<leader>lf` produces the same result as running shfmt
  on that file from the command line, in 100% of tested cases, and is undone with a single
  undo.
- **SC-005**: A user reading only the README can tell which tools to install for shell script
  support and what each one adds.

## Assumptions

- The bash language server, ShellCheck and shfmt are installed separately by the user (e.g.
  with Homebrew) and available on the path; the configuration does not install them. At the
  time of writing all three are installed on the primary machine.
- Neovim recognises shell scripts (`.sh`, `.bashrc`, extension-less files with a `bash`/`sh`
  shebang) as file type `sh`; `bash` is included in FR-001 for buffers where it is set
  explicitly.
- The server's own defaults are used (e.g. which files it indexes for workspace symbols and
  `source` resolution); the configuration overrides only what is needed for FR-001–FR-007.
- `.editorconfig` settings for shell files, if any, are the project's choice; this repository
  does not gain a shell-specific `.editorconfig` section as part of this feature.
- Format-on-save and range formatting are out of scope; formatting happens only on request
  with `<leader>lf`, as for Lua and CMake. `gq` is not configured specifically for shell
  scripts and does whatever the editor does by default with this server attached.
- Running shell scripts, debugging them, or ShellCheck code-action extras beyond what the
  server offers by default are out of scope.
- zsh support is out of scope: the bash language server does not understand zsh syntax.
