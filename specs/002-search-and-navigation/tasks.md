---

description: "Task list for Search, Yank Feedback and Buffer Navigation"
---

# Tasks: Search, Yank Feedback and Buffer Navigation

**Input**: Design documents from `/specs/002-search-and-navigation/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md,
contracts/keymaps-and-search.md, quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching steps from `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and
testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Neovim config directory at repository root: `init.lua`, `lua/config/*.lua` (see plan.md
"Project Structure"). All Lua follows `.editorconfig` (2-space indent, 80 columns, double
quotes, trailing table separators, explicit call parentheses). Every mapping sets `desc`
(FR-015).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the new modules from plan.md and load them

- [ ] T001 [P] Create `lua/config/search.lua` as a module returning a table `M` with no-op
  `M.clear()` and `M.refresh()`, plus a header comment stating its concern (search position
  label, search-key wrappers, `<Esc>`); see contracts/keymaps-and-search.md
  "`config.search` module API"
- [ ] T002 [P] Create `lua/config/keymaps.lua` with a header comment stating its concern
  (general-purpose key mappings)
- [ ] T003 [P] Create `lua/config/autocmds.lua` with a header comment stating its concern
  (small general autocommands)
- [ ] T004 Add `require("config.search")`, `require("config.keymaps")` and
  `require("config.autocmds")` to `init.lua` after the existing two requires, keeping
  `config.options` first (plan.md "Source Code"; Constitution II)

**Checkpoint**: `nvim --headless "+qa"` exits 0 with no output.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: None needed. The leader keys and load order from feature 001 already cover what
every story depends on, and Phase 1 supplies the module files.

---

## Phase 3: User Story 1 - Search that tells me where I am (Priority: P1) 🎯 MVP

**Goal**: Confirm-only search with smart case. `<Esc>` clears highlights. A single
right-aligned `[current/total]` label follows the current match.

**Independent Test**: quickstart.md §2, §3, §4 and §5 step 1.

### Implementation for User Story 1

- [ ] T005 [US1] Add the search options to `lua/config/options.lua` in a new "Search" block
  after the line-number block, per `data-model.md` Settings.incsearch, Settings.ignorecase,
  Settings.smartcase and Settings.shortmess (FR-001, FR-002; research R1, R7). Use
  `vim.opt.shortmess:append("S")`. Do not set `hlsearch` (Settings.hlsearch stays default,
  FR-003).
- [ ] T006 [US1] In `lua/config/search.lua`, create the namespace `config_search_count` and the
  module-local state per `data-model.md` Search position label.buf and Search position
  label.id. Define highlight group `SearchCountLabel` per `data-model.md` Search position
  label.Highlight group (`default = true`, link `Comment`). Re-apply it from a `ColorScheme`
  autocommand in augroup `config_search_count` (created with `clear = true`, per
  `data-model.md` Augroups) (research R4).
- [ ] T007 [US1] Implement `M.clear()` in `lua/config/search.lua`. If Search position
  label.buf is still valid, delete extmark Search position label.id from it, then reset both
  fields to `nil`. Never raise, even if the buffer was wiped (contract; FR-007).
- [ ] T008 [US1] Implement `M.refresh()` in `lua/config/search.lua`.
  - Call `M.clear()` first, so only one label exists (FR-006).
  - Return early when `vim.v.hlsearch == 0`.
  - Call `vim.fn.searchcount({ recompute = true, maxcount = 999, timeout = 100 })` inside
    `pcall`, since an invalid pattern must not error.
  - Build the label text exactly per `data-model.md` Search position label.Label text
    (FR-005, FR-009; research R3).
  - Place it with `nvim_buf_set_extmark` on the cursor line, col 0,
    `virt_text_pos = "right_align"`, highlight `SearchCountLabel` (FR-008; research R4).
  - Record buf and id.
- [ ] T009 [US1] In `lua/config/search.lua`, map `n`, `N`, `*`, `#`, `g*` and `g#` in normal
  mode as `expr` mappings. Each callback runs `vim.schedule(M.refresh)` and returns the
  original key, so counts, offsets and errors stay native. Each mapping gets the `desc` listed
  for it in contracts/keymaps-and-search.md (research R5; contracts/keymaps-and-search.md; FR-006, FR-015).
- [ ] T010 [US1] In `lua/config/search.lua`, add a `CmdlineLeave` autocommand to augroup
  `config_search_count`, skipped when `vim.v.event.abort` is true (research R5, R6):
  - For cmdtype `/` or `?`, schedule `M.refresh()`.
  - For cmdtype `:`, schedule a check that calls `M.clear()` when `vim.v.hlsearch == 0`
    (covers `:noh`).
- [ ] T011 [US1] In `lua/config/search.lua`, add `TextChanged`, `TextChangedI` and `BufLeave`
  autocommands to augroup `config_search_count`. They call `M.clear()` when `args.buf` equals
  Search position label.buf (`data-model.md` state diagram; FR-007). Do not react to
  `CursorMoved` (clarification Q2).
- [ ] T012 [US1] In `lua/config/search.lua`, map `<Esc>` in normal mode to a function that runs
  `vim.cmd.nohlsearch()` then `M.clear()`, with `desc = "Clear search highlights"`
  (FR-004; research R2). Return `M` at the end of the module.
- [ ] T013 [US1] Run quickstart.md §2, §3, §4 and §5 step 1 and confirm every expected
  result. Then run `nvim --headless "+qa"` and confirm there is no output.

**Checkpoint**: User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Fast switching between open buffers (Priority: P2)

**Goal**: `<Tab>`/`<S-Tab>` cycle file buffers in open order with wrap-around, skipping
special buffers.

**Independent Test**: quickstart.md §6.

### Implementation for User Story 2

- [ ] T014 [P] [US2] In `lua/config/keymaps.lua`, write a local function `cycle(step)`,
  where `step` is `1` or `-1`:
  - Build the candidate set per `data-model.md` Buffer cycle candidates.Candidate set.
  - Choose the target per Buffer cycle candidates.Next target, wrapping around.
  - Do nothing per Buffer cycle candidates.No-op.
  - Switch with `vim.cmd.buffer(n)`.

  (FR-010, FR-011; research R8.)
- [ ] T015 [US2] In `lua/config/keymaps.lua`, map normal-mode `<Tab>` to `cycle(1)`
  (`desc = "Next buffer"`) and `<S-Tab>` to `cycle(-1)` (`desc = "Previous buffer"`). Map
  normal mode only, and do not map `<C-i>`, `<C-o>` or any replacement jump key (FR-012,
  FR-012a; contracts/keymaps-and-search.md).
- [ ] T016 [US2] Run quickstart.md §6 and confirm every expected result.

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Visual feedback and roomy line numbers (Priority: P3)

**Goal**: Yanks flash briefly; the number column fits 5 digits.

**Independent Test**: quickstart.md §5 step 2 and §7.

### Implementation for User Story 3

- [ ] T017 [US3] Add `numberwidth` to the line-number block in `lua/config/options.lua`, per
  `data-model.md` Settings.numberwidth (FR-014; research R10).
- [ ] T018 [P] [US3] In `lua/config/autocmds.lua`, create augroup `config_yank_highlight`
  (`clear = true`) with a `TextYankPost` autocommand calling `vim.hl.on_yank()` with
  defaults, per `data-model.md` Yank highlight.Trigger (FR-013; research R9). Don't use the
  deprecated `vim.highlight`.
- [ ] T019 [US3] Run quickstart.md §5 step 2 and §7 and confirm every expected result.

**Checkpoint**: All user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Constitution compliance across all stories

- [ ] T020 [P] Add a short "Key mappings" section to `README.md` listing `<Esc>`, `<Tab>`,
  `<S-Tab>` and the search-label behaviour, including the `<C-i>` trade-off
  (contracts/keymaps-and-search.md)
- [ ] T021 [P] Check `init.lua`, `lua/config/options.lua`, `lua/config/search.lua`,
  `lua/config/keymaps.lua` and `lua/config/autocmds.lua` against `.editorconfig` formatting
  and for `lua_ls` diagnostics errors (Constitution V)
- [ ] T022 Run the full quickstart.md (§1–§8). Confirm startup stays under 100 ms (SC-006),
  the label appears without perceptible delay on the 50 000-line file (SC-007),
  every mapping shows a description (§8, FR-015), and `:checkhealth` shows no new errors
  (Constitution workflow).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001, T002 and T003 in parallel; T004 after all three.
- **Foundational (Phase 2)**: Empty.
- **User Stories (Phase 3+)**: All depend on Phase 1 only and are independent of each other.
- **Polish (Phase 6)**: After all stories.

### Within Each User Story

- US1: T005 is independent of T006–T012. The `search.lua` tasks run in order T006 → T007 →
  T008 → T009 → T010 → T011 → T012, then T013.
- US2: T014 → T015 → T016.
- US3: T017 and T018 in either order, then T019.

### Shared-file note

T005 and T017 both edit `lua/config/options.lua`, and T006–T012 all edit
`lua/config/search.lua`. These run sequentially. Only work in different files is marked [P].

### Parallel Opportunities

- T001 ∥ T002 ∥ T003 (Setup)
- T014 (keymaps.lua) ∥ T018 (autocmds.lua) ∥ the US1 `search.lua` chain
- T020 ∥ T021 (Polish)

---

## Parallel Example: After Setup

```bash
# Different files, no shared dependency:
Task: "Write cycle(step) in lua/config/keymaps.lua (T014)"
Task: "Add TextYankPost yank highlight in lua/config/autocmds.lua (T018)"
Task: "Create namespace, state and highlight group in lua/config/search.lua (T006)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001–T004).
2. Complete Phase 3 (T005–T013).
3. **Stop and validate** with quickstart.md §2–§4. Search options, `<Esc>` and the label are
   usable on their own.

### Incremental Delivery

1. Setup → US1 → validate → commit (`feat: search options, Esc clear and match counter`).
2. US2 → validate → commit (`feat: cycle buffers with Tab and Shift-Tab`).
3. US3 → validate → commit (`feat: yank highlight and 5-digit number column`).
4. Polish → commit (`docs: document key mappings`).
