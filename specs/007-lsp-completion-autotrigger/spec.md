# Feature Specification: Auto-triggered LSP Completion with IDE-style Keys

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Completion (LSP) should be auto triggered. Navigation through it
should be amended so that navigation can be achieved with `Tab` and `Shift+Tab`, accepting with
`Enter`/`Return` and manual triggering with `Control+Space`. Default neovim mappings should
continue to work. Nothing should be preselected, and offered list should be filtered as user
types."

## Clarifications

### Session 2026-11-20

- Q: What should open the menu automatically — only the server's trigger characters, or also
  ordinary identifier characters? → A: Both: the menu opens while typing any word as well as
  after the server's trigger characters (IDE-like), with no minimum word length.
- Q: When moving through the menu with `<Tab>` / `<S-Tab>` (or `<C-n>` / `<C-p>`), should the
  highlighted item's text appear in the buffer right away, or only after accepting it? → A:
  Only after accepting (IDE-style): moving only highlights; `<CR>` / `<C-y>` insert the item;
  `<C-e>`, `<Esc>` or further typing keep just the typed text. This applies to `<C-n>` /
  `<C-p>` / `<Up>` / `<Down>` as well. *(Revised during planning: `<C-n>` / `<C-p>` keep their
  stock preview, because Neovim does not apply mappings to them while the menu is open —
  research R4. `<Tab>`, `<S-Tab>`, `<Up>` and `<Down>` do not preview.)*
- Q: Should the automatic menu list only the server's suggestions, or also words from the open
  buffers? → A: Both, in one menu, with the server's suggestions listed first.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Completion appears on its own while typing (Priority: P1)

As the editor's sole user, when I type code in a buffer that has a language server attached, I
want the completion menu to appear by itself, without pressing `<C-x><C-o>`, and to narrow down
as I keep typing, so that I see relevant symbols without interrupting my typing.

**Why this priority**: Auto-triggering is the core of the request; the new keys (Stories 2 and
3) only make sense once a menu shows up on its own.

**Independent Test**: Open a Lua file in this configuration, enter insert mode, type `vim.` and
then `ap`; confirm the menu appears without any extra key, that nothing is highlighted, and that
after `ap` only items matching `ap` remain. Continue typing a full word and `<Esc>` to confirm
nothing was inserted that was not typed.

**Acceptance Scenarios**:

1. **Given** a language server with completion support is attached, **When** I type an
   identifier character (starting or continuing a word) or one of the server's trigger
   characters (e.g. `.`, `>` of `->`, `:` of `::`), **Then** the completion menu opens without
   any extra key press, provided the server returns suggestions at that position.
2. **Given** the menu opened automatically, **When** it is shown, **Then** no item is
   highlighted and nothing is inserted into the buffer beyond what I typed.
3. **Given** the menu is open, **When** I type further characters, **Then** the list is
   narrowed to items matching what I typed so far (fuzzy matching, as today), and closes when
   nothing matches.
4. **Given** the menu is open, **When** I keep typing and finish the word myself, then type a
   space or punctuation, **Then** the buffer contains exactly what I typed.
5. **Given** a buffer with no language server attached, **When** I type, **Then** no menu opens
   automatically (behaviour as before this feature).
6. **Given** a language server is attached, **When** the menu opens, **Then** it lists the
   server's suggestions first, followed by matching words from the open buffers; when the
   server has no suggestion for the word being typed (e.g. in a comment), the buffer words are
   still offered.

---

### User Story 2 - Choose and accept with Tab, Shift+Tab and Enter (Priority: P2)

As the user, when the completion menu is open I want `<Tab>` to move to the next item,
`<S-Tab>` to the previous one, and `<CR>` to accept the highlighted item, so that completion
works with the keys familiar from other editors.

**Why this priority**: Explicitly requested; it changes the everyday interaction with the menu,
but completion is already usable through the default keys.

**Independent Test**: In a Lua buffer, trigger the menu, press `<Tab>` twice and `<S-Tab>` once
to confirm the highlight moves down, down, up; press `<CR>` and confirm the highlighted item is
inserted and no new line is started. Then, with the menu closed, press `<Tab>` and `<CR>` to
confirm they insert indentation and a new line as usual.

**Acceptance Scenarios**:

1. **Given** the menu is open with nothing highlighted, **When** I press `<Tab>`, **Then** the
   first item is highlighted; further `<Tab>` presses move to the next item.
2. **Given** the menu is open, **When** I press `<S-Tab>`, **Then** the previous item is
   highlighted (from nothing highlighted, the last item).
3. **Given** an item is highlighted, **When** I press `<CR>`, **Then** that item is accepted
   exactly as `<C-y>` would accept it (including extra edits such as an automatic `#include`
   and expansion of argument placeholders), the menu closes, and no line break is inserted.
4. **Given** the menu is open but no item is highlighted, **When** I press `<CR>`, **Then** the
   menu closes and a line break is inserted, as if the menu had not been open.
5. **Given** the menu is not open, **When** I press `<Tab>`, `<S-Tab>` or `<CR>`, **Then** they
   behave as they did before this feature (indentation, jump between snippet placeholders while
   a snippet is active, new line).
6. **Given** I accepted a function whose arguments became placeholders, **When** the menu is
   closed and I press `<Tab>` / `<S-Tab>`, **Then** the cursor moves between the placeholders
   (existing behaviour); **When** the menu is open inside a placeholder, **Then** `<Tab>` /
   `<S-Tab>` move through the menu instead.

---

### User Story 3 - Open completion on demand with Ctrl+Space (Priority: P3)

As the user, I want `<C-Space>` in insert mode to open the language-server completion menu at
the cursor, so that I can request suggestions in places where the menu did not open by itself or
after I closed it.

**Why this priority**: A convenience on top of auto-triggering; the default `<C-x><C-o>` already
provides the same capability.

**Independent Test**: In a Lua buffer, type `vim.ap`, close the menu with `<C-e>`, then press
`<C-Space>` and confirm the menu re-opens, filtered to `ap`, with nothing highlighted.

**Acceptance Scenarios**:

1. **Given** a language server is attached and the menu is closed, **When** I press
   `<C-Space>`, **Then** the completion menu opens for the text before the cursor, with nothing
   highlighted.
2. **Given** no language server is attached, **When** I press `<C-Space>`, **Then** nothing is
   inserted and no error or message is shown.

---

### User Story 4 - Default completion keys keep working (Priority: P2)

As the user, I want the editor's built-in completion keys to keep working alongside the new
ones, so that existing habits and documentation stay valid.

**Why this priority**: Explicitly required; regressions here would break muscle memory.

**Independent Test**: With the menu open, use `<C-n>` / `<C-p>` to move, `<C-y>` to accept,
`<C-e>` to cancel; use `<C-x><C-o>` to open the menu manually; confirm each behaves as in stock
Neovim.

**Acceptance Scenarios**:

1. **Given** the menu is open, **When** I press `<C-n>`, `<C-p>`, `<Down>` or `<Up>`, **Then**
   the highlight moves as in stock Neovim (`<Down>` / `<Up>` without changing the buffer,
   `<C-n>` / `<C-p>` previewing the item in the buffer, as stock).
2. **Given** an item is highlighted, **When** I press `<C-y>`, **Then** it is accepted as before.
3. **Given** the menu is open, **When** I press `<C-e>`, **Then** the menu closes and the typed
   text is kept as before.
4. **Given** a language server is attached, **When** I press `<C-x><C-o>`, **Then** the menu
   opens as before.
5. **Given** the menu is open, **When** I press `<Esc>`, **Then** the menu closes and insert mode
   ends, keeping only the typed text, even if an item was highlighted with `<Tab>`, `<S-Tab>`,
   `<Up>` or `<Down>`; after `<C-n>` / `<C-p>` the previewed item stays, as in stock Neovim
   (`<C-e>` restores the typed text).

---

### Edge Cases

- A language server that does not support completion is attached: no menu opens automatically,
  and `<C-Space>` does nothing (FR-010).
- Several language servers are attached to one buffer: items from all of them are offered in one
  menu (editor default).
- The server is slow or does not answer: typing is never blocked or delayed; matching buffer
  words may be shown first, and the server's suggestions join the menu when (and if) they
  arrive while the cursor is still at the same word.
- The server stops or crashes while I type: no error messages are repeated per keystroke;
  editing continues, and the buffer behaves like one without a server (no automatic menu,
  stock completion) until the server attaches again.
- Results arrive after I already moved on (left insert mode or moved the cursor away): no stale
  menu is shown.
- In many terminals `<C-Space>` reaches the editor as `<C-@>`; the manual trigger MUST work in
  that case too. This replaces the rarely used stock `<C-@>` insert-mode action (insert the
  previously inserted text and stop insert), which is accepted.
- Entering insert mode, opening a new line (even with automatic indentation) or typing a space
  does not open the menu; only a word character or a server trigger character does.
- In a buffer with a server, the stock `<C-n>` / `<C-p>` started with the menu closed also
  include the server's suggestions, since they use the same sources as the automatic menu.
- `<C-Space>` with nothing typed before the cursor (start of a word, right after `.` or `::`)
  offers the server's suggestions only; buffer words are added once a word is started.
- `<Tab>` in normal mode keeps switching buffers (unchanged; only insert-mode keys change).
- Prompt-type buffers and the command line: behaviour is unchanged (no server attaches there).
- Read-only buffers with a server attached (e.g. a library header opened by go-to-definition)
  get the automatic menu like any other buffer with a server; editing them stays governed by
  the editor's usual read-only warning.
- Replaying a macro feeds its keys at once, before an asynchronous server answer can open the
  menu, so a recorded `<Tab>` / `<CR>` that picked a menu item replays as a plain Tab / new
  line. This holds for any asynchronous completion and is accepted; recording and replaying
  must not raise errors.

## Requirements *(mandatory)*

### Functional Requirements

**Automatic triggering and filtering**

- **FR-001**: In every buffer with a language server that supports completion, the completion
  menu MUST open automatically while typing in insert mode, without a manual key, on the inputs
  defined in User Story 1, scenario 1.
- **FR-001a**: The menu MUST combine the server's suggestions with matching words from the
  open buffers, server suggestions first and, within each group, best fuzzy matches first; the
  same combined menu is used whether it opened automatically or with `<C-Space>` (except as
  noted for `<C-Space>` with nothing typed, FR-010).
- **FR-002**: Buffers without such a server MUST NOT get automatic completion; their completion
  behaviour stays as before this feature.
- **FR-003**: When the menu opens (automatically or manually), no item MUST be highlighted.
  Moving the highlight with `<Tab>`, `<S-Tab>`, `<Up>` or `<Down>` MUST NOT change the buffer;
  such a highlighted item's text is inserted only when it is accepted with `<CR>` or `<C-y>`,
  and closing the menu with `<C-e>` or `<Esc>`, or typing further characters, MUST leave only
  the typed text in the buffer. `<C-n>` / `<C-p>` keep their stock preview (FR-011): after
  them `<Esc>` keeps the previewed item and `<C-e>` restores the typed text.
- **FR-004**: While the menu is open, the offered items MUST be narrowed as further characters
  are typed, using the existing fuzzy matching; the menu closes when nothing matches.
- **FR-005**: Automatic completion MUST NOT block or noticeably delay typing, and MUST NOT show
  results for a position the cursor has already left.

**Insert-mode keys**

- **FR-006**: With the menu open, `<Tab>` MUST highlight the next item and `<S-Tab>` the
  previous item, wrapping as the default `<C-n>` / `<C-p>` do.
- **FR-007**: With the menu open and an item highlighted, `<CR>` MUST accept it with the same
  effect as `<C-y>` (including the item's extra edits and snippet expansion) and MUST NOT
  insert a line break.
- **FR-008**: With the menu open and nothing highlighted, `<CR>` MUST close the menu and insert a
  line break.
- **FR-009**: With the menu closed, `<Tab>`, `<S-Tab>` and `<CR>` MUST keep their previous
  insert-mode behaviour, including jumping between snippet placeholders while a snippet is
  active.
- **FR-010**: `<C-Space>` (also received as `<C-@>`) in insert mode MUST open the completion
  menu of FR-001a at the cursor when a word has been started, and the server's suggestions
  alone when nothing is typed before the cursor; in a buffer without a capable server, or with
  the menu already open, it MUST do nothing and show no message.
- **FR-011**: The editor's default completion keys (`<C-n>`, `<C-p>`, `<Up>`, `<Down>`,
  `<C-y>`, `<C-e>`, `<C-x><C-o>`, `<Esc>`) MUST keep their stock behaviour; in buffers with a
  server, `<C-n>` / `<C-p>` started with the menu closed also offer the server's suggestions.
- **FR-012**: The new insert-mode mappings MUST each have a description (Constitution
  Principle V) and MUST NOT change any normal-mode mapping.

**Robustness and documentation**

- **FR-013**: Starting the editor headlessly and quitting MUST produce no errors or messages;
  startup time on an empty buffer MUST NOT noticeably increase (completion setup happens only
  when a server attaches).
- **FR-014**: The README MUST describe the automatic completion, the `<Tab>` / `<S-Tab>` /
  `<CR>` / `<C-Space>` keys, and that the default keys still work; the C/C++ section's
  completion note (currently `<C-x><C-o>` and `<C-n>` / `<C-p>` then `<C-y>`) MUST be updated
  accordingly.
- **FR-015**: This feature supersedes the "no auto-trigger" and "no key mappings" constraints
  on completion recorded for clangd (spec 006, FR-004b and FR-010); all other behaviour from
  that spec, such as automatic `#include` insertion on accept, is preserved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a buffer with an attached server, the menu appears without any key press in
  100% of tries for the trigger inputs of User Story 1, scenario 1.
- **SC-002**: Selecting and accepting the third item of an open menu takes exactly 4 key presses
  (`<Tab>` ×3, `<CR>`), and a typed word followed by `<CR>` with nothing highlighted always
  produces a new line with that word unchanged.
- **SC-003**: Each of the 8 default completion keys listed in FR-011 behaves identically to stock
  Neovim in a side-by-side check, apart from server suggestions being added to `<C-n>` /
  `<C-p>` in buffers with a server.
- **SC-004**: Typing a 30-character line at normal speed in a buffer with an attached server
  never shows a visible pause between a key press and the character appearing.
- **SC-005**: Startup time on an empty buffer stays under 100 ms and headless start/quit
  produces 0 messages (Constitution Principles III and IV).
- **SC-006**: After moving the highlight with `<Tab>` / `<S-Tab>` any number of times and then
  pressing `<Esc>` or `<C-e>`, the buffer differs from the typed text in 0 characters.

## Assumptions

- "Completion (LSP)" limits auto-triggering to buffers with an attached language server. In
  those buffers the automatic menu also includes words from the open buffers (FR-001a); other
  sources (file paths, dictionary, tags) remain manual through the stock keys, and buffers
  without a server get no automatic menu at all.
- The existing completion options (menu for a single match, nothing preselected, details popup,
  fuzzy narrowing) stay as configured; this feature builds on them. The no-preview behaviour of
  FR-003 comes from the new `<Tab>` / `<S-Tab>` keys, not from a completion option.
- No completion plugin is added; the editor's built-in completion and language-server client
  cover the need (Constitution Principle I), as confirmed by the plan's prototype.
- `<CR>` with nothing highlighted inserting a line break (rather than requiring a second
  `<CR>`) matches the common IDE behaviour and the "nothing preselected" requirement.
- `<C-Space>` in a buffer without a server does nothing (it does not offer buffer words there);
  where a server is attached it behaves as FR-010 describes.
- Normal-mode `<Tab>` / `<S-Tab>` buffer switching is unaffected.
