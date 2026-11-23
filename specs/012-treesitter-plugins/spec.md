# Feature Specification: Tree-sitter Parsers and Syntax-Aware Text Objects

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-23

**Status**: Draft

**Input**: User description: "Add treesitter and treesitter object plugins. Tree sitter should be
enabled after a supported language file has been loaded. On any treesitter plugin change and
update should be run. The list of languages that should have parsers installed and enabled is:
asm, c, cmake, cpp, editorconfig, lua, markdown, markdown_inline, python, regex, vim and vimdoc.
URLs of the plugins are:
 - https://github.com/nvim-treesitter/nvim-treesitter
 - https://github.com/nvim-treesitter/nvim-treesitter-textobjects"

## Clarifications

### Session 2026-11-23

- Q: Besides highlighting, should tree-sitter also handle indentation and/or folding? → A:
  Highlighting, indentation and folding are all enabled in supported buffers.
- Q: Which syntax-aware text objects and keys should be provided? → A: `af`/`if` function,
  `ac`/`ic` class, `aa`/`ia` parameter, plus jumps `]f`/`[f` (next/previous function start)
  and `]c`/`[c` (next/previous class start); replacing Neovim's built-in `]c`/`[c` diff-change
  jumps is accepted (outside diff mode, see next answer).
- Q: In diff mode, should `]c`/`[c` jump between classes or diff changes? → A: In a diff-mode
  window `]c`/`[c` keep the built-in diff-change jumps; otherwise they jump between classes.
- Q: When should missing parsers be installed on a fresh machine? → A: When the first
  supported-language file is opened (not at startup); that buffer switches to syntax-tree
  features automatically once its parser is ready.
- Q: Which messages should be shown while parsers are installed or updated? → A: The plugin's
  default progress output (one line per parser; in practice two, see FR-012); the
  configuration adds no messages of its own (except the missing-tools warning required by
  the constitution, see FR-012).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Syntax-tree features in supported languages (Priority: P1)

As the editor's sole user, when I open a file in one of the supported languages (Assembly, C,
C++, CMake, EditorConfig, Lua, Markdown, Python, Vim script or Neovim help) I want the editor to
parse it into a syntax tree and use that tree for highlighting, indentation and folding, so
that these are accurate and consistent across languages — including embedded code such as fenced code
blocks in Markdown, regular expressions inside strings and Lua inside Vim script.

**Why this priority**: This is the core of the request; text objects (Story 3) and parser
upkeep (Story 2) only matter once parsing is active.

**Independent Test**: On a configured machine, open one file of each supported language and
check that the editor reports an active syntax tree for the buffer and that highlighting,
indentation (e.g. after `o` inside a function body) and folds (e.g. `zc` on a function) come
from it; open a Markdown file with a fenced Lua block and a Python file with a regular
expression literal and check that the embedded code is highlighted as its own language.

**Acceptance Scenarios**:

1. **Given** the parsers are installed, **When** I open a file of a supported language,
   **Then** syntax-tree highlighting is active for that buffer, plus folding and indentation
   where the language provides them, without any manual command.
2. **Given** a Markdown file with fenced code blocks in a supported language and inline
   formatting, **When** I open it, **Then** the inline formatting and the fenced code are each
   highlighted by their own language.
3. **Given** a Python, Lua or Vim script file containing a regular expression, **When** I open
   it, **Then** the expression is highlighted as a regular expression where the language marks
   it as one.
4. **Given** I open a file of a language not in the list (e.g. JSON or shell), **When** the
   buffer loads, **Then** it keeps the editor's previous behaviour and no error is shown.
5. **Given** I start the editor on an empty buffer, **When** startup completes, **Then** no
   syntax-tree feature or plugin code has been loaded.
6. **Given** a supported file is opened, **When** it is displayed, **Then** all folds are open;
   **When** I use the fold commands (`zc`, `zo`, `za`, `zM`, `zR`), **Then** they act on code
   structures such as functions, classes and blocks.
7. **Given** the cursor is inside a block in a supported language, **When** I open a new line
   or use `=` on a range, **Then** the indentation follows the code structure.

---

### User Story 2 - Parsers installed and kept in sync automatically (Priority: P2)

As the user, I want the parsers for the listed languages to be installed automatically on a
fresh machine and brought up to date whenever the tree-sitter plugins are installed or updated,
so that parsers never fall out of step with the plugin's queries and I never run a manual
install command.

**Why this priority**: Needed for Story 1 to work on a fresh clone (Constitution Principle IV)
and to avoid broken highlighting after plugin updates, but it is plumbing rather than a
user-visible editing feature.

**Independent Test**: Remove the installed parsers (or start from a fresh clone), start the
editor on an empty buffer and check that nothing is installed, then open a C file and check
that all twelve parsers get installed and the C buffer switches to syntax-tree features; then update the tree-sitter plugins
and check that a parser update is run as part of that change.

**Acceptance Scenarios**:

1. **Given** a fresh clone with no parsers installed, **When** I start the editor on an empty
   buffer, **Then** no parser installation starts.
2. **Given** the parsers are installed, **When** either tree-sitter plugin is installed,
   updated or otherwise changed by the plugin manager, **Then** a parser update runs
   automatically once for that change.
3. **Given** all parsers are installed and up to date, **When** I start the editor normally,
   **Then** no install or update work runs and no message is shown.
4. **Given** a required build tool is missing, **When** I open the first supported file,
   **Then** no installation starts, exactly one non-blocking warning names the missing tools,
   and the editor falls back to its previous behaviour; **Given** the tools are present but an
   install fails (e.g. no network), **Then** the plugin's own output reports it and the editor
   remains usable.
5. **Given** no parsers are installed and the documented external tools are present, **When**
   I open the first file of a supported language, **Then** all missing listed parsers are
   installed in the background without a manual command, the editor stays usable meanwhile,
   and once that file's parser is ready its buffer switches to syntax-tree features without
   being reopened.
6. **Given** parsers are being installed or updated, **When** each parser finishes, **Then**
   the plugin's default progress lines for it are shown, without blocking editing.

---

### User Story 3 - Syntax-aware text objects and jumps (Priority: P3)

As the user, I want text objects based on the syntax tree ("around/inside" function, class and
parameter) and keys to jump between functions and classes, so that I can select, delete,
change or yank whole code constructs with operators and move through code by structure in the
supported programming languages.

**Why this priority**: Explicitly requested, but it builds on Story 1 and is an editing
convenience rather than the core capability.

**Independent Test**: In a C, C++, Lua and Python file, place the cursor inside a function body and
use `vaf`, `vif`, `daa`, `yic` (in a C++ class / Python class) and the jumps `]f`, `[f`, `]c`,
`[c`; confirm the selected ranges and cursor positions match the constructs.

**Acceptance Scenarios**:

1. **Given** the cursor is inside a function in a supported language, **When** I apply an
   operator to the "around function" text object, **Then** the whole function definition is
   affected; with the "inside function" object only its body is affected.
2. **Given** the cursor is inside a class or on a parameter, **When** I use `ac`/`ic` or
   `aa`/`ia`, **Then** the whole class / class body, or the parameter with / without its
   separator, is selected.
3. **Given** a language or cursor position where a construct does not exist, **When** I use
   its text object, **Then** nothing is selected or changed and no error is shown.
4. **Given** text object and jump keys are configured, **When** I list key mappings, **Then**
   each one has a description.
5. **Given** the cursor is anywhere in a buffer with several functions, **When** I press
   `]f` or `[f` (optionally with a count), **Then** the cursor moves to the start of the
   next / previous function; `]c` and `[c` do the same for classes, and the jumps are added
   to the jump list.
6. **Given** a supported file is shown in a diff-mode window, **When** I press `]c` or `[c`,
   **Then** the cursor moves to the next / previous diff change, as built in.

---

### Edge Cases

- If the tools needed to build parsers (`tree-sitter`, a C compiler, `curl`, `tar`) are not
  installed, starting the editor and opening files MUST NOT raise errors; no installation is
  attempted, a single non-blocking warning naming the missing tools is shown once per session
  (on the first supported file), and `:checkhealth nvim-treesitter` (available once a
  supported file has been opened in the session) reports them.
- If the tree-sitter plugins are not yet installed (first start before the plugin manager has
  fetched them, or the fetch failed), the editor MUST start without errors.
- Opening a very large file of a supported language MUST NOT make the editor hang
  noticeably; parsing behaviour for such files follows the editor's built-in limits.
- A file whose type is detected only after loading (e.g. via a modeline or `:set filetype=`)
  MUST get syntax-tree features once its type becomes a supported language.
- Neovim help pages (vimdoc) opened with `:help` count as a supported language file.
- `markdown_inline` and `regex` are injected-only languages: they have no file type of their
  own and are active only inside Markdown and the languages that embed regular expressions.
- If several supported files are opened while installation is running, no second installation
  starts; each buffer switches to syntax-tree features once its parser is ready.
- Parser installation MUST NOT run more than once concurrently, e.g. when several plugin
  change events arrive together.
- The existing CMake and Lua language-server features and `<leader>lf` formatting MUST behave
  exactly as before.
- `]c`/`[c` in a diff-mode window always jump between diff changes, whatever the language;
  in buffers of unsupported languages they keep the built-in meaning everywhere.
- A window that enters or leaves diff mode while a supported file is shown switches the
  meaning of `]c`/`[c` accordingly, without reopening the file.
- A jump key with no further function/class in that direction leaves the cursor in place
  without an error.
- A language without syntax-tree indentation or folding rules (currently: no indentation for
  asm, editorconfig, vim and help; no folding for asm and help) MUST keep the editor's
  built-in indentation and folding for that language.

## Requirements *(mandatory)*

### Functional Requirements

**Plugins**

- **FR-001**: The configuration MUST add nvim-treesitter
  (https://github.com/nvim-treesitter/nvim-treesitter) and nvim-treesitter-textobjects
  (https://github.com/nvim-treesitter/nvim-treesitter-textobjects) through the editor's
  built-in plugin manager, each with a one-line justification of what core Neovim lacks
  (Constitution Principle I).
- **FR-002**: Plugin code MUST NOT be loaded at startup on an empty buffer; it MUST be loaded
  when the first buffer of a supported language is opened (Constitution Principle III).

**Parsers**

- **FR-003**: Parsers MUST be installed for exactly these languages: asm, c, cmake, cpp,
  editorconfig, lua, markdown, markdown_inline, python, regex, vim, vimdoc.
- **FR-004**: Missing parsers from that list MUST be installed automatically without manual
  commands, asynchronously so the editor stays usable during installation. Installation MUST
  be triggered when the first buffer of a supported language is opened, never at startup on
  an empty buffer; all missing listed parsers are installed at that point, not only the one
  for the opened file.
- **FR-004a**: Buffers of supported languages that were opened while their parser was still
  being installed MUST switch to syntax-tree features automatically once it is ready, without
  being reopened.
- **FR-005**: Whenever the plugin manager installs, updates or otherwise changes either
  tree-sitter plugin, a parser update MUST be run automatically, at most once per change.

**Activation**

- **FR-006**: Syntax-tree features MUST be activated for a buffer when it is loaded with (or
  later switched to) a file type whose language is in the list, and only for those buffers.
- **FR-007**: In supported buffers the syntax tree MUST drive highlighting, and MUST drive
  folding and indentation wherever the installed plugin provides fold or indent rules for
  that language; elsewhere the editor's built-in folding and indentation remain. Folding
  settings MUST be local to those buffers' windows, and files MUST open with all folds open.
- **FR-008**: Embedded languages (`markdown_inline` within Markdown, `regex` within languages
  that mark regular expressions, and other listed languages inside Markdown code blocks or
  Vim script) MUST be highlighted by their own parser.
- **FR-009**: Buffers of languages not in the list MUST keep their pre-feature behaviour.

**Text objects**

- **FR-010**: Syntax-aware text objects MUST be available in operator-pending and visual mode
  in supported buffers: `af`/`if` (function outer/inner), `ac`/`ic` (class outer/inner),
  `aa`/`ia` (parameter outer/inner). Every mapping MUST have a description (Constitution
  Principle V).
- **FR-010a**: Jumps MUST be available in normal, visual and operator-pending mode in
  supported buffers: `]f`/`[f` to the start of the next/previous function and `]c`/`[c` to the
  start of the next/previous class, accepting a count and recording the jump in the jump list.
  In a window in diff mode, `]c`/`[c` MUST keep the built-in diff-change jumps.
- **FR-010b**: Text object and jump keys MUST be buffer-local to supported buffers; other
  buffers keep the built-in meaning of these keys.

**Robustness and documentation**

- **FR-011**: Starting the editor headlessly and quitting MUST produce no errors or warnings,
  whether or not the parsers or the external build tools are present.
- **FR-012**: Progress and failures of parser installs and updates that actually run MUST be
  reported through the plugin's default output (progress lines per parser), which MUST NOT
  block editing; the configuration MUST NOT suppress or reformat these messages. Before
  installing or updating, the configuration MUST check that the required build tools are
  available; if any is missing it MUST skip the install/update and show exactly one
  non-blocking warning per session naming the missing tools (Constitution Principle IV). No
  install or update failure may leave the editor unusable.
- **FR-013**: The README MUST list the plugins, the supported languages, the automatic
  parser installation and update behaviour, any external tools needed to build parsers, and
  any added key mappings or text objects.

### Key Entities

- **Supported language list**: the twelve parser names in FR-003; the single source of truth
  for what is installed and which buffers get syntax-tree features.
- **Parser**: a compiled grammar for one language plus its queries, installed per machine and
  not committed to the repository.
- **Text object**: a named code construct (function, class, …) with "around" and "inside"
  variants, bound to a key.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a fresh clone with the documented tools present, all 12 parsers are installed
  after the first supported file is opened, with 0 manual commands and 0 reopened buffers;
  starting on an empty buffer installs 0 parsers.
- **SC-002**: Opening a file of each of the 10 file-backed supported languages shows active
  syntax-tree highlighting in 100% of tries.
- **SC-003**: Every plugin change to either tree-sitter plugin triggers exactly 1 parser
  update; a normal start with up-to-date parsers triggers 0.
- **SC-004**: Startup time on an empty buffer remains under 100 ms (Constitution Principle
  III) and headless start/quit produces 0 messages, with or without parsers installed; the
  only exception is the plugin manager's progress while it installs the two plugins on the
  very first start.
- **SC-005**: Each of the 6 text objects and 4 jumps selects or reaches the expected
  construct in C, C++, Lua and Python test files in 100% of tries (class objects and jumps in
  C++ and Python only).
- **SC-006**: Files of unsupported languages show 0 behavioural changes compared with before
  the feature.
- **SC-007**: In C, C++, CMake, Lua and Python, a new line opened inside a function body is
  indented one level deeper than the function header, and `zc` on a function header closes
  exactly that function (also in Vim script for folding).
- **SC-008**: In diff-mode windows, `]c`/`[c` reach the next/previous diff change in 100% of
  tries, in both supported and unsupported languages.

## Assumptions

- The tree-sitter plugins are installed with the editor's built-in plugin manager, as for any
  future plugin; the plugin lockfile stays uncommitted.
- Building parsers requires external tools (a C compiler and, depending on the plugin version,
  the tree-sitter command-line tool, plus `git`/`curl`/`tar` for downloads); the user installs
  them separately and they are documented in the README. The configuration does not install
  them.
- The plugin versions compatible with the editor's minimum version (0.12) are used; parsers
  for languages the editor already bundles (c, lua, markdown, markdown_inline, vim, vimdoc)
  are still installed from the list so that parsers and queries stay in step.
- Only parsers in the list are installed; other parsers that may already be on the machine are
  neither removed nor activated by this feature.
- Parser installation location is the plugin's default per-user data location, outside the
  repository.
- Incremental selection, context display, text objects or jumps beyond FR-010/FR-010a, and
  language-specific highlighting or indentation tweaks are out of scope.
- Folding sets a high window-local fold level so that files open unfolded; no fold column or
  custom fold text is added.
- No alternative keys for class or diff-change jumps are added; in diff mode class jumps are
  simply unavailable.
- Parsing behaviour for very large files is left to the editor's and plugin's defaults.
