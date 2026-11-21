---

description: "Task list for Notifications via mini.notify"
---

# Tasks: Notifications via mini.notify

**Input**: Design documents from `/specs/009-mini-notify-popup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notifications.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`. Drive the TUI with tmux
(`tmux new-session -d -x 100 -y 20 nvim`, `send-keys`, `capture-pane`) when scripting it.

**Verification note (implementation)**: T004–T009 were run against the real config in a
tmux-driven TUI. T009 found the install failure was silent; a single scheduled WARN line was
added (research R5 outcome). Startup: ~8.2 ms → ~10.4 ms; mappings 68/8/26 (n/i/v) unchanged;
`:checkhealth` errors 0 → 0; lua_ls: no problems.

**Organization**: Tasks are grouped by user story. All code is in one small module, so code
tasks are sequential; README work can run in parallel with code.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US3)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root; modules live in `lua/config/`. Lua follows
`.editorconfig`: 2-space indent, 80 columns, double quotes, trailing table separators, explicit
call parentheses. No new key mapping, no global defined by the config.

---

## Phase 1: Setup

**Purpose**: Confirm the starting point.

- [X] T001 Record baselines: run `nvim --headless "+qa"` (expect no output),
  `nvim --headless --startuptime <scratch>/before.log +qa` (note last line), and
  `nvim --headless "+lua print(#vim.api.nvim_get_keymap('n'))" +qa` (note count) from the repo
  root, for comparison in T011

---

## Phase 2: Foundational

**Purpose**: None — the single module rewrite (US1) is the foundation for the other stories.

---

## Phase 3: User Story 1 - Notifications still appear in a popup (Priority: P1) 🎯 MVP

**Goal**: Every `vim.notify` call is shown by `mini.notify` with its defaults.

**Independent Test**: `<leader>td` shows `Diagnostics: off` top right in the plugin popup;
the cursor stays put; it disappears after ~5 s (quickstart.md §2).

- [X] T002 [US1] Replace the entire contents of `lua/config/notifications.lua` with a short
  module that: (1) has a header comment naming the plugin and the Principle I justification
  (core Neovim has no notification popup; replaces ~300 lines of custom code), (2) calls
  `pcall(vim.pack.add, { "https://github.com/nvim-mini/mini.notify", }, { confirm = false, })`
  (source per `data-model.md` `Plugin spec.src`; no `version` given, per `data-model.md`
  `Plugin spec.version`; research R1, R5), (3) only if that succeeded,
  `pcall`s `require("mini.notify").setup()` with no arguments (research R2), and (4) returns an
  empty module table. No options, autocommands or wrappers (FR-002)
- [X] T003 [US1] Update the comment above `require("config.notifications")` in `init.lua` to say
  it must load before any module that notifies so every notification reaches mini.notify (keep
  the line's position right after `config.options`)
- [X] T004 [US1] Start `nvim` (network on) and verify quickstart.md §2: plugin installs with no
  prompt, `<leader>td` notification appears with no visible delay (SC-001) in a rounded ` Notifications ` popup, no focus
  change, insert-mode typing uninterrupted, gone after ~5 s, ERROR/WARN colours, DEBUG not
  shown; also verify a `vim.notify` issued during startup is displayed once the UI is drawn

**Checkpoint**: Notifications are shown by the plugin; the custom popup code is gone.

---

## Phase 4: User Story 2 - The custom implementation is gone (Priority: P1)

**Goal**: No trace of the custom popup; documentation describes the plugin.

**Independent Test**: quickstart.md §3 and §4.

- [X] T005 [P] [US2] Rewrite the "Notifications" section of `README.md` per
  `contracts/notifications.md`: plugin popup top right, rounded border, title, time prefix,
  ~5 s per notification, DEBUG/TRACE ignored, LSP progress shown, history via
  `:lua MiniNotify.show_history()` (no longer in `:messages`); remove every mention of
  `TIMEOUT_MS`, the three-entry limit and `:messages` splitting
- [X] T006 [US2] Add a "Plugins" note to `README.md` (Requirements section): `git` is
  required for `vim.pack` to install plugins on first start; list `mini.notify`
  (https://github.com/nvim-mini/mini.notify) with its one-line reason; mention that without
  network on first start notifications fall back to the command line
- [X] T007 [US2] Verify quickstart.md §3–§4: `grep -rn "TIMEOUT_MS\|MAX_ENTRIES\|config_notifications\|nvim_open_win" lua init.lua`
  returns nothing; each notification produces exactly one popup; `MiniNotify.show_history()`
  lists earlier notifications

**Checkpoint**: Code and docs reflect only the plugin-based behaviour.

---

## Phase 5: User Story 3 - Plugin installs itself on a fresh machine (Priority: P2)

**Goal**: Zero-step install, and graceful degradation when the plugin is unavailable.

**Independent Test**: quickstart.md §1 and §5.

- [X] T008 [US3] Verify fresh install (quickstart.md §1): with the plugin directory moved
  aside to a scratch location, start `nvim`; it installs without a prompt;
  `:checkhealth vim.pack` lists `mini.notify` without errors. Restore nothing (the new install
  stays) and delete the moved copy
- [X] T009 [US3] Verify fault tolerance (quickstart.md §5): copy the config to an isolated
  `NVIM_APPNAME` (scratch `XDG_CONFIG_HOME`/`XDG_DATA_HOME`/`XDG_STATE_HOME`), change the `src`
  in its `lua/config/notifications.lua` to a non-existent repository URL, and start `nvim` with
  that environment in a real terminal UI; the editor is usable right away with no "Press ENTER"
  prompt and no error stack trace, at most one install-failure notice is shown (Constitution
  IV), and `:lua vim.notify("x")` falls back to the built-in command-line display. If a
  "Press ENTER" prompt appears, fix it in `lua/config/notifications.lua` (see research R5)
  before marking this task done

**Checkpoint**: All user stories verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T010 Run lua_ls diagnostics on `lua/config/notifications.lua` (e.g.
  `lua-language-server --check lua/config/notifications.lua`) and fix any errors/warnings;
  confirm `.editorconfig` style (80 columns, trailing separators)
- [X] T011 Regression checks (quickstart.md §6) against T001 baselines: headless start/quit
  prints nothing, startup < 100 ms, normal-mode keymap count unchanged; `:checkhealth` shows no
  new errors
- [X] T012 Commit in focused Conventional Commits: `feat: show notifications with mini.notify`
  (T002–T003, plugin justification in the body), `docs: document mini.notify notifications`
  (T005–T006), and `docs: add spec, plan and tasks for mini.notify notifications` (this
  feature's `specs/009-mini-notify-popup/`)

---

## Dependencies & Execution Order

- **Setup (T001)** → **US1 (T002–T004)** → **US2 verification (T007)** and **US3 (T008–T009)**
  → **Polish (T010–T012)**.
- T005 and T006 (README) depend only on the design docs and can be done any time, in parallel
  with US1. They touch the same file, so do them one after the other or as one edit.
- US3 depends on US1 (the module must call `vim.pack.add`); US2's T007 depends on T002.

### Parallel Opportunities

```text
# While T002–T004 are in progress:
T005 README Notifications section
T006 README Requirements note (after T005; same file)
```

## Implementation Strategy

1. **MVP**: T001–T004 — notifications go through mini.notify; the user-visible goal is met.
2. **Increment 2**: T005–T007 — docs match the behaviour; no leftovers.
3. **Increment 3**: T008–T009 — fresh-install and failure paths proven.
4. **Finish**: T010–T012 — style, regressions, commits.
