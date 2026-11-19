# Feature Specification: Lua Language Server and Diagnostic Toggles

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-19

**Status**: Draft

**Input**: User description: "Add lua language server to the configuration. The configuration
of language server should discover modules/runtime in such way that it does not report `vim`
as unknown/undefined. A few keymaps should be added too: Toggling diagnostics on and off:
Leader+td; Toggling virtual lines with diagnostics on and off: Leader+tl; Toggling virtual text
with diagnostics on and off: Leader+tt; Code formatting via language server: Leader+lf. No
other keymaps should be added."

## Clarifications

### Session 2026-11-19

- Q: Should turning virtual lines on hide diagnostic virtual text (and vice versa)? → A: No —
  the two toggles are independent; both may be on at once.
- Q: Which Lua files get Neovim runtime awareness (`vim` global, API docs)? → A: This config
  plus any Lua project without its own language-server settings; a project's own settings
  take precedence.
- Q: What is the diagnostic display state at startup? → A: Diagnostics on, virtual text on,
  virtual lines off.
- Q: Should the server also read installed plugins? → A: Yes — Neovim runtime, this config's
  modules and all plugins installed through the config, discovered automatically.
- Q: Should a missing language server be announced? → A: No message while editing; the
  missing server is reported only by the editor's health check (`:checkhealth`).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Language intelligence while editing the config (Priority: P1)

As the editor's sole user, when I open a Lua file of this configuration I want a Lua language
server to start automatically and understand the editor's own runtime and this configuration's
modules, so that I get accurate diagnostics, completion, hover and go-to-definition without
false "undefined global `vim`" warnings.

**Why this priority**: Without a correctly configured server, every config file is littered
with false warnings, and the constitution (Principle V) requires config files to be free of
language-server errors — which cannot be checked without it.

**Independent Test**: Open `init.lua` and each file under `lua/config/`, wait for the server to
start, and inspect diagnostics, hover on `vim.api` functions, and go-to-definition on a
`require("config.…")` call.

**Acceptance Scenarios**:

1. **Given** the Lua language server is installed, **When** I open any Lua file of this
   configuration, **Then** the server attaches to the buffer within 5 seconds without any
   manual command.
2. **Given** the server is attached, **When** I look at code that uses `vim` (e.g. `vim.o`,
   `vim.api.nvim_create_autocmd`, `vim.keymap.set`), **Then** no diagnostic reports `vim` as
   an undefined global or unknown field.
3. **Given** the server is attached, **When** I hover over or request completion for an editor
   runtime function (e.g. `vim.api.nvim_buf_get_name`), **Then** its signature and
   documentation are shown.
4. **Given** the server is attached, **When** I go to the definition of `require("config.keymaps")`
   in `init.lua`, **Then** `lua/config/keymaps.lua` is opened.
5. **Given** the current configuration as committed, **When** all its Lua files are checked by
   the server, **Then** zero errors and zero warnings are reported.
6. **Given** I have not opened any Lua file, **When** I start the editor on a non-Lua file or
   an empty buffer, **Then** the language server is not started.

---

### User Story 2 - Control how diagnostics are shown (Priority: P2)

As the user, I want single key sequences to turn diagnostics on and off entirely, and to switch
between showing them as virtual text at the end of the line or as separate virtual lines below
the code, so that I can choose between a quiet screen and full detail depending on the task.

**Why this priority**: Diagnostics are useful only once a server exists (Story 1); the toggles
improve how they are consumed but are not essential.

**Independent Test**: Open a Lua file with a deliberate error (e.g. an undefined local), then
press each toggle key repeatedly and observe the display and the confirmation message.

**Acceptance Scenarios**:

1. **Given** diagnostics are shown, **When** I press Leader+td, **Then** all diagnostics (signs,
   underlines, virtual text and virtual lines) disappear in every buffer and a short message
   confirms they are off; **When** I press Leader+td again, **Then** they reappear with the
   display settings they had before and a message confirms they are on.
2. **Given** diagnostics are on with virtual text shown, **When** I press Leader+tt, **Then** the
   end-of-line diagnostic virtual text disappears (signs and underlines remain) and a message
   confirms the new state; pressing it again restores the virtual text.
3. **Given** diagnostics are on and virtual lines are off, **When** I press Leader+tl, **Then**
   each diagnostic is shown on its own virtual line(s) beneath the affected code and a message
   confirms the new state; pressing it again removes the virtual lines.
4. **Given** diagnostics are toggled off with Leader+td, **When** I press Leader+tt or
   Leader+tl, **Then** the corresponding setting is changed and remembered, takes effect when
   diagnostics are turned back on, and the message says so.
5. **Given** a buffer with no language server (e.g. a plain text file), **When** I press any
   of the three toggles, **Then** the toggle still works and no error is raised.

---

### User Story 3 - Format the current file (Priority: P3)

As the user, I want Leader+lf to format the current buffer using its language server, so that
code follows the project's formatting rules without leaving the editor.

**Why this priority**: Convenient, but formatting can still be done by other means; it depends
on Story 1.

**Independent Test**: Mis-indent a few lines and change quotes in a config Lua file, press
Leader+lf in normal mode, and compare the result with the project's formatting rules.

**Acceptance Scenarios**:

1. **Given** a Lua buffer with an attached server and badly formatted code, **When** I press
   Leader+lf in normal mode, **Then** the whole buffer is reformatted according to the
   project's formatting rules (2-space indent, 80-column limit, double quotes).
2. **Given** a formatted buffer, **When** I press Leader+lf, **Then** the buffer content is
   unchanged.
3. **Given** a buffer with no attached language server able to format, **When** I press
   Leader+lf, **Then** the buffer is not modified and a single, non-blocking message explains
   that no formatter is available.
4. **Given** I formatted a buffer, **When** I press undo once, **Then** the whole formatting
   change is reverted.

---

### Edge Cases

- If the Lua language server is not installed, opening a Lua file MUST NOT raise an error;
  Lua editing works as before without language features and no message is shown; the
  missing server is reported only by the editor's health check (`:checkhealth`).
- If the server crashes or exits, the editor MUST stay usable; diagnostics from it disappear
  and no repeated error messages are shown.
- Lua files outside this configuration: if their project has its own language-server
  settings, those take precedence and no Neovim runtime awareness is injected; otherwise
  they get the same runtime awareness as this configuration.
- With no plugins installed, plugin discovery finds nothing and MUST NOT raise an error.
- Toggle state applies globally (all buffers and windows) and lasts for the editor session;
  it is not persisted across restarts.
- Virtual text and virtual lines are independent toggles; when both are on, a diagnostic may
  be shown both as virtual text and below the line. This is acceptable.
- Pressing Leader+lf while the buffer is read-only MUST NOT modify it and MUST produce at most
  one message, saying that the buffer is read-only.
- Formatting a very large file may take noticeably longer; the editor MUST not lose edits made
  meanwhile (formatting is applied only if the buffer has not changed since the request, or is
  run synchronously).

## Requirements *(mandatory)*

### Functional Requirements

**Lua language server**

- **FR-001**: The configuration MUST enable a Lua language server for Lua buffers, started
  automatically when the first Lua buffer is opened and not before.
- **FR-002**: For files of this configuration, and for any other Lua project that has no
  language-server settings of its own, the server MUST know the editor's Lua runtime
  (the `vim` global and its API, including documentation and type information) so that
  `vim` is never reported as undefined/unknown and its functions offer hover and completion.
- **FR-003**: For files of this configuration, the server MUST resolve this configuration's
  own modules so that `require("config.<name>")` resolves to `lua/config/<name>.lua`.
- **FR-003a**: The server MUST also know every plugin installed through this configuration,
  discovered automatically (no per-plugin list), so that `require("<plugin>")` resolves and
  offers hover, completion and go-to-definition. Plugins added or removed later MUST be
  picked up without changing the server configuration (at most after restarting the server).
- **FR-004**: Runtime discovery MUST NOT require hand-maintained absolute paths; it MUST work
  unchanged after cloning the repository on another machine (Constitution Principle IV).
- **FR-005**: The server's formatting MUST follow the repository's `.editorconfig` rules
  (2-space indent, 80-column limit, double quotes, trailing table separators, explicit call
  parentheses).
- **FR-006**: Workspace analysis MUST be limited so that opening a config file does not cause
  the server to scan unrelated parts of the user's home directory.

**Diagnostic toggles** (normal mode)

- **FR-007**: Leader+td MUST toggle the display of all diagnostics on and off, globally.
- **FR-008**: Leader+tt MUST toggle diagnostic virtual text (shown at the end of the line) on
  and off, globally.
- **FR-009**: Leader+tl MUST toggle diagnostics shown as virtual lines beneath the code on and
  off, globally. Leader+tt and Leader+tl are independent: neither changes the other's state.
- **FR-010**: Each toggle MUST show a brief, non-blocking message stating the new state.
- **FR-011**: Turning diagnostics back on with Leader+td MUST restore the virtual-text and
  virtual-line settings in effect before they were turned off (including changes made while
  off).
- **FR-012**: Initial state at startup: diagnostics on, virtual text on, virtual lines off. This
  state MUST be in effect before the first diagnostic appears on screen, whatever its source.

**Formatting** (normal mode)

- **FR-013**: Leader+lf MUST format the entire current buffer via an attached language server
  that supports formatting.
- **FR-014**: When no attached server can format the buffer, Leader+lf MUST leave the buffer
  unchanged and show one non-blocking message.
- **FR-015**: A single undo MUST revert a formatting operation.

**Keymap scope**

- **FR-016**: Exactly four new key mappings MUST be added (Leader+td, Leader+tl, Leader+tt,
  Leader+lf); the configuration MUST NOT add any other key mapping, including language-server
  mappings on attach. The editor's own built-in default mappings are left as they are.
- **FR-017**: Every new key mapping MUST carry a human-readable description (Constitution
  Principle V).

**Robustness**

- **FR-018**: Starting the editor headlessly and quitting MUST produce no errors or warnings,
  whether or not the language server is installed.
- **FR-018a**: When the language server is not installed, no message MUST appear while
  editing; the editor's health check MUST report the server as missing.
- **FR-019**: The README MUST list the Lua language server as an external dependency and
  document the four new key mappings.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Opening any Lua file of this configuration shows 0 diagnostics mentioning an
  undefined or unknown `vim`, and 0 errors/warnings overall for the committed config.
- **SC-002**: Go-to-definition on each `require("config.…")` call in `init.lua`, and on the
  `require` of any installed plugin, succeeds in 100% of cases.
- **SC-003**: Each of the three toggles changes the visible diagnostic display on the first key
  press, every time, in 100% of tries.
- **SC-004**: Formatting an already-formatted config file produces 0 changed lines; formatting
  a deliberately mangled file yields code that conforms to the project's style rules.
- **SC-005**: Startup time on an empty buffer remains under 100 ms (Constitution Principle III)
  and headless start/quit produces 0 messages, with or without the server installed.
- **SC-006**: The set of user-defined key mappings grows by exactly 4.

## Assumptions

- The Lua language server meant is the widely used `lua-language-server` (`lua_ls`), installed
  separately by the user (e.g. via a system package manager) and available on the path; the
  configuration does not install it.
- No plugin is expected to be required (Constitution Principle I): the editor's built-in
  language-server client, diagnostics and formatting facilities are assumed sufficient.
- "Leader" is the existing leader key (Space); all four mappings are normal-mode only, and
  Leader+lf formats the whole buffer (range formatting is out of scope).
- "Toggle diagnostics" hides and shows diagnostics; it does not stop the server or discard
  its results.
- Built-in default language-server mappings provided by the editor itself (e.g. hover,
  rename, code action) remain available; "no other keymaps" applies to mappings this
  configuration adds.
- Format-on-save is out of scope; formatting happens only on request.
- Language servers for other languages are out of scope for this feature.
