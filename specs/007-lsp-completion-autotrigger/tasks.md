---

description: "Task list for Auto-triggered LSP Completion with IDE-style Keys"
---

# Tasks: Auto-triggered LSP Completion with IDE-style Keys

**Input**: Design documents from `/specs/007-lsp-completion-autotrigger/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md,
contracts/keymaps-and-completion.md, quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`, in a real terminal UI and, where useful, with
an RPC-driven headless Neovim as in research.md.

**Verification note (implementation)**: all scenarios were run against the real config in a
headless Neovim driven over RPC (`--listen` / `--remote-send`), not in an interactive
terminal. Scenario 18 (a terminal sending `<C-@>` for Ctrl+Space) was checked through the
`<C-@>` mapping itself; an interactive terminal check remains for the user.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested
on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root. Modules live in `lua/config/`. All Lua
follows `.editorconfig` (2-space indent, 80 columns, double quotes, trailing table separators,
explicit call parentheses). No plugin, no global Lua function, every mapping has a `desc`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the environment matches research.md

- [X] T001 Check `nvim --version` reports 0.12.x, that `lua-language-server` and `clangd` are on `PATH`, and create the scratch files from the Prerequisites in specs/007-lsp-completion-autotrigger/quickstart.md

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The module every story extends, loaded at startup

- [X] T002 Create lua/config/completion.lua with a header comment (purpose: automatic LSP + buffer-word completion and IDE-style insert-mode keys; native only, research R1), `local M = {}`, the augroup `vim.api.nvim_create_augroup("config_completion", { clear = true, })` and `return M`; no global state (plan Implementation Notes 1, research R8)
- [X] T003 Add `require("config.completion")` after `require("config.lsp")` in init.lua

**Checkpoint**: `nvim --headless "+qa"` prints nothing; behaviour is unchanged.

---

## Phase 3: User Story 1 - Completion appears on its own while typing (Priority: P1) 🎯 MVP

**Goal**: In buffers with a completion-capable server the menu opens while typing a word or
after a trigger character, lists server items first then buffer words, nothing preselected,
narrowing as you type; other buffers are unchanged.

**Independent Test**: quickstart.md scenarios 1, 2, 3, 6, 16 (automatic part) and 21–23, plus typing
`in` / `std::str` in `m.cpp`: menu appears without a key press, nothing highlighted, list
narrows, no menu on a new line or in a buffer without a server.

- [X] T004 [US1] Implement the comparator in lua/config/completion.lua per data-model.md Comparator `compare(a, b)` (server item first, then fuzzy score with the per-word cache keyed on the word before the cursor, then `sortText`, then `word`; strict weak order) (research R2)
- [X] T005 [US1] Implement `M.source(findstart, base)` in lua/config/completion.lua per data-model.md Source function `source(findstart, base)`: on `findstart = 1` return `-3` unless the character before the cursor matches `\k` or the text before the cursor ends with a `completionProvider.triggerCharacters` entry of an attached client (`vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion", })`); otherwise delegate to `vim.lsp.omnifunc(findstart, base)` (research R3)
- [X] T006 [US1] Add the `LspAttach` autocommand (group `config_completion`) in lua/config/completion.lua: skip clients where `client:supports_method("textDocument/completion", buf)` is false; call `vim.lsp.completion.enable(true, client.id, buf, { cmp = compare, })` (data-model.md Per-client completion registration); set data-model.md Buffer-local options `'autocomplete'` = true, `'complete'` = `F,.,w,b,u` and `'completefunc'` = `v:lua.require'config.completion'.source` (research R1, R2)
- [X] T007 [US1] Add the `LspDetach` autocommand (group `config_completion`) in lua/config/completion.lua: when no other client of the buffer supports `textDocument/completion` (exclude the detaching `client_id`), reset data-model.md Buffer-local options `'autocomplete'`, `'complete'` and `'completefunc'` to their global values (research R8)
- [X] T008 [US1] Verify US1: quickstart.md scenarios 1, 2, 3, 6, 16 (no menu part), 21, 22 and 23 in a terminal UI; in `m.cpp` type `in` and `std::str` at normal speed and confirm the menu with clangd items; then re-check research R7 by typing `std::` slowly and record whether the spec's `std:` edge case still applies (plan Implementation Notes 4)

**Checkpoint**: Automatic completion works; keys are still stock (`<C-y>` to accept).

---

## Phase 4: User Story 2 - Choose and accept with Tab, Shift+Tab and Enter (Priority: P2)

**Goal**: `<Tab>` / `<S-Tab>` move through the open menu without inserting, `<CR>` accepts a
highlighted item or inserts a line break; with the menu closed the keys behave as before,
including snippet jumps.

**Independent Test**: quickstart.md scenarios 4, 5, 7, 8, 9, 13, 14 and 15.

- [X] T009 [US2] Add the insert-mode `<Tab>` and `<S-Tab>` expression mappings in lua/config/completion.lua per contracts/keymaps-and-completion.md (menu visible → `<Down>` / `<Up>`; else `vim.snippet.active({ direction = d, })` → `<Cmd>lua vim.snippet.jump(d)<CR>`; else the key), with the contract's `desc` values; insert mode only, select mode keeps Neovim's defaults (research R4)
- [X] T010 [US2] Add the insert-mode `<CR>` expression mapping in lua/config/completion.lua per contracts/keymaps-and-completion.md (menu visible and `vim.fn.complete_info({ "selected", }).selected ~= -1` → `<C-y>`; menu visible, nothing selected → `<C-e><CR>`; else `<CR>`), with the contract's `desc` (research R5)
- [X] T011 [US2] Verify US2: quickstart.md scenarios 4, 5, 7, 8, 9, 13, 14 and 15; confirm one `u` after scenario 13 removes both the word and the `#include`

**Checkpoint**: US1 + US2 give the requested IDE-style workflow.

---

## Phase 5: User Story 4 - Default completion keys keep working (Priority: P2)

**Goal**: Stock completion keys behave as in stock Neovim (with server items added to
`<C-n>` / `<C-p>` in buffers with a server).

**Independent Test**: quickstart.md scenarios 12, 17, 20 and 24.

- [X] T012 [US4] Verify US4: quickstart.md scenarios 12, 17, 20 and 24, and in a buffer without a server confirm `<C-n>`, `<C-p>`, `<C-y>`, `<C-e>`, `<C-x><C-o>` behave exactly as with `nvim --clean`; fix lua/config/completion.lua if any key deviates beyond what contracts/keymaps-and-completion.md allows

---

## Phase 6: User Story 3 - Open completion on demand with Ctrl+Space (Priority: P3)

**Goal**: `<C-Space>` (and `<C-@>` from terminals) opens the menu by hand; nothing happens
without a completion-capable server or when the menu is already open.

**Independent Test**: quickstart.md scenarios 10, 11, 16 and 18.

- [X] T013 [US3] Add one expression function mapped to insert-mode `<C-Space>` and `<C-@>` in lua/config/completion.lua per contracts/keymaps-and-completion.md and research R6: menu visible or no client supporting `textDocument/completion` → `""`; word before the cursor (`\k*$` non-empty) → `<C-n>`; otherwise call `vim.lsp.completion.get()` and return `""`; `desc = "Trigger completion"`
- [X] T014 [US3] Verify US3: quickstart.md scenarios 10, 11, 16 and 18 (scenario 18 in a terminal emulator that sends `<C-@>` for Ctrl+Space)

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T015 [P] Update README.md: add a "Completion" section (automatic menu in buffers with a language server, server items first then buffer words; keys `<Tab>` / `<S-Tab>` / `<CR>` / `<C-Space>`; default keys still work, `<C-n>` / `<C-p>` preview the item) and rewrite the C/C++ completion sentence that mentions `<C-x><C-o>` and `<C-n>` / `<C-p>` then `<C-y>` (spec FR-014)
- [X] T016 Check lua/config/completion.lua against `.editorconfig` and for lua_ls diagnostics (no errors or warnings), and confirm every mapping has a `desc` with `:verbose imap` (quickstart.md scenario 19)
- [X] T017 Run the automated checks in quickstart.md: `nvim --headless "+qa"` silent, `--startuptime` under 100 ms, `:checkhealth vim.lsp` without new errors (FR-013, SC-005)
- [X] T018 If T008 showed the `std::` limitation does not reproduce, remove that edge-case bullet from specs/007-lsp-completion-autotrigger/spec.md and research R7's "accept" decision in specs/007-lsp-completion-autotrigger/research.md; otherwise leave both

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002–T003)** → user stories.
- **US1 (T004–T008)** first: T004 and T005 before T006 (it references both); T007 after T006.
- **US2 (T009–T011)** depends only on Foundational for the mappings, but is only observable
  with a menu, so test it after US1.
- **US4 (T012)** after US1 and US2 (checks they did not break stock keys).
- **US3 (T013–T014)** after US1 (needs the source and `enable()` registration).
- **Polish**: T015 may run any time after the key set is final; T016–T018 last.

All implementation tasks edit the same file (lua/config/completion.lua), so they run in
sequence. The only parallel opportunity is T015 (README.md) alongside T016/T017.

## Parallel Example

```text
After T014:
  T015 README.md            ┐ in parallel
  T016 lint / desc check    ┘
then T017, T018
```

## Implementation Strategy

1. **MVP**: Setup + Foundational + US1 (T001–T008). Completion pops up automatically and is
   accepted with the stock `<C-y>`. This is already a usable increment and can be committed.
2. **Increment 2**: US2 (T009–T011): IDE-style keys. Commit.
3. **Increment 3**: US4 check (T012) and US3 `<C-Space>` (T013–T014). Commit.
4. **Polish** (T015–T018), README in its own `docs:` commit.

Commit messages follow Conventional Commits (`feat:` for the module, `docs:` for README and
spec updates).
