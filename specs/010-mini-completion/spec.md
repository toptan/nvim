# Feature Specification: Completion via mini.completion

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: "Replace custom written completion with `mini.completion` plugin."

## Clarifications

### Session 2026-11-21

- Q: Keep the IDE-style key mappings or use only default keys? → A: Keep `<Tab>`/`<S-Tab>` and
  `<CR>` as today; `<C-Space>` uses the plugin's own trigger.
- Q: Should the automatic menu open in buffers without a language server? → A: Yes, plugin
  default (buffer words).

## Overview

Feature 007 (LSP Completion Autotrigger) added hand-written insert-mode completion: an automatic
menu in buffers with a language server, server suggestions ranked before buffer words, re-asking
the server as the word grows, trigger-character handling and IDE-style keys. It works, but it is
some two hundred lines of custom code that works around several editor quirks and must be
maintained across editor upgrades. This feature replaces it with the `mini.completion` plugin,
installed through the editor's built-in plugin manager (as `mini.notify` was in feature 009).
This feature supersedes the custom-completion requirements of feature 007 (in particular its
"no plugin" assumption) wherever they conflict.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Completion still appears while typing (Priority: P1)

As the editor's sole user, when I type a word or a member-access character (such as `.`, `->` or
`::`) in a buffer with a language server, I want a completion menu with the server's
suggestions to open by itself, so that the switch to a plugin is invisible in day-to-day use
apart from the plugin's default look and timing.

**Why this priority**: This is the whole point of the feature: same user value, less custom code.

**Independent Test**: Open a Lua file (lua_ls attached), type `vim.` and then `ap`; a menu of
server suggestions opens without any key press and narrows as typing continues.

**Acceptance Scenarios**:

1. **Given** a buffer with a language server, **When** I type part of a word and pause briefly,
   **Then** a menu of the server's suggestions opens by itself.
2. **Given** a buffer with a language server, **When** I type one of the server's trigger
   characters (e.g. `.` in Lua, `->` or `::` in C++), **Then** the menu opens with members
   relevant to that position.
3. **Given** the server has no suggestions for the word, **When** the menu would open, **Then**
   matching words from open buffers are offered instead.
4. **Given** the menu is open, **When** I keep typing, **Then** the menu narrows to the matching
   items; nothing is inserted or selected until I choose.
5. **Given** an item is highlighted, **When** the plugin's default details delay has passed,
   **Then** its documentation is shown beside the menu.
6. **Given** a server item that is a snippet, **When** I accept it, **Then** it expands and I can
   jump between its placeholders.

---

### User Story 2 - Familiar keys keep working (Priority: P1)

As the user, I want to keep moving through, accepting and opening the menu with the keys I use
today (`<Tab>` / `<S-Tab>`, `<CR>`, `<C-Space>`), so that my muscle memory is not broken.

**Why this priority**: The keys are how completion is used; losing them would be a daily
regression.

**Independent Test**: With the menu open, press `<Tab>` twice, `<S-Tab>` once and `<CR>`; the
second item is inserted and no new line is added. With the menu closed, `<CR>` inserts a new line
and `<Tab>` inserts a tab (or jumps to the next snippet placeholder when a snippet is active).

**Acceptance Scenarios**:

1. **Given** the menu is open, **When** I press `<Tab>` / `<S-Tab>`, **Then** the next / previous
   item is highlighted without being inserted into the text.
2. **Given** the menu is open with an item highlighted, **When** I press `<CR>`, **Then** the item
   is accepted and no line break is inserted.
3. **Given** the menu is open with nothing highlighted, **When** I press `<CR>`, **Then** the menu
   closes and a line break is inserted.
4. **Given** the menu is closed, **When** I press `<Tab>` / `<S-Tab>`, **Then** I jump between
   snippet placeholders if a snippet is active, otherwise a plain Tab / Shift-Tab is typed.
5. **Given** the menu is closed, **When** I press `<C-Space>`, **Then** the plugin's own
   completion trigger runs and the menu opens immediately (server suggestions where a server is
   attached, otherwise buffer words).

---

### User Story 3 - The custom implementation is gone (Priority: P1)

As the maintainer of this configuration, I want the hand-written completion code removed
entirely, so that there is a single completion mechanism and no dead code to maintain.

**Why this priority**: Explicitly requested ("replace"); keeping both would mean two competing
completion triggers fighting over the same menu.

**Independent Test**: Search the configuration for the custom completion code (custom ranking,
re-request on a growing word, trigger-character handling, per-buffer completion settings set on
server attach); none remain, and the README describes the plugin-based behaviour.

**Acceptance Scenarios**:

1. **Given** the change is complete, **When** I look at the configuration, **Then** none of the
   custom completion logic remains; the completion module only installs and sets up the plugin
   (plus key mappings, if kept).
2. **Given** a word is being typed, **When** the menu opens, **Then** exactly one mechanism opened
   it (never the old automatic completion and the plugin at once).
3. **Given** the change is complete, **When** I read the README, **Then** the Completion section
   describes the plugin-based behaviour, lists the plugin and its key mappings, and no longer
   describes removed behaviour.

---

### User Story 4 - Plugin installs itself on a fresh machine (Priority: P2)

As the user setting up a new machine, I want the completion plugin to be installed automatically
by the editor's built-in plugin manager the first time the editor starts, so that cloning the
configuration is still all that is needed.

**Why this priority**: Required by the constitution (Principle IV), but only matters on first
start or a fresh install.

**Independent Test**: Remove the plugin's installed copy, start the editor with network access;
the plugin is installed and completion works in the same session.

**Acceptance Scenarios**:

1. **Given** a fresh clone with network access, **When** the editor starts and I first enter
   Insert mode, **Then** the plugin is installed without prompts and completion works in the
   same session.
2. **Given** the plugin cannot be installed or loaded, **When** the editor starts and I first
   enter Insert mode, **Then** there are no errors, a single non-blocking notice says
   completion is degraded, and the editor's built-in manual completion keys still work.

### Edge Cases

- Buffers without a language server (Markdown, commit messages, plain text): the menu opens by
  itself as the plugin does by default, offering matching words from open buffers.
- A language server that answers slowly or returns a partial list (clangd stops at 100 items):
  the menu still opens and refines as the word grows, within the plugin's default behaviour; no
  errors are raised.
- Pressing a key while a request is still pending: typing is never blocked or lost.
- The language server detaches or stops while typing: no errors; the menu simply stops offering
  server items.
- Prompt, terminal and special buffers (command-line window, file pickers, help): no errors are
  raised.
- Signature help: the plugin's signature window is the only one shown automatically. The
  editor's own signature help popup appears only when explicitly requested (`<C-s>`), and may
  then cover the plugin's window.
- Headless runs (no screen): with the plugin installed, starting and quitting produce no errors
  or messages.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A completion menu MUST open by itself while a word is typed in any regular buffer,
  and, where a language server offering completion is attached, after its trigger characters.
- **FR-002**: Suggestions MUST come from the language server first; when it has none, matching
  words from open buffers MUST be offered.
- **FR-003**: Completion MUST be provided by the `mini.completion` plugin with its default
  settings, except where a requirement in this spec needs otherwise; every overridden option MUST
  be justified beside it.
- **FR-004**: The plugin MUST be installed and managed by the editor's built-in plugin manager
  (`vim.pack`); no third-party plugin manager MAY be introduced.
- **FR-005**: The hand-written completion logic MUST be removed, and nothing in the configuration
  MAY reference it.
- **FR-006**: Nothing MUST be selected or inserted until the user chooses an item.
- **FR-007**: `<Tab>` / `<S-Tab>` and `<CR>` MUST keep the behaviour of User Story 2 as custom
  key mappings; `<C-Space>` MUST use the plugin's own completion trigger. Every mapping MUST have
  a description.
- **FR-008**: Accepting a snippet item MUST expand it with jumpable placeholders.
- **FR-009**: If the plugin is missing or fails to load, the editor MUST start without errors,
  with at most one non-blocking notice, and the editor's built-in completion keys MUST still work.
- **FR-010**: The plugin MUST carry a one-line justification stating what core Neovim lacks
  (Constitution Principle I).
- **FR-011**: The README MUST describe the new completion behaviour, list the plugin and its key
  mappings.
- **FR-012**: Starting the editor headlessly and quitting MUST still produce no errors, and
  startup time on an empty buffer MUST stay under 100 ms.

### Key Entities

- **Completion item**: a suggestion with its text, kind and optional documentation, coming from
  a language server or from words in open buffers.
- **Completion plugin**: the `mini.completion` plugin, installed by the built-in plugin manager,
  which triggers the menu, gathers items and shows their details.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The menu opens without a key press in 100% of attempts after typing a word prefix
  (any regular buffer) or a trigger character (buffer with a language server), within half a
  second.
- **SC-002**: 0 keystrokes are lost while the menu opens or refines, and every typed character
  appears in the buffer before any pending server answer arrives.
- **SC-003**: The configuration contains 0 lines of custom completion ranking, triggering or
  re-requesting logic after the change.
- **SC-004**: On a fresh clone, completion works with 0 manual steps beyond starting the editor
  with network access.
- **SC-005**: With the plugin unavailable, the editor starts with 0 errors.
- **SC-006**: Headless start/quit produces 0 messages with the plugin installed, and startup time
  on an empty buffer stays under 100 ms.

## Assumptions

- The user has explicitly chosen `mini.completion`; following feature 009, it is installed with
  the editor's built-in plugin manager. These named technologies are constraints of the request,
  not implementation choices left open.
- As in feature 009, plugin defaults are accepted wherever this spec does not require otherwise:
  trigger delays, menu ordering and filtering, the item-details window and its timing, and item
  appearance may differ from feature 007. In particular, feature 007's custom ranking (fuzzy
  score, then server order, server items before buffer words) is not required.
- The editor's completion options set in the options module (menu for a single match, nothing
  preselected, fuzzy narrowing) stay. Item details are shown in the plugin's own window; the
  editor's built-in details preview is turned off so the two never appear at once.
- The plugin is installed and loaded the first time Insert mode is entered, not at startup, so
  startup time is unaffected (Constitution Principle III); cloning and starting the editor is
  still all that is needed (Principle IV).
- Snippets are expanded by the editor's built-in snippet support; no snippet plugin is added.
- Only the completion part of the `mini` family is wanted; no other modules are enabled.
- The plugin is tracked at its default (latest) version; the machine-local lockfile stays
  uncommitted.
- Language-server configuration (which servers, their settings) is unchanged; only how completion
  is triggered and shown changes.
- Justification for the plugin (Principle I): core Neovim's automatic completion does not merge
  language-server and buffer suggestions well, re-ask the server as a word grows, or handle
  multi-character trigger characters without the custom workarounds being removed; the plugin
  does this and replaces a larger amount of custom code.
- Feature 007 opened the menu automatically only where a server was attached; that limit is
  dropped in favour of the plugin's default (automatic menu with buffer words everywhere).
- `<C-Space>` (and `<C-@>`, which most terminals send for it) is handed to the plugin's trigger;
  in buffers without a server it now offers buffer words instead of doing nothing.
- Normal-mode `<Tab>` / `<S-Tab>` buffer switching is unaffected.
