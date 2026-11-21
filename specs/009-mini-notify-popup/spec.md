# Feature Specification: Notifications via mini.notify

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: "Replace notificatons popup implementation with `mini.notify`
plugin. Use nvim built in `vim.pack`. Plugin defaults are good enough."

## Overview

Feature 008 (Notification Popup) added a hand-written popup for notifications. It works, but it
is a few hundred lines of custom code that must be maintained, and it re-implements something a
small, well-maintained, single-purpose plugin already does. This feature replaces the custom
popup with the `mini.notify` plugin, installed through the editor's built-in plugin manager and
used with its default settings. This feature supersedes the custom-popup requirements of
feature 008 (in particular its "no plugin" requirement, FR-011) wherever they conflict.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Notifications still appear in a popup (Priority: P1)

As the editor's sole user, when the editor or one of its features notifies me of something (for
example "Diagnostics: off", "Buffer is read-only" or "No language server can format this
buffer"), I want the message to keep appearing in a non-intrusive popup, so that the switch to a
plugin is invisible in day-to-day use apart from the popup's default look and timing.

**Why this priority**: This is the whole point of the feature: same user value, less custom code.

**Independent Test**: Start the editor, toggle diagnostics with the existing Leader+td mapping,
and check that the toggle's message appears in a popup drawn by the plugin, while the cursor
stays in the buffer and typing is not interrupted.

**Acceptance Scenarios**:

1. **Given** the editor has started, **When** a notification is issued, **Then** it appears in
   the plugin's notification popup.
2. **Given** I am typing in insert mode, **When** a notification appears, **Then** the cursor
   stays where it was, the popup does not take focus, and my typing continues uninterrupted.
3. **Given** a notification has been shown, **When** the plugin's default display time has
   passed, **Then** it disappears by itself without any action from me.
4. **Given** notifications issued while the editor is still starting up, **When** the editor
   has finished starting, **Then** those notifications are not lost and do not raise errors.

---

### User Story 2 - The custom implementation is gone (Priority: P1)

As the maintainer of this configuration, I want the hand-written notification popup removed
entirely, so that there is a single notification mechanism and no dead code to maintain.

**Why this priority**: Explicitly requested ("replace"); keeping both would mean two competing
popups or dead code.

**Independent Test**: Search the configuration for the custom popup code and its settings
(dismissal delay, maximum entries, hand-made window drawing); none remain, and the README
describes the plugin-based behaviour instead.

**Acceptance Scenarios**:

1. **Given** the change is complete, **When** I look at the configuration, **Then** none of the
   custom popup code remains; the notifications module only installs and enables the plugin.
2. **Given** the change is complete, **When** I read the README, **Then** the Notifications
   section describes the plugin-based behaviour and lists the plugin, and no longer mentions the
   removed settings.
3. **Given** a notification is issued, **When** it is displayed, **Then** exactly one popup shows
   it (never both a custom and a plugin popup).

---

### User Story 3 - Plugin installs itself on a fresh machine (Priority: P2)

As the user setting up a new machine, I want the notification plugin to be installed
automatically by the editor's built-in plugin manager the first time the editor starts, so that
cloning the configuration is still all that is needed.

**Why this priority**: Required by the constitution (Principle IV), but only matters on first
start or a fresh install.

**Independent Test**: Remove the plugin's installed copy, start the editor with network access,
and check that the plugin is installed and notifications work without manual steps. Then start
the editor with the plugin missing and no network access, and check that it still starts and is
usable.

**Acceptance Scenarios**:

1. **Given** a fresh clone with the plugin not yet installed, **When** the editor starts with
   network access, **Then** the plugin is installed automatically and notifications appear in
   its popup.
2. **Given** the plugin cannot be installed or loaded, **When** the editor starts, **Then** the
   editor still starts and is usable, and notifications fall back to the editor's standard
   behaviour instead of raising errors.

---

### Edge Cases

- Headless runs (no screen): with the plugin already installed, starting and quitting produce no
  errors or messages. The very first run on a fresh clone may print the plugin manager's
  installation progress; this is not an error.
- The plugin is unavailable (no network on first start, failed download): the editor starts
  normally and notifications still reach the user through the editor's built-in display.
- A notification arriving while the command line, completion menu or another popup is open does
  not close or move those, and the notification popup does not take focus.
- Very narrow or short editor window and resizing: handled by the plugin's defaults; no errors
  are raised.
- The plugin's default extras (such as showing language-server progress) are accepted as they
  come, per "defaults are good enough".

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every notification issued through the editor's standard notification mechanism
  MUST be displayed by the `mini.notify` plugin.
- **FR-002**: The plugin MUST be used with its default settings; no options MAY be overridden
  beyond what is needed to enable it and route notifications to it.
- **FR-003**: The plugin MUST be installed and managed by the editor's built-in plugin manager
  (`vim.pack`); no third-party plugin manager MAY be introduced.
- **FR-004**: The hand-written notification popup and all its settings MUST be removed, and
  nothing in the configuration MAY reference it.
- **FR-005**: Notifications MUST NOT take focus, move the cursor, change mode or interrupt typing.
- **FR-006**: Notifications issued during startup (before the screen is drawn) MUST NOT be lost
  or raise errors.
- **FR-007**: If the plugin is missing or fails to load, the editor MUST start without errors and
  notifications MUST still be delivered through the editor's built-in mechanism.
- **FR-008**: The plugin MUST carry a one-line justification stating what core Neovim lacks
  (Constitution Principle I).
- **FR-009**: The README MUST describe the new notification behaviour, list the plugin, and
  explain how to review past notifications.
- **FR-010**: The change MUST NOT add or change any key mapping, and starting the editor
  headlessly and quitting MUST still produce no errors.

### Key Entities

- **Notification**: a message with its text and level (error, warning, information, or other),
  issued by the editor or a feature of the configuration.
- **Notification plugin**: the `mini.notify` plugin, installed by the built-in plugin manager,
  which displays notifications in its own popup using its defaults.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of attempts, a notification issued after startup is visible in the
  plugin's popup within 100 ms.
- **SC-002**: Typing continues uninterrupted while notifications appear: 0 keystrokes are lost or
  redirected to the popup.
- **SC-003**: The configuration contains 0 lines of custom notification-popup code after the
  change (the notifications module only installs and enables the plugin).
- **SC-004**: On a fresh clone, the editor reaches a working state with working notifications
  with 0 manual steps beyond starting it with network access.
- **SC-005**: With the plugin unavailable, the editor still starts with 0 errors.
- **SC-006**: The number of user-defined key mappings is unchanged, startup time on an empty
  buffer stays under 100 ms, and, with the plugin installed, headless start/quit produces 0
  messages.

## Assumptions

- The user has explicitly chosen `mini.notify` and the built-in plugin manager; these named
  technologies are constraints of the request, not implementation choices left open.
- "Plugin defaults are good enough" means the popup's position, look, title, size, display time
  per level, maximum entries and any default extras (such as language-server progress) are
  whatever the plugin provides by default. Differences from feature 008 (for example a different
  display time, no fixed limit of three entries, or a slightly different look) are accepted.
- Past notifications are reviewed through the plugin's own notification history rather than the
  editor's message history; recording notifications in the editor's message history (feature
  008's FR-009) is no longer required. No key mapping is added for viewing the history; it is
  reached through the plugin's history function, documented in the README.
- Only the notification part of the `mini` family is wanted; no other modules are enabled.
- The plugin is tracked at its default (latest) version as resolved by the built-in plugin
  manager; the machine-local lockfile stays uncommitted.
- The plugin has to be active early enough to catch notifications issued during startup;
  loading it at startup is justified because notifications can come from any module, and its
  cost must keep startup within the constitution's limit.
- Justification for the plugin (Principle I): core Neovim shows notifications only on the
  command line, where they are easily missed or overwritten; it has no notification popup.
  The plugin replaces a larger amount of custom code, reducing maintenance.
