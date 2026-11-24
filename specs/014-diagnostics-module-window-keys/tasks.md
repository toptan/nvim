---

description: "Task list for One Diagnostics Module, Aligned List and Window Keys"
---

# Tasks: One Diagnostics Module, Aligned List and Window Keys

**Input**: Design documents from `/specs/014-diagnostics-module-window-keys/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md,
contracts/diagnostics-and-window-keys.md, quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task
that runs the matching section of `quickstart.md`.

**Organization**: Tasks are grouped by user story. The module merge (the work for US3) is
done first, in the Foundational phase, because US1 edits the merged file. The US3 phase
holds only its verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

## Path Conventions

The repository root is the Neovim config directory. All Lua follows `.editorconfig`
(2-space indent, 80 columns, double quotes, trailing table separators, explicit call
parentheses). Nothing may touch `vim.diagnostic` or `vim.lsp` at module load time. Scratch
files for verification go in the session scratchpad, never in the repository.

---

## Phase 1: Setup

**Purpose**: Make sure the editor starts cleanly before anything changes

- [X] T001 Confirm `init.lua` loads only modules (no stray code) and `nvim --headless "+qa"` exits with no output, and record the baseline from `nvim --startuptime /dev/stdout --headless +qa | tail -1`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: One diagnostics module (research R1, contract "Module
`lua/config/diagnostics.lua`"). US1 cannot start until this is done.

- [X] T002 In `lua/config/diagnostics.lua`, create one augroup at the top (`local group = vim.api.nvim_create_augroup("config_diagnostics", { clear = true, })`), use it for the existing `DiagnosticChanged` autocmd, and update the header comment to cover display, toggles and the diagnostics list
- [X] T003 Move all code from `lua/config/diagnostic_list.lua` into `lua/config/diagnostics.lua`, between the `<leader>tl` mapping and `return M`. Bring the `lists` table, the namespace (renamed `config_diagnostics`), `severities`, `target_win`, `file_name`, `build`, `qftf`, the decoration provider, `show`, `request_workspace`, the `<leader>ld`/`<leader>lD` mappings and the `FileType qf` `<Esc>` autocmd, which must use the shared `group` from T002. Drop the old file's own augroup and namespace names. Behaviour must stay unchanged
- [X] T004 Delete `lua/config/diagnostic_list.lua` and remove `require("config.diagnostic_list")` from `init.lua`
- [X] T005 Run `nvim --headless "+qa"` (no output) and `nvim --headless "+lua print(package.loaded['vim.diagnostic'] == nil)" +qa` (prints `true`), and check that lua_ls reports no diagnostics in `lua/config/diagnostics.lua`

**Checkpoint**: The merged module behaves exactly like the two old modules.

---

## Phase 3: User Story 1 - Read the diagnostics list as a table (Priority: P1) 🎯 MVP

**Goal**: Severity labels share one column and messages share one column (FR-004–FR-006).

**Independent Test**: quickstart.md section 2.

- [X] T006 [US1] Rewrite `build()` in `lua/config/diagnostics.lua` as two passes over the sorted entries. Pass 1 formats each location per data-model.md "Display line layout" (`loc`) and tracks the list's maximum `vim.fn.strdisplaywidth(loc)` (`W`, research R3). Pass 2 builds each line as `loc .. pad_loc .. " " .. label .. pad_label .. "| " .. message`, using `pad_loc` and `pad_label` from data-model.md. Use a named constant `LABEL_WIDTH = 7` for the width of `"warning"`
- [X] T007 [US1] In the same `build()` in `lua/config/diagnostics.lua`, compute the list record's `label` and `msg` byte ranges per data-model.md "Highlight ranges", so that padding is never coloured (FR-006). Quickfix items (`items[i]`) stay unchanged
- [X] T008 [US1] Verify with quickstart.md section 2 (steps 1–6) using a scratch project with all four severities, line numbers from 1 to 4 digits, and two file names of different lengths, one of them non-ASCII

**Checkpoint**: The aligned list works; US1 is shippable.

---

## Phase 4: User Story 2 - Move between windows with one key (Priority: P1)

**Goal**: `<C-h/j/k/l>` in Normal mode do what `<C-w>h/j/k/l` do (FR-007–FR-010).

**Independent Test**: quickstart.md section 3.

- [X] T009 [P] [US2] Add four Normal-mode mappings to `lua/config/keymaps.lua`: `<C-h>`→`<C-w>h`, `<C-j>`→`<C-w>j`, `<C-k>`→`<C-w>k`, `<C-l>`→`<C-w>l`, as string right-hand sides with the `desc` values from contracts/diagnostics-and-window-keys.md (research R4). Add a comment saying that `<C-l>` no longer redraws (use `:redraw!`) and that other modes are untouched
- [X] T010 [US2] Verify with quickstart.md section 3 (steps 1–6), including the quickfix and help windows (FR-008)

**Checkpoint**: Window keys work. They don't depend on US1 or the merge.

---

## Phase 5: User Story 3 - Diagnostics configured in one place (Priority: P2)

**Goal**: A single diagnostics module with no leftover references (FR-001–FR-003).
The implementation is in Phase 2.

**Independent Test**: quickstart.md section 1.

- [X] T011 [US3] Verify with quickstart.md section 1: the file is gone, `grep -rn diagnostic_list init.lua lua README.md` finds nothing, a headless start is clean, startup is < 100 ms, and the acceptance scenarios of specs 004 and 013 still pass

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T012 [P] Update `README.md` (FR-013). Add rows for `<C-h>`/`<C-j>`/`<C-k>`/`<C-l>` to the key table, with a note that `<C-l>` no longer redraws (`:redraw!` instead). In "Diagnostics list", describe the aligned columns, add a short fenced example of two aligned entries (an `error` and a `warning` with different location widths, per data-model.md "Display line layout"), and change "`<C-w>j` goes back to it" to "`<C-j>` goes back to it"
- [X] T013 Final check: lua_ls is clean in `lua/config/diagnostics.lua` and `lua/config/keymaps.lua`, `:checkhealth` shows no new errors, `nvim --headless "+qa"` is clean, and startup is under 100 ms and close to the T001 baseline

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002–T005)** → **US1 (T006–T008)**
- **US2 (T009–T010)** depends only on Setup; it touches `lua/config/keymaps.lua` and can run
  in parallel with Foundational and US1
- **US3 (T011)** depends on Foundational and, for a full re-run of spec 013's scenarios, on
  US1
- **Polish**: T012 can start once US1 and US2 have settled the behaviour; T013 comes last
- Within US1, T006 → T007 → T008 (same function)

## Parallel Example

```text
# Once T001 is done, two independent lines of work:
Line A: T002 → T003 → T004 → T005 → T006 → T007 → T008   (lua/config/diagnostics.lua, init.lua)
Line B: T009 → T010                                       (lua/config/keymaps.lua)
# Then T011, T012 [P], T013
```

## Implementation Strategy

- **MVP**: Setup + Foundational + US1. This gives the merged module and the aligned list.
- **Increment 2**: US2 window keys (can land first; it is independent).
- **Close out**: US3 verification, README, final checks.
- **Commits** (Constitution workflow): `refactor: merge diagnostics list into diagnostics
  module` (T002–T005), `feat: align diagnostics list columns` (T006–T007),
  `feat: move between windows with <C-h/j/k/l>` (T009), `docs: document window keys and
  aligned diagnostics list` (T012).
