---

description: "Task list for Sticky Visual Indent and Line Moving"
---

# Tasks: Sticky Visual Indent and Line Moving

**Input**: Design documents from `/specs/015-visual-indent-move-lines/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/editing-keys.md,
quickstart.md

**Tests**: The spec does not ask for automated tests. Each story is checked by hand with the
quickstart.md scenarios, optionally sped up with a throwaway headless `nvim_feedkeys` script
as in research.md.

**Organization**: Tasks are grouped by user story. All code goes into
`lua/config/keymaps.lua`, so tasks that edit it are not marked [P] against each other.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Make sure nothing already uses the keys.

- [X] T001 Record a startup-time baseline per quickstart.md "Startup time" (the "before" run). Check that `<`, `>` (visual), `<M-j>`, `<M-k>`, `∆` and `˚` are not mapped anywhere in `lua/config/` or `init.lua` (`grep -rn` for each), and that `lua/config/clue.lua` has no trigger on them (research R4). Stop and report if any clash is found

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared line-moving helper used by US2 and US3 (research R2).

**⚠️ CRITICAL**: US2 and US3 depend on this phase. US1 does not.

- [X] T002 Add `local function move_lines(dir)` (`dir` = 1 down, -1 up) to `lua/config/keymaps.lua`, after the window-key mappings, with a short comment. It reads the range and count per data-model.md "Line range" (`Line range.top`, `Line range.bottom`, `Line range.count`, `Line range.mode`): in visual mode (`vim.fn.mode()` is `v`, `V` or `\22`), take `line("v")`/`line(".")` in order, then leave visual mode with `vim.cmd("normal! \27")`. It computes the target and the edge no-op per data-model.md "Move target". When it moves, it runs `vim.cmd(("silent keepjumps %d,%dmove %d"):format(top, bottom, target))`. In visual mode it finishes with `vim.cmd("normal! gv")`, including the no-op case, so the selection is kept (FR-005, FR-006, FR-007, FR-008). Next to it, add a `local move_keys` table listing `{ lhs, dir }` for `<M-j>`/1, `∆`/1, `<M-k>`/-1, `˚`/-1, with a comment that `∆` / `˚` are what macOS US layout Option+j / Option+k type without "Option as Meta" (research R3). US2 and US3 each loop over this table for their own mode. Keep within 80 columns and the `.editorconfig` style

**Checkpoint**: The helper exists, but nothing calls it yet.

---

## Phase 3: User Story 1 - Indent a selection repeatedly (Priority: P1) 🎯 MVP

**Goal**: Visual `>` / `<` shift by count and keep the selection (FR-001, FR-010).

**Independent Test**: quickstart.md scenarios 1–3 and the regression check for normal-mode
`>>` / `<<` / `>ip`.

- [X] T003 [US1] In `lua/config/keymaps.lua`, add `vim.keymap.set("x", ">", ">gv", { desc = "Indent selection", })` and `vim.keymap.set("x", "<", "<gv", { desc = "Dedent selection", })` with a comment saying the selection is kept so the key can be repeated (contracts/editing-keys.md "Indent", research R1)
- [X] T004 [US1] Verify quickstart.md scenarios 1–3 with `V`, `v` and `<C-v>` selections, and check that normal-mode `>>`, `<<` and `>ip` behave as before

**Checkpoint**: Sticky indent works on its own; it can be shipped before the move keys.

---

## Phase 4: User Story 2 - Move a selection up and down (Priority: P1)

**Goal**: Visual `<M-j>` / `<M-k>` and the fallbacks `∆` / `˚` move the selected lines and
keep them selected (FR-004, FR-005, FR-006, FR-008a).

**Independent Test**: quickstart.md scenarios 4–7 and 11–14.

- [X] T005 [US2] In `lua/config/keymaps.lua`, loop over `move_keys` (T002) and add a visual-mode (`"x"`) mapping for each that calls `move_lines(dir)`, with `desc` `Move selection down` / `Move selection up` per contracts/editing-keys.md
- [X] T006 [US2] Verify quickstart.md scenarios 4–7, 11–14 and 16 (clamping at the buffer edges with no message, charwise and blockwise selections, one undo step per press, `∆` fallback, closed fold with no error)

**Checkpoint**: Moving a selection works.

---

## Phase 5: User Story 3 - Move the current line (Priority: P2)

**Goal**: Normal-mode `<M-j>` / `<M-k>` / `∆` / `˚` move the current line, with the cursor
following it (FR-003, FR-006).

**Independent Test**: quickstart.md scenarios 8–10 and 15.

- [X] T007 [US3] In `lua/config/keymaps.lua`, loop over `move_keys` (T002) and add a normal-mode (`"n"`) mapping for each that calls `move_lines(dir)`, with `desc` `Move line down` / `Move line up` per contracts/editing-keys.md. Do not map any of the keys in insert mode
- [X] T008 [US3] Verify quickstart.md scenarios 8–10 and 15 (count, bottom-of-buffer no-op, `∆` still typed literally in insert mode)

**Checkpoint**: All three stories work.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T009 [P] Add rows to the "Key mappings" table in `README.md`: visual `>` / `<` (indent and keep the selection, count supported), and `<M-j>` / `<M-k>` (move the line or selection down / up, count supported, selection kept, stops at the buffer edge). Mention that `∆` / `˚` also work on macOS when the terminal does not send Option as Meta
- [X] T010 Run `nvim --headless "+qa"` (must print nothing), compare startup time against the baseline per quickstart.md "Startup time" (difference under 1 ms, total under 100 ms; SC-005, Constitution III), check `:verbose xmap >` and `:verbose map <M-j>` show the `desc` values, check that lua_ls reports no diagnostics in `lua/config/keymaps.lua`, and check `:checkhealth` for new errors (Constitution IV, V)
- [X] T011 Update the `**Status**` line in `specs/015-visual-indent-move-lines/spec.md` from `Draft` to `Implemented`

---

## Dependencies & Execution Order

- **Setup (T001)** → everything.
- **Foundational (T002)** → US2 (T005–T006) and US3 (T007–T008).
- **US1 (T003–T004)** depends only on T001 and can be done before or after T002.
- **US2** and **US3** are independent of each other; both only need T002.
- **Polish**: T009 can be done any time after the key list is final; T010 and T011 come last.

```text
T001 ─┬─ T003 → T004                  (US1)
      └─ T002 ─┬─ T005 → T006         (US2)
               └─ T007 → T008         (US3)
T009 [P] (README) any time after T001
T010 → T011 last
```

## Parallel Opportunities

- T009 (`README.md`) can be written alongside any `keymaps.lua` task.
- All other code tasks touch `lua/config/keymaps.lua` and should be done one after another,
  although US2 (T005) and US3 (T007) have no ordering between them.
- Checks inside a verify task (T004, T006, T008) can be run in any order.

## Implementation Strategy

1. **MVP**: T001 → T003 → T004. Sticky indent works and can be committed alone
   (`feat: keep visual selection after indent`).
2. **Increment 2**: T002 → T005 → T006 → T007 → T008. Move lines and selections
   (`feat: move lines with <M-j>/<M-k>`).
3. **Finish**: T009 → T010 → T011 (`docs: document indent and move-line keys`).
