# Feature Specification: Notification Popup

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-21

**Status**: Draft

**Input**: User description: "A display of notifications would add to useability. Notifications
should be visible via popup in top right corner the editor. The popup should contain at most three
notifications. The popup should disappear three seconds after last notification, but this should
be configurable. Popup should have title "Notifications" and should have a border like other
popups."

## Clarifications

### Session 2026-11-21

- Q: When several notifications are in the popup, do they disappear together after the last one
  arrives, or each on its own? → A: Each notification disappears from the popup three seconds
  (the configurable delay) after it appeared; when the last remaining notification is removed,
  the popup closes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See notifications in a popup (Priority: P1)

As the editor's sole user, when the editor or one of its features notifies me of something (for
example "Diagnostics: off", "Buffer is read-only" or "No language server can format this
buffer"), I want the message to appear in a bordered popup titled "Notifications" in the top
right corner of the editor, so that I notice it without it being lost in, or overwritten on, the
command line, and without it interrupting what I am typing.

**Why this priority**: This is the core of the request. Today notifications appear briefly on the
command line, where they are easy to miss and are replaced by the next message.

**Independent Test**: Start the editor, toggle diagnostics with the existing Leader+td mapping,
and check that a popup titled "Notifications" with the usual popup border appears in the top
right corner showing the toggle's message, while the cursor stays in the buffer.

**Acceptance Scenarios**:

1. **Given** no notification is showing, **When** a notification is issued, **Then** a popup
   appears in the top right corner of the editor containing that notification's text.
2. **Given** the popup is showing, **When** I look at it, **Then** it has the title
   "Notifications" on its border and the same border style as the editor's other popups.
3. **Given** I am typing in insert mode, **When** a notification appears, **Then** the cursor
   stays where it was, the popup does not take focus, and my typing continues uninterrupted.
4. **Given** notifications of different levels (error, warning, information), **When** they are
   shown, **Then** each is coloured by its level, matching the colours used for that severity
   elsewhere in the editor, so an error stands out from information.

---

### User Story 2 - Several notifications at once (Priority: P1)

As the user, when several notifications arrive close together, I want to see the most recent
ones together in the same popup, so that a later message does not hide an earlier one I have not
read yet, while the popup never grows to cover a large part of the screen.

**Why this priority**: Explicitly requested ("at most three notifications"); without it, bursts
of messages would either be lost or flood the screen.

**Independent Test**: Toggle diagnostics four times in quick succession and check that the popup
shows exactly three entries — the three newest — in the order they arrived. Then toggle twice,
about one second apart, and check that the first entry leaves the popup three seconds after it
appeared while the second stays, and that the popup closes when the second entry expires.

**Acceptance Scenarios**:

1. **Given** one notification is showing, **When** a second arrives, **Then** both are shown in
   the same popup, clearly separated, in the order they arrived with the newest last.
2. **Given** three notifications are showing, **When** a fourth arrives, **Then** the oldest is
   removed and the popup shows the three newest.
3. **Given** the popup holds fewer than three notifications, **When** it is drawn, **Then** it is
   only as tall as its contents, with no empty placeholder rows.
4. **Given** the popup holds several notifications, **When** the oldest one has been shown for
   three seconds, **Then** that notification alone is removed, the others stay, and the popup
   shrinks to fit the remaining entries.
5. **Given** the popup holds a single notification, **When** that notification is removed,
   **Then** the popup closes.

---

### User Story 3 - Automatic dismissal with a configurable delay (Priority: P2)

As the user, I want each notification to disappear by itself a short time after it appears, and
the popup to close once it is empty, and I want to be able to change that time in one place, so
that the popup never needs manual closing and I can tune how long messages stay visible.

**Why this priority**: Requested, but the popup is already useful with a fixed delay; the
configurable value refines it.

**Independent Test**: Issue a notification and time how long the popup stays; issue a second one
two seconds later and check the first leaves after three seconds while the second stays until
three seconds after it appeared, at which point the popup closes. Change the configured delay to
five seconds, restart, and check each notification now stays for five seconds.

**Acceptance Scenarios**:

1. **Given** the default configuration, **When** a notification is shown and no other follows,
   **Then** it is removed and the popup closes three seconds after it appeared.
2. **Given** the popup is showing a notification, **When** another arrives before the first
   expires, **Then** the first is still removed three seconds after it appeared, and the popup
   stays open, showing the second, until three seconds after the second appeared.
3. **Given** the delay has been changed in the configuration, **When** a notification is shown,
   **Then** it is removed after the configured delay instead of three seconds.
4. **Given** the popup has closed, **When** a new notification arrives, **Then** a fresh popup
   shows only the new notification, not the ones that were previously dismissed.

---

### Edge Cases

- A notification longer than the popup's maximum width wraps (FR-010); no text is drawn on or
  outside the border.
- A single multi-line notification counts as one notification, not several.
- An empty notification does not open an empty popup.
- Very narrow or short editor window: the popup still opens without errors and stays fully inside
  the editor, shrinking or wrapping as needed rather than having its border cut off.
- Resizing the editor while the popup is showing keeps the popup anchored to the top right
  corner.
- Notifications issued during startup, before the screen is ready, are shown once the editor is
  drawn instead of being lost or raising errors.
- Headless runs (no screen) produce no popup and no errors.
- A notification arriving while the command line, a completion menu or another popup is open
  does not close or move those, and the notification popup does not take focus.
- When a tabline is shown, the popup appears directly below it, so the tabline stays visible.
- Notifications are still recorded in the editor's message history, so they can be reviewed after
  the popup has closed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every notification issued through the editor's standard notification mechanism
  MUST be displayed in a popup anchored to the top right corner of the editor.
- **FR-002**: The popup MUST show the title "Notifications" on its border.
- **FR-003**: The popup MUST use the same border style and border colour as the editor's other
  popups.
- **FR-004**: The popup MUST hold at most three notifications; when a fourth arrives, the oldest
  MUST be dropped. Entries MUST be shown in arrival order, newest last.
- **FR-005**: Each notification MUST be removed from the popup a configurable delay after it was
  shown, independently of other notifications; the arrival of a new notification MUST NOT extend
  or shorten the lifetime of notifications already shown. When the last remaining notification is
  removed, the popup MUST close.
- **FR-006**: The default delay MUST be three seconds, and the delay MUST be changeable through
  a single, documented configuration value that applies to every notification.
- **FR-007**: The popup MUST NOT take focus, move the cursor, change mode or interrupt typing.
- **FR-008**: Each notification MUST be visually marked by its level (error, warning,
  information/other) using the editor's existing severity colours.
- **FR-009**: Notifications MUST continue to be recorded in the editor's message history.
- **FR-010**: Long notifications MUST wrap within the popup; the popup MUST size itself to its
  contents and stay entirely within the editor's screen.
- **FR-011**: The feature MUST NOT add a plugin, MUST NOT add or change any key mapping, and MUST
  keep startup within the constitution's limit; starting the editor headlessly and quitting MUST
  still produce no errors.

### Key Entities

- **Notification**: a message with its text and level (error, warning, information, or other),
  issued by the editor or a feature of the configuration.
- **Notification popup**: the bordered, titled window in the top right corner holding up to three
  of the most recent, not yet expired notifications; it exists only while it holds at least one.
- **Dismissal delay**: the configurable time, three seconds by default, each notification stays in
  the popup after it was shown.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of attempts, a notification is visible in the top right corner within
  100 ms of being issued, inside a popup titled "Notifications" with the shared border.
- **SC-002**: In a burst of any number of notifications, the popup never shows more than three
  entries, and those are always the three most recent.
- **SC-003**: With the default setting, every notification leaves the popup 3 seconds (±0.5 s)
  after it appeared, regardless of later notifications; with any other configured value, after
  that value (±0.5 s). The popup closes within 0.5 s of its last notification leaving.
- **SC-004**: Typing continues uninterrupted while notifications appear: 0 keystrokes are lost or
  redirected to the popup.
- **SC-005**: Every notification shown in the popup can still be found afterwards in the message
  history.
- **SC-006**: The number of user-defined key mappings is unchanged, startup time on an empty
  buffer stays under 100 ms, and headless start/quit produces 0 messages.

## Assumptions

- "Notifications" are messages issued through the editor's standard notification mechanism (as
  the configuration already does for diagnostics toggling, formatting and similar features).
  Ordinary command-line output, error messages from commands, and prompts that need an answer
  stay on the command line as today.
- The popup is purely informational: it cannot be focused, scrolled or clicked, and no mapping is
  added to dismiss it early or reopen it; the message history serves for reviewing past
  notifications.
- All levels, including errors, use the same dismissal delay.
- A notification dropped early because a fourth one arrived (FR-004) is simply removed; the
  remaining notifications keep their own lifetimes.
- Saving a notification to the message history clears the command line, so a message shown there
  at the same moment (for example `"file" written`) disappears from the screen but stays in
  `:messages`. This is the cost of keeping notifications in the history without a "Press ENTER"
  prompt.
- Notifications explicitly marked as debug/trace level are treated like information.
- A sensible maximum popup width (roughly a third to a half of the editor's width) is used so the
  popup does not cover most of the code; the exact value is a design detail.
- The configurable delay is set by editing the configuration (it is a personal config), not via a
  runtime command; changes take effect after restarting or re-sourcing the module.
- The existing shared popup border style (rounded, title-coloured) from the diagnostic popup
  feature is reused; no new border style or colours are introduced.
- Native editor functionality is sufficient for this feature (Constitution Principle I), so no
  plugin is needed.
