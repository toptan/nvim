---

description: "Task list for Diagnostics List in the Location List"
---

# Tasks: Diagnostics List in the Location List

**Input**: Design documents from `/specs/013-lsp-diagnostics-loclist/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md,
contracts/diagnostic-list.md, quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested
on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root. All feature code lives in the new module
`lua/config/diagnostic_list.lua`, so most tasks edit the same file and run in ID order. All Lua
follows `.editorconfig` (2-space indent, 80 columns, double quotes, trailing table separators,
explicit call parentheses). Nothing from `vim.diagnostic` or `vim.lsp` may be touched at module
load time; only inside key callbacks (contracts/diagnostic-list.md "Guarantees").

Verification uses the scratch project from quickstart.md "Prerequisites", created under the
session scratchpad, never inside the repository.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the module and load it

- [X] T001 Create lua/config/diagnostic_list.lua with a header comment (purpose: `<leader>ld`/`<leader>lD` diagnostics in the location list, severity colours, `<Esc>` in location lists), module locals `lists = {}` (list records keyed by location list id) and `ns = vim.api.nvim_create_namespace("config_diagnostic_list")`, and augroup `config_diagnostic_list` with `clear = true` (plan.md "Constitution Check", Principle II)
- [X] T002 [P] Add `require("config.diagnostic_list")` to init.lua directly after `require("config.diagnostics")`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: List building, opening, colouring and `<Esc>`, shared by both keys

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T003 Add `target_win()` to lua/config/diagnostic_list.lua: if `vim.fn.win_gettype() == "loclist"` return `vim.fn.getloclist(0, { filewinid = 0, }).filewinid` (when valid), else the current window (research.md R5)
- [X] T004 Add `build(diagnostics)` to lua/config/diagnostic_list.lua: drop diagnostics for which `vim.diagnostic.is_enabled({ bufnr = d.bufnr, ns_id = d.namespace, })` is false (data-model.md `Diagnostic.namespace`); sort by data-model.md "Sort order" (`Diagnostic.severity`, file display name from `Diagnostic.bufnr`, `Diagnostic.lnum`, `Diagnostic.col`); return quickfix items (`bufnr`, `lnum`/`col`/`end_lnum`/`end_col` +1 per data-model.md `Diagnostic.lnum`/`Diagnostic.col`/`Diagnostic.end_lnum`/`Diagnostic.end_col`, `text`, `type` per data-model.md "Severity mapping") and a list record with `lines` and `hl` (data-model.md `List record.lines`, `List record.hl`) using the display line layout in data-model.md "Display line", where the message is `Diagnostic.message` with newlines replaced by spaces and the label/group come from data-model.md "Severity mapping"
- [X] T005 Add the per-list `quickfixtextfunc` to lua/config/diagnostic_list.lua: for `info.start_idx..info.end_idx` return `lists[info.id].lines[i]`, falling back to an empty string if the record is missing (research.md R3)
- [X] T006 Add `show(win, title, diagnostics, empty_msg)` to lua/config/diagnostic_list.lua: call `build()`; with no items `vim.notify(empty_msg, vim.log.levels.INFO)` and return without touching any list or window (FR-006). Otherwise get the list id **before** any entries are set, because an open list window re-renders (and calls `quickfixtextfunc`) the moment items arrive (research.md R1): if `lists[vim.fn.getloclist(win, { id = 0, }).id]` exists, reuse that id; else create an empty list with `vim.fn.setloclist(win, {}, " ", { title = title, })` and read its id. Store the record under that id, then fill it with `vim.fn.setloclist(win, {}, "r", { id = id, title = title, items = items, quickfixtextfunc = qftf, })` (data-model.md `Location list.title`, `Location list.items`, `Location list.quickfixtextfunc`). Ensure the decoration provider (T007), then `vim.api.nvim_set_current_win(win)` and `vim.cmd.lopen()` so the list opens or is reused and takes focus (FR-005, FR-009)
- [X] T007 Add `ensure_provider()` to lua/config/diagnostic_list.lua, registering once with `vim.api.nvim_set_decoration_provider(ns, ...)`: `on_win` returns true only when `vim.bo[buf].buftype == "quickfix"` and `lists[vim.fn.getloclist(win, { id = 0, }).id]` exists, caching that record in a module local for the window being drawn so `on_line` does no list lookup per row; `on_line` sets two ephemeral extmarks (`ephemeral = true`, `end_col`, `hl_group`, `priority = 200`) over the label and message ranges from data-model.md `List record.hl` (FR-003a, contracts/diagnostic-list.md "Decoration provider")
- [X] T008 Add the `FileType` `qf` autocmd in augroup `config_diagnostic_list` to lua/config/diagnostic_list.lua: when `vim.fn.win_gettype() == "loclist"`, set a buffer-local Normal-mode `<Esc>` (`desc = "Close location list"`) that reads `filewinid`, runs `vim.cmd.lclose()`, and focuses `filewinid` if `vim.api.nvim_win_is_valid()`; leave `<CR>` and quickfix windows untouched (FR-007, FR-008, FR-011, research.md R4)

**Checkpoint**: Foundation ready; the keys can now be added

---

## Phase 3: User Story 1 - List the current buffer's diagnostics (Priority: P1) 🎯 MVP

**Goal**: `<leader>ld` lists the current buffer's diagnostics in the location list, focused,
coloured by severity; `<Esc>` closes it, `<CR>` jumps.

**Independent Test**: quickstart.md scenarios 1–3 and 6–13.

### Implementation for User Story 1

- [X] T009 [US1] Add the Normal-mode keymap `<leader>ld` (`desc = "Buffer diagnostics"`) to lua/config/diagnostic_list.lua: `local win = target_win()`, then `show(win, "Diagnostics", vim.diagnostic.get(vim.api.nvim_win_get_buf(win)), "No diagnostics")` (FR-001, contracts/diagnostic-list.md "Global key mappings")
- [X] T010 [US1] Verify US1 in a real Neovim against the scratch project: quickstart.md scenarios 1–3, 6–13 and 15–17, including the headless `screenattr()` colour check for scenario 10 (label and message cells match the severity's `Diagnostic*` group and differ from the file name cells), the entry-count check (SC-002) and the timing check (SC-001: `<leader>ld` < 0.5 s) from quickstart.md "Headless checks"; fix any failure in lua/config/diagnostic_list.lua before continuing

**Checkpoint**: User Story 1 is fully functional and testable on its own

---

## Phase 4: User Story 2 - List the workspace's diagnostics (Priority: P1)

**Goal**: `<leader>lD` asks capable servers for project-wide diagnostics (≤ 2 s wait), then
lists every diagnostic the editor holds, errors first.

**Independent Test**: quickstart.md scenarios 4 and 5.

### Implementation for User Story 2

- [X] T011 [US2] Add `request_workspace(bufnr)` to lua/config/diagnostic_list.lua: for each client in `vim.lsp.get_clients({ bufnr = bufnr, })` with `client:supports_method("workspace/diagnostic")` call `vim.lsp.buf.workspace_diagnostics({ client_id = client.id, })`; if any were asked, `vim.wait(2000, cond, 50)` where `cond` is true once none of them has a `client.requests` entry with `method == "workspace/diagnostic"` and `type == "pending"`; with none asked, return at once (FR-002, FR-002a, research.md R2)
- [X] T012 [US2] Add the Normal-mode keymap `<leader>lD` (`desc = "Workspace diagnostics"`) to lua/config/diagnostic_list.lua: `local win = target_win()`, `request_workspace(vim.api.nvim_win_get_buf(win))`, re-check `vim.api.nvim_win_is_valid(win)` (fall back to the current window), then `show(win, "Workspace diagnostics", vim.diagnostic.get(), "No workspace diagnostics")`
- [X] T013 [US2] Verify US2: quickstart.md scenarios 4 and 5 (the unopened files' warnings are listed before the hint and `<CR>` opens `b.lua` at line 2), the workspace entry-count check (SC-002: 3 files, 11 diagnostics) and the timing check (SC-001: `<leader>lD` < 2.5 s); confirm with a C file under clangd that `<leader>lD` opens without waiting; fix any failure in lua/config/diagnostic_list.lua

**Checkpoint**: User Stories 1 and 2 both work independently

---

## Phase 5: User Story 3 - Discoverable from the key-clue window (Priority: P3)

**Goal**: `d` and `D` appear under the `<Leader>l` "Language" group with distinct descriptions.

**Independent Test**: quickstart.md scenario 14.

### Implementation for User Story 3

- [X] T014 [US3] Verify US3: quickstart.md scenario 14 shows `d` Buffer diagnostics, `D` Workspace diagnostics and `f` under `<leader>l`; no change to lua/config/clue.lua is expected (the `desc`s from T009 and T012 are enough); fix only if the clue window misses them

**Checkpoint**: All user stories are independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and final checks across all stories

- [X] T015 [P] Update README.md: add `<leader>ld` and `<leader>lD` rows to the key-mappings table, and a "Diagnostics list" section covering the location list, focus, `<Esc>` (location lists only) and `<CR>` (list stays open), severity order and colours, the 2-second project-wide request and the fact that lua_ls reports unopened files by itself while clangd does not (FR-014)
- [X] T016 Check lua/config/diagnostic_list.lua against Constitution Principle V: no lua_ls diagnostics, 80 columns, every mapping has a `desc`, the only autocommand is in `config_diagnostic_list`
- [X] T017 Run quickstart.md "Headless checks": `nvim --headless "+qa"` prints nothing, startup stays under 100 ms (baseline 17.6 ms), `package.loaded["vim.diagnostic"]` is false after startup; run `:checkhealth` and confirm no new errors (FR-013, SC-006)
- [X] T018 Set **Status** to `Implemented` in specs/013-lsp-diagnostics-loclist/spec.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies
- **Foundational (Phase 2)**: after Setup; blocks all stories
- **US1 (Phase 3)**: after Foundational
- **US2 (Phase 4)**: after Foundational; uses `target_win()` and `show()` only, so it is
  independent of US1 (ordering after US1 only avoids edit conflicts in the same file)
- **US3 (Phase 5)**: after US1 and US2 (verifies their `desc`s)
- **Polish (Phase 6)**: after the stories you want to ship

### Within Each User Story

- Tasks edit the same file and run in ID order; each phase ends with its verification task

### Parallel Opportunities

- T002 (init.lua) alongside T001; commit them together
- T015 (README.md) alongside T016–T017

---

## Parallel Example: Polish

```bash
Task: "Update README.md with key rows and Diagnostics list section (T015)"
Task: "Check lua/config/diagnostic_list.lua against Principle V (T016)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 and Phase 2
2. Phase 3 (US1), then **stop and validate** with quickstart.md scenarios 1–3 and 6–13

### Incremental Delivery

1. Commit spec, plan and tasks (`docs: add spec, plan and tasks for diagnostics list`)
2. US1 + US2 + US3 → commit (`feat: list diagnostics in the location list`)
3. Polish → commit (`docs: document diagnostics list`)

---

## Notes

- [P] tasks = different files, no dependencies
- Commits follow Conventional Commits, matching earlier features
- The scratch Lua project must stay outside the repository (it would otherwise join this
  config's lua_ls workspace)
