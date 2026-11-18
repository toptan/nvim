---

description: "Task list for Basic Editor Options"
---

# Tasks: Basic Editor Options

**Input**: Design documents from `/specs/001-basic-editor-options/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/editor-settings.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching headless checks from `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and
testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Neovim config directory at repository root: `init.lua`, `lua/config/*.lua` (see plan.md
"Project Structure"). All Lua follows `.editorconfig` (2-space indent, 80 columns, double
quotes, trailing table separators, explicit call parentheses).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the module layout from plan.md

- [X] T001 [P] Create `lua/config/options.lua` as an empty module (a header comment stating
  its concern: leader keys, provider flags, Nerd Font flag, editor options)
- [X] T002 [P] Create `lua/config/colorscheme.lua` as an empty module (a header comment
  stating its concern: colour scheme and transparency)
- [X] T003 Create `init.lua` that only does `require("config.options")` then
  `require("config.colorscheme")`, in that order (contracts/editor-settings.md "Load order";
  Constitution II: thin entry point)

**Checkpoint**: `nvim --headless "+qa"` exits 0 with no output.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Settings every later module depends on and that must run first

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Set the leader keys as the very first statements of `lua/config/options.lua`, per
  `data-model.md` Global variable.mapleader and Global variable.maplocalleader (FR-005;
  research R5). Nothing may precede them in this file.

**Checkpoint**: Leader keys are in place before any other module loads.

---

## Phase 3: User Story 1 - Predictable editing behaviour (Priority: P1) 🎯 MVP

**Goal**: Indentation defaults, hybrid line numbers and scroll context behave the same in every
session.

**Independent Test**: quickstart.md steps 1, 2 (indentation/number/scrolloff/leader rows) and 5
— new buffers indent with 4 spaces, the repo's Lua uses 2 via `.editorconfig`, Makefiles use
tabs, numbers are hybrid, scrolloff is 8, leader is Space.

### Implementation for User Story 1

- [X] T005 [US1] Add indentation defaults to `lua/config/options.lua` as global options only,
  per `data-model.md` Global option.expandtab, Global option.tabstop, Global
  option.shiftwidth and Global option.softtabstop (FR-001, FR-002). Do not touch
  `vim.g.editorconfig` or any `*_recommended_style` global, and do not add `FileType`
  autocommands — buffer-local overrides must win (FR-002a; research R3).
- [X] T006 [US1] Add line numbering and scroll context to `lua/config/options.lua`, per
  `data-model.md` Global option.number, Global option.relativenumber and Global
  option.scrolloff (FR-003, FR-004).
- [X] T007 [US1] Run quickstart.md steps 1, 2 and 5 and confirm the US1 values and the
  per-file indentation table match exactly.

**Checkpoint**: User Story 1 is fully functional and testable independently.

---

## Phase 4: User Story 2 - Clean, readable appearance (Priority: P2)

**Goal**: Built-in `catppuccin` following the terminal's light/dark mode, transparent
background that survives reloads, cursor line, column-81 marker, permanent sign column and
Unicode whitespace symbols.

**Independent Test**: quickstart.md steps 2 (appearance rows and `colors_name`), 4 and 7.

### Implementation for User Story 2

- [X] T008 [US2] Add visual options to `lua/config/options.lua`, per `data-model.md`
  Global option.cursorline, Global option.colorcolumn, Global option.signcolumn, Global
  option.list and Global option.listchars (FR-008–FR-011; research R6, R8). Do not set
  `background` or `termguicolors` (research R1, R9).
- [X] T009 [P] [US2] In `lua/config/colorscheme.lua`, create augroup `config_transparency`
  with `clear = true` and a `ColorScheme` autocommand that clears only the background of every
  group in `data-model.md` Colour scheme state.Transparent groups, preserving each group's
  other attributes (FR-007; research R2; contracts/editor-settings.md "Colour scheme"). Do not
  touch `NormalFloat`/`FloatBorder`, `CursorLine` or `ColorColumn`.
- [X] T010 [US2] In `lua/config/colorscheme.lua`, after the autocommand from T009, load the
  scheme with `pcall` so a missing scheme leaves the default in place without an error, per
  `data-model.md` Colour scheme state.`vim.g.colors_name` (FR-006; Constitution IV). Never set
  `background` here, so the scheme's own light/dark switch selects the palette per
  `data-model.md` Colour scheme state.Palette (research R1).
- [X] T011 [US2] Run quickstart.md steps 2 and 4; confirm `colors_name` is `catppuccin` and every
  background value printed is `nil` at start, after the background switch and after a reload.
  Then do the visual check in step 7 in a real terminal, in both light and dark mode.

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Lean, dependency-free startup (Priority: P3)

**Goal**: Providers are disabled and the configuration records that no Nerd Font is available.

**Independent Test**: quickstart.md steps 2 (provider and `have_nerd_font` rows) and 3.

### Implementation for User Story 3

- [X] T012 [US3] Disable all four providers in `lua/config/options.lua`, directly after the
  leader keys and before any option, per `data-model.md` Global
  variable.loaded_python3_provider, Global variable.loaded_node_provider, Global
  variable.loaded_ruby_provider and Global variable.loaded_perl_provider (FR-013; research R4).
- [X] T013 [US3] Record the Nerd Font flag in `lua/config/options.lua` next to the provider
  flags, per `data-model.md` Global variable.have_nerd_font (FR-012; research R7).
- [X] T014 [US3] Run quickstart.md steps 2 and 3; confirm all four providers are reported as
  disabled and no ERROR/WARNING lines appear.

**Checkpoint**: All user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Constitution compliance across all stories

- [X] T015 [P] Document the Neovim 0.12+ requirement (needed for the built-in `catppuccin`
  scheme) in `README.md` (Constitution IV: dependencies documented in the README)
- [X] T016 Check `init.lua`, `lua/config/options.lua` and `lua/config/colorscheme.lua` against
  `.editorconfig` formatting and for `lua_ls` diagnostics errors (Constitution V)
- [X] T017 Run the full quickstart.md (steps 1–7) (step 7 visual check is tracked in T011) including startup time < 100 ms (SC-004) and
  confirm `:checkhealth` shows no new errors (Constitution workflow)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: T001 and T002 in parallel; T003 after both.
- **Foundational (Phase 2)**: T004 after Setup — BLOCKS all user stories (leader must be first in
  `lua/config/options.lua`).
- **User Stories (Phase 3+)**: All depend on Phase 2.
- **Polish (Phase 6)**: After all stories.

### User Story Dependencies

- **US1 (P1)**: Depends only on Phase 2.
- **US2 (P2)**: Depends only on Phase 2. Its `lua/config/colorscheme.lua` work (T009, T010) is
  independent of US1.
- **US3 (P3)**: Depends only on Phase 2. T012/T013 go in the flags block right after the leader
  keys, so they do not conflict with US1/US2 option blocks.

### Within Each User Story

- Implementation before its verification task.
- T009 before T010 (the autocommand must exist before the first scheme load).

### Shared-file note

T005, T006, T008, T012 and T013 all edit `lua/config/options.lua`; when they are done by one
agent they run sequentially. Only work in different files is marked [P].

### Parallel Opportunities

- T001 ∥ T002 (Setup)
- T008 ∥ T009 (options.lua vs colorscheme.lua; T008 is not marked [P] because it shares
  options.lua with T005, T006, T012 and T013)
- T015 ∥ T016 (Polish)

---

## Parallel Example: User Story 2

```bash
# Different files, no shared dependency:
Task: "Add visual options to lua/config/options.lua (T008)"
Task: "Create config_transparency ColorScheme autocommand in lua/config/colorscheme.lua (T009)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001–T003)
2. Phase 2: Foundational (T004)
3. Phase 3: User Story 1 (T005–T007)
4. **STOP and VALIDATE** with quickstart.md steps 1, 2, 5

### Incremental Delivery

1. Setup + Foundational → editor starts cleanly with Space as leader
2. + US1 → usable daily-driver editing behaviour (MVP)
3. + US2 → final look (theme, transparency, markers)
4. + US3 → lean startup with no provider warnings
5. Polish → README, style check, full validation

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Commit after each phase or logical group, using Conventional Commits (Constitution workflow)
- No plugins, keymaps or LSP settings are in scope for this feature
