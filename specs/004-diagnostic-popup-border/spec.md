# Feature Specification: Prominent Diagnostic Popup

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Diagnostic popup should be more prominent and visible. It should
have border."

## Clarifications

### Session 2026-11-20

- Q: Should the border apply only to the diagnostic popup, or to every popup in the editor? →
  A: Every popup — diagnostics, hover, signature help and other plugin popups share one
  border style.
- Q: Besides the border, should the diagnostic popup also get a title, the reporting tool's
  name and severity colours? → A: Yes, all three (Story 2 stays in scope).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bordered popups (Priority: P1)

As the editor's sole user, when I open the diagnostic popup — or any other popup, such as hover
documentation — I want it framed by a clearly visible border, so that I can tell at a glance
where the popup ends and the code behind it begins, and read it without hunting for it.

**Why this priority**: This is exactly what was asked for. Today the popup has no frame and
blends into the surrounding code, especially when it overlaps code with a similar background.

**Independent Test**: Open a Lua file with a deliberate problem (e.g. an unused local), place
the cursor on it, open the diagnostic popup with the editor's built-in key (Ctrl-w d), and
check that a border surrounds the whole popup. Then open hover documentation (K) and signature
help on a function call, and check they show the same border; a popup opened explicitly
without a border stays borderless.

**Acceptance Scenarios**:

1. **Given** the cursor is on a line with a diagnostic, **When** I open the diagnostic popup,
   **Then** the popup is surrounded on all four sides by a continuous border.
2. **Given** the popup is open over code, **When** I look at it, **Then** the border makes its
   edges clearly distinguishable from the code underneath, in both dark and light background
   settings.
3. **Given** a diagnostic message longer than the popup's width or spanning several lines,
   **When** the popup opens, **Then** the border encloses all of the message's text and no text
   is drawn on or outside the border.
4. **Given** the popup is open, **When** I move the cursor or press Escape, **Then** the popup
   and its border close together, leaving no stray border characters on screen.
5. **Given** the cursor is on a function name, **When** I open hover documentation or signature
   help, **Then** that popup has the same border as the diagnostic popup.
6. **Given** a plugin opens a popup and explicitly asks for no border (or its own border),
   **When** the popup appears, **Then** that choice is kept.

---

### User Story 2 - Easier-to-read popup contents (Priority: P2)

As the user, I want the popup to make each diagnostic's severity and origin obvious, so that I
can immediately tell an error from a hint and know which tool reported it.

**Why this priority**: Improves "prominent and visible" beyond the frame, but the border alone
(Story 1) already resolves the main complaint.

**Independent Test**: Create a line with two diagnostics of different severity (or from two
sources) and open the popup.

**Acceptance Scenarios**:

1. **Given** the popup is open, **When** I look at it, **Then** a title on the border identifies
   it as a diagnostics popup.
2. **Given** a diagnostic with a known source (e.g. the Lua language server), **When** the popup
   opens, **Then** each entry names the source that reported it.
3. **Given** the line has diagnostics of several severities, **When** the popup opens, **Then**
   each entry is coloured according to its severity, matching the colours used for that
   severity elsewhere in the editor.

---

### Edge Cases

- Popup near a screen edge: the border MUST remain fully visible; the popup is repositioned or
  shrunk rather than having part of its border cut off.
- Very narrow editor window: the popup MUST still open without errors, even if the message wraps
  heavily.
- Diagnostics turned off (Leader+td): asking for the popup explicitly still shows the cursor
  line's diagnostics, in the same bordered style; this is the editor's built-in behaviour and is
  kept. A line with no diagnostics opens no popup and no empty bordered frame.
- Diagnostics from a source that reports no name: the entry is shown without a source label and
  no placeholder text (such as "nil") appears.
- The border MUST use plain Unicode or ASCII characters, since the configuration does not assume
  a Nerd Font.
- A popup from a plugin that sets its own border keeps it; a plugin popup that sets none gets the
  shared border.
- Opening the popup must not change virtual text, virtual lines or the on/off state managed by
  the existing diagnostic toggles.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The diagnostic popup MUST be drawn with a border on all four sides.
- **FR-002**: The border MUST use characters that render correctly without a Nerd Font.
- **FR-003**: The border MUST be visually distinct from both the popup's contents and the code
  behind it under the configured colour scheme.
- **FR-004**: The popup MUST show a title on its border identifying it as diagnostics.
- **FR-005**: Each popup entry MUST show the name of the source that reported it, when the source
  is known.
- **FR-006**: Each popup entry MUST be highlighted with its severity's colour.
- **FR-007**: The style MUST apply to the diagnostic popup however it is opened (the editor's
  built-in key, or any command that opens it), without passing options each time.
- **FR-008**: The style MUST be in effect from the first time the popup is opened in a session,
  for diagnostics from any source.
- **FR-009**: The configuration MUST NOT add, remove or change any key mapping for this feature.
- **FR-010**: Every other floating popup (hover documentation, signature help, and popups from
  plugins that do not set their own border) MUST use the same border style as the diagnostic
  popup. The built-in completion menu is not a floating popup and is unchanged.
- **FR-011**: The change MUST NOT add a plugin, MUST NOT load the diagnostic subsystem at
  startup, and MUST keep startup within the constitution's limit; starting the editor
  headlessly and quitting MUST still produce no errors.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of attempts, opening the diagnostic popup shows a complete border on all
  four sides, including near every screen edge.
- **SC-002**: In both dark and light background settings, the border colour differs clearly from
  the popup's background and from the editor's background (it is not a near-background shade),
  so the popup's edges are visible at a glance when it overlaps code.
- **SC-003**: Every entry from a named source shows that name, and every entry's colour matches
  its severity in 100% of checked cases.
- **SC-004**: The number of user-defined key mappings is unchanged, startup time on an empty
  buffer stays under 100 ms, and headless start/quit produces 0 messages.
- **SC-005**: Hover and signature-help popups show the same complete border as the diagnostic
  popup in 100% of attempts.

## Assumptions

- "Diagnostic popup" means the floating window that lists the diagnostics for the cursor's line,
  opened with the editor's built-in Ctrl-w d mapping; no new mapping is introduced to open it.
- Popups whose plugin explicitly chooses its own border (or no border) keep that choice; the
  shared style is the default, not an override.
- The title, source names and severity colours (Story 2) are specific to the diagnostic popup;
  other popups only gain the border.
- A rounded border is used as the default style; any continuous border satisfying FR-001–FR-003
  is acceptable.
- Automatically opening the popup when the cursor rests on, or jumps to, a diagnostic is out of
  scope; the popup opens only on request, as today.
- The existing colour scheme's severity colours are used. Its own popup-border colour is too
  close to the background to meet FR-003, so the border instead takes the scheme's popup-title
  colour; no new colour scheme or hard-coded palette is introduced.
- The style follows the existing deferred diagnostic setup, so it is applied without loading the
  diagnostic subsystem at startup (Constitution Principle III).
