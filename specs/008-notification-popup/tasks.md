---

description: "Task list for Notification Popup"
---

# Tasks: Notification Popup

**Input**: Design documents from `/specs/008-notification-popup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notifications.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md` in a real terminal UI. Use tmux
(`tmux new-session -d … nvim`, `send-keys`, `capture-pane`) as in research.md R2 when driving it
from a script.

**Verification note (implementation)**: every quickstart scenario was run against the real
config in a TUI driven through tmux (`send-keys` / `capture-pane`, with `-e` for colours).
Scenario 11 found that the popup was not redrawn in command-line mode (research.md R9).
Scenario 18 passed without a `CompleteDone` hold.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested
on its own. All code lives in one module, so tasks inside a story are sequential. Only the
README and documentation tasks can run in parallel with code.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US3)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root, and modules live in `lua/config/`. All Lua
follows `.editorconfig`: 2-space indent, 80 columns, double quotes, trailing table separators,
explicit call parentheses. No plugin, no global Lua function, no new key mapping, and no Nerd
Font glyphs.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the module and load it early enough to capture every notification.

- [X] T001 Create `lua/config/notifications.lua`. Start it with a one-line header comment and
  the constants `TIMEOUT_MS`, `MAX_ENTRIES`, `TITLE` and `MAX_WIDTH_RATIO` from data-model.md
  (Constants). Give `TIMEOUT_MS` a comment saying it is the dismissal delay to edit. Add the
  module-local state from data-model.md (Popup state: `entries`, `buf`, `win`, `ns`,
  `pending`), with `ns` from `nvim_create_namespace("config_notifications")`, and the augroup
  `config_notifications` with `clear = true`. End with `return M`.
- [X] T002 In `init.lua`, add `require("config.notifications")` directly after
  `require("config.options")`, with a short comment explaining it must load before modules that
  notify (plan.md Structure Decision).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The `vim.notify` replacement and history writing that every story relies on.

- [X] T003 In `lua/config/notifications.lua`, implement the entry constructor per data-model.md:
  - `Entry.lines`: convert `msg` with `tostring`, split it on `\n`, and drop trailing empty lines.
    Return nil when nothing is left.
  - `Entry.hl`: map `level` per research.md R5.
  - `Entry.timer`: starts as nil.
- [X] T004 In `lua/config/notifications.lua`, implement `history(entry)` per research.md R2.
  For each line of `Entry.lines`, write pieces of at most `math.max(vim.v.echospace, 10)`
  characters (split with `vim.fn.strcharpart`). Write each piece with `nvim_echo({ { piece, hl } },
  true, {})`, where `hl` is `ErrorMsg` for ERROR, `WarningMsg` for WARN and nil otherwise, and
  follow it at once with `nvim_echo({ { "" } }, false, {})`. When `vim.fn.mode()` starts with
  `c`, append the entry to a held list instead and create a once-only `CmdlineLeave` autocommand
  in `config_notifications`. It registers a one-shot `vim.on_key` listener (namespace `ns`) that
  removes itself and flushes the list via `vim.schedule`, so the executed command's output stays
  visible until the next key press (data-model.md Autocommands, research.md R2).
- [X] T005 In `lua/config/notifications.lua`, assign `vim.notify = function(msg, level, opts)`
  per contracts/notifications.md. Build the entry (T003) and return early if it is nil. Then
  `vim.schedule` a function that first calls `history(entry)`. Next:
  - if `vim.v.vim_did_enter == 0`, it appends the entry to `pending`;
  - otherwise, if `#vim.api.nvim_list_uis() > 0`, it calls `add(entry)` through `pcall`, so a
    drawing error never loses the message from `:messages` (research.md R7).

  Add a stub `add` that will be replaced in T008. Annotate `opts` as unused so lua_ls stays
  clean.

**Checkpoint**: `:lua vim.notify("x")` shows nothing on the command line, `:messages` lists
`x`, and a multi-line or very long message produces no "Press ENTER" prompt.

---

## Phase 3: User Story 1 - See notifications in a popup (Priority: P1) 🎯 MVP

**Goal**: Each notification appears in a bordered, titled, level-coloured popup in the top right
corner without taking focus.

**Independent Test**: `<leader>td` shows the ` Notifications ` popup with `Diagnostics: off` in
the top right corner, with the shared border, while the cursor stays in the buffer (quickstart
scenarios 1, 3 colours only, 6, 7, 9, 10, 12).

- [X] T006 [US1] In `lua/config/notifications.lua`, implement `layout()`. It returns the
  `nvim_open_win` config per research.md R4:
  - placement: `relative="editor"`, `anchor="NE"`, `col=vim.o.columns`, and `row` 1 when a
    tabline is visible (`showtabline == 2`, or `== 1` with more than one tab page), else 0
  - size: `width` computed from the entries' `Entry.lines` only (data-model.md Entry.lines),
    never from buffer lines, so separators cannot widen the popup; `height` is the wrapped count
    of those lines at that width plus one per separator. Apply the R4 caps (`MAX_WIDTH_RATIO`,
    title width minimum, available rows).
  - frame: `border` from `vim.o.winborder`, or `"rounded"` when empty, and `title = TITLE`
  - behaviour: `focusable=false`, `style="minimal"`, `zindex=250`, and `noautocmd=true` when
    opening only
- [X] T007 [US1] In `lua/config/notifications.lua`, implement `render()`:
  - Create the scratch buffer on first use (`nvim_create_buf(false, true)`, `bufhidden=hide`).
  - Set its lines from every entry's `Entry.lines` (data-model.md Entry.lines).
  - Clear namespace `ns` and add one extmark per entry with `hl_group = entry.hl` spanning its
    lines (data-model.md Entry.hl).
  - Open the window with `nvim_open_win(buf, false, layout())` when it is not valid, otherwise
    update it with `nvim_win_set_config`, and set the window option `wrap = true`.
  - When the content is taller than the window, set the window's cursor to the last line so the
    newest entry is visible (research.md R4).
  - Close the window and set `win = nil` when `entries` is empty.
- [X] T008 [US1] In `lua/config/notifications.lua`, replace the `add` stub with a version that
  appends the entry to `entries` and calls `render()`. Add the once-only `VimEnter` autocommand
  that moves `pending` into `entries` through `add` if a UI is attached and otherwise just
  clears `pending` (history already has them, research.md R7), and the `VimResized` autocommand
  that
  calls `render()` while `win` is valid (data-model.md Autocommands).
- [X] T009 [US1] Verify quickstart.md scenarios 1, 3 (colours), 6, 7, 9, 10, 12 and 18 in a
  real TUI. Fix any failure in `lua/config/notifications.lua` before moving on. If scenario 18
  shows that the history write closes the completion menu, hold the write until `CompleteDone`,
  as for the command line, and record it in `specs/008-notification-popup/research.md` R2.

**Checkpoint**: Notifications appear in the popup. Entries accumulate until US2 and US3 cap and
expire them.

---

## Phase 4: User Story 2 - Several notifications at once (Priority: P1)

**Goal**: The popup shows at most three entries, newest last, clearly separated.

**Independent Test**: Four notifications in a row leave exactly n2, n3 and n4 visible, separated
by `─` lines (quickstart scenarios 3 and 4).

- [X] T010 [US2] In `lua/config/notifications.lua`, in `add`, before appending: while
  `#entries >= MAX_ENTRIES`, remove the oldest entry and stop and close its `Entry.timer` if
  set (data-model.md Popup state `entries`, Entry.timer).
- [X] T011 [US2] In `lua/config/notifications.lua`, in `render()`, insert a separator line
  between consecutive entries. The line is `string.rep("─", width)`, where `width` is the
  width returned by `layout()` for the current entries, computed before the buffer is filled.
  Highlight it with `FloatBorder` through an extmark in `ns` (research.md R5). Count separator
  lines in the height calculation in `layout()`.
- [X] T012 [US2] Verify quickstart.md scenarios 3 and 4 in a real TUI.

**Checkpoint**: Bursts never show more than three entries.

---

## Phase 5: User Story 3 - Automatic dismissal with a configurable delay (Priority: P2)

**Goal**: Each entry disappears `TIMEOUT_MS` after it was shown, and the popup closes with its
last entry.

**Independent Test**: `a`, then `b` 1.5 s later. `a` leaves at about 3 s and the popup closes at
about 4.5 s. With `TIMEOUT_MS = 5000`, an entry stays about 5 s (quickstart scenarios 2, 5, 13).

- [X] T013 [US3] In `lua/config/notifications.lua`, in `add`, after appending, set
  `entry.timer = vim.defer_fn(function() remove(entry) end, TIMEOUT_MS)` (data-model.md
  Entry.timer). Implement `remove(entry)`: find the entry by identity in `entries`, do nothing
  if it is absent (already dropped), otherwise remove it and call `render()`, which closes the
  window when no entries remain (data-model.md State transitions). Entries released from
  `pending` on `VimEnter` start their timers then (research.md R7).
- [X] T014 [US3] Verify quickstart.md scenarios 2, 5 and 13 (restore `TIMEOUT_MS = 3000`
  afterwards) in a real TUI.

**Checkpoint**: All three stories work together.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T015 [P] In `README.md`, add a "Notifications" section after "Popups". Describe the popup
  (top right, title, shared border, at most three entries, newest last, level colours), say
  that each entry disappears after 3 s and how to change `TIMEOUT_MS` in
  `lua/config/notifications.lua` (restart afterwards), and say that `:messages` keeps the
  history, with long notifications split over several lines. Also say that recording a
  notification clears whatever message is on the command line at that moment; it stays in
  `:messages`.
- [X] T016 Verify quickstart.md scenarios 8 and 11 (history, command-line mode) in a real TUI.
- [X] T017 Run quickstart.md scenarios 14–17: `nvim --headless "+qa"` exits with no output,
  startup is under 100 ms, `:checkhealth` shows no new errors, lua_ls shows no diagnostics in
  `lua/config/notifications.lua` and `init.lua`, and the `:map` count is unchanged.
- [X] T018 Record in `specs/008-notification-popup/research.md` any deviation found during
  implementation, and update `specs/008-notification-popup/plan.md` Implementation Notes to
  match.

---

## Dependencies & Execution Order

- **Setup (T001–T002)** → **Foundational (T003–T005)** → **US1 (T006–T009)** → **US2
  (T010–T012)** → **US3 (T013–T014)** → **Polish (T016–T018)**.
- US2 and US3 both edit `add` / `render` in the same file, so they build on US1 and run one
  after the other. Each can still be verified on its own via its quickstart scenarios.
- T015 (README) depends only on the design and can be done at any time.

## Parallel Opportunities

- T015 [P] can run alongside any code task.
- Everything else touches `lua/config/notifications.lua` and is sequential.

```text
# Example: while T006–T008 are in progress
Task: "T015 [P] Add Notifications section to README.md"
```

## Implementation Strategy

1. **MVP**: Phases 1–3. Notifications are visible in the popup and kept in `:messages`. Stop
   and validate US1.
2. Add US2, which caps and separates entries, and validate it.
3. Add US3, which adds per-entry timers and the configurable delay, and validate it. The feature
   is now complete.
4. Polish: README, the remaining quickstart checks, and the constitution checks. Commit in small
   steps, for example `feat: show notifications in a popup` and `docs: document notifications`.
