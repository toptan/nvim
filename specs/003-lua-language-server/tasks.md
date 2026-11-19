---

description: "Task list for Lua Language Server and Diagnostic Toggles"
---

# Tasks: Lua Language Server and Diagnostic Toggles

**Input**: Design documents from `/specs/003-lua-language-server/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md,
contracts/keymaps-and-lsp.md, quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching steps from `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and
testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Neovim config directory at repository root: `init.lua`, `lsp/lua_ls.lua`,
`lua/config/*.lua` (see plan.md "Project Structure"). All Lua follows `.editorconfig`
(2-space indent, 80 columns, double quotes, trailing table separators, explicit call
parentheses). Every mapping sets the `desc` given in contracts/keymaps-and-lsp.md (FR-017).
Exactly four mappings are added in total (FR-016). No `LspAttach` or buffer-local mappings.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the new modules from plan.md and load them

- [X] T001 [P] Create `lua/config/diagnostics.lua` as a module returning a table `M` with a
  no-op `M.setup()`, plus a header comment stating its concern (diagnostic display and the
  three toggles); see contracts/keymaps-and-lsp.md "`config.diagnostics` module API"
- [X] T002 [P] Create `lua/config/lsp.lua` with a header comment stating its concern
  (language-server activation and `<leader>lf`). It needs no return value
- [X] T003 Add `require("config.diagnostics")` then `require("config.lsp")` after
  `require("config.autocmds")` in `init.lua`. Confirm `nvim --headless "+qa"` prints nothing

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Initial diagnostic display, needed by the deferred LSP hook (US1) and by every
toggle (US2)

- [X] T004 Implement `M.setup()` in `lua/config/diagnostics.lua` with a module-local
  `did_setup` flag (data-model.md `config.diagnostics.did_setup`). On the first call, run
  `vim.diagnostic.config({ virtual_text = true, virtual_lines = false, })` (data-model.md
  Diagnostic display state: virtual text, virtual lines initial values; FR-012, research
  R5). Later calls return immediately. Do not call it at module load, so `vim.diagnostic` is
  not loaded at startup (Principle III). At module load, create augroup
  `config_diagnostics` (`clear = true`) with a `DiagnosticChanged` autocommand
  (`once = true`) whose callback calls `M.setup()`. This way diagnostics from any source, not
  only lua_ls, get the initial display (FR-012). Creating the autocommand does not load
  `vim.diagnostic`

**Checkpoint**: Foundation ready. User story work can begin.

---

## Phase 3: User Story 1 - Language intelligence while editing the config (Priority: P1) 🎯 MVP

**Goal**: lua_ls starts on the first Lua buffer and knows the `vim` runtime, this config's
modules and every installed plugin, with zero false diagnostics in the config.

**Independent Test**: quickstart.md §1, §2 (steps 1–4), §5, §6, §7 and §9.

### Implementation for User Story 1

- [X] T005 [P] [US1] Create `lsp/lua_ls.lua` returning a table with `cmd`, `filetypes`,
  `root_markers` and `settings` as specified in data-model.md (`lua_ls.cmd`,
  `lua_ls.filetypes`, `lua_ls.root_markers`, `lua_ls.settings.Lua`; research R1, R4). Do not
  set `root_dir`
- [X] T006 [US1] Add `on_init = function(client)` to `lsp/lua_ls.lua`, as described in
  research R3 and data-model.md `lua_ls.on_init`. The hook does the following:
  - If `client.workspace_folders` has a first folder that contains `.luarc.json` or
    `.luarc.jsonc` (`vim.uv.fs_stat`), return without changes.
  - Otherwise build `library` from `vim.env.VIMRUNTIME` plus `p.path` for each entry of
    `pcall(vim.pack.get, nil, { info = false, })`, treating a failed call as an empty list.
  - Deep-merge the Injected `Lua` settings (data-model.md `runtime.version`,
    `runtime.path`, `workspace.checkThirdParty`, `workspace.library`) into
    `client.config.settings.Lua` with `vim.tbl_deep_extend("force", …)`.
  - Send `client:notify("workspace/didChangeConfiguration", { settings = client.config.settings, })`.
  - Add a one-line comment for why the `.luarc` check exists: a project's own settings win.
- [X] T007 [US1] In `lua/config/lsp.lua`, create augroup `config_lsp` (`clear = true`) and a
  `FileType` autocommand with `pattern = "lua"` and `once = true`. Its callback calls
  `require("config.diagnostics").setup()` and then `vim.lsp.enable("lua_ls")`. Add a comment
  explaining the deferral (research R2) and that `enable` attaches the triggering buffer
- [X] T008 [US1] Open `init.lua` and every `lua/config/*.lua` with the server attached. Fix
  any errors or warnings it reports in those files, in place and without changing behaviour,
  until `vim.diagnostic.count()` is empty for each (SC-001, Principle V)
- [X] T009 [US1] Run quickstart.md §1 (including the non-Lua file check), §2 steps 1–4, §5
  (project settings and the loose file without a root), §6 (temporary plugin in an isolated
  `NVIM_APPNAME` copy, removed afterwards), §7 and §9 (server stopped). Record any deviation
  and fix it before continuing

**Checkpoint**: The config is served by lua_ls with no false `vim` diagnostics. Startup is
unchanged.

---

## Phase 4: User Story 2 - Control how diagnostics are shown (Priority: P2)

**Goal**: `<leader>td`, `<leader>tt` and `<leader>tl` toggle diagnostics globally, with a
message stating the new state.

**Independent Test**: quickstart.md §2 step 5 and §3. Needs a diagnostic source, which US1
provides.

### Implementation for User Story 2

- [X] T010 [US2] In `lua/config/diagnostics.lua`, add normal-mode `<leader>td`
  (`desc = "Toggle diagnostics"`). It calls `M.setup()`, then
  `vim.diagnostic.enable(not vim.diagnostic.is_enabled())`, then notifies
  `Diagnostics: on`/`off` at `vim.log.levels.INFO`. This covers data-model.md Diagnostic
  display state: enabled. See FR-007, FR-010 and contracts/keymaps-and-lsp.md
- [X] T011 [US2] In `lua/config/diagnostics.lua`, add a local helper `toggle(key, label)`. It
  calls `M.setup()`, flips `vim.diagnostic.config()[key]` with
  `vim.diagnostic.config({ [key] = not current, })`, and notifies
  `Diagnostic <label>: on/off`. While `not vim.diagnostic.is_enabled()`, it appends
  ` (diagnostics are off)` (FR-010, FR-011, US2 #4)
- [X] T012 [US2] Use the helper to add normal-mode `<leader>tt` → `toggle("virtual_text",
  "virtual text")` (`desc = "Toggle diagnostic virtual text"`) and `<leader>tl` →
  `toggle("virtual_lines", "virtual lines")` (`desc = "Toggle diagnostic virtual lines"`) in
  `lua/config/diagnostics.lua`. These cover data-model.md Diagnostic display state: virtual
  text, virtual lines. The two are independent (FR-008, FR-009)
- [X] T013 [US2] Run quickstart.md §2 step 5 and §3 steps 1–6, including the
  plain-text-buffer case. Fix any deviation

**Checkpoint**: All three toggles work globally, independently and with messages.

---

## Phase 5: User Story 3 - Format the current file (Priority: P3)

**Goal**: `<leader>lf` formats the whole buffer through the language server, following
`.editorconfig`, in one undo step.

**Independent Test**: quickstart.md §4. Needs US1.

### Implementation for User Story 3

- [X] T014 [US3] In `lua/config/lsp.lua`, add a global normal-mode `<leader>lf`
  (`desc = "Format buffer"`) implementing data-model.md Format request (all three buffer
  states, in order; research R6):
  - If `vim.bo.readonly` or not `vim.bo.modifiable`, notify `Buffer is read-only` (WARN).
  - Else if `vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting", })` is
    empty, notify `No language server can format this buffer` (WARN).
  - Else call `vim.lsp.buf.format({ bufnr = 0, async = false, timeout_ms = 3000, })`.
  - Add a comment explaining why the request is synchronous (no race with typing; one undo
    step).
- [X] T015 [US3] Run quickstart.md §4 steps 1–5. Fix any deviation

**Checkpoint**: All user stories work independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, style and the constitution's verification workflow

- [X] T016 [P] Update `README.md` (FR-019):
  - Under "Requirements", add `lua-language-server` (e.g. `brew install lua-language-server`).
    Note that without it Lua editing still works and `:checkhealth vim.lsp` reports it
    missing.
  - Add the four mappings to the "Key mappings" table with the effects from
    contracts/keymaps-and-lsp.md.
  - Add one sentence: projects with their own `.luarc.json` keep their settings.
- [X] T017 Run `<leader>lf` on `lsp/lua_ls.lua`, `lua/config/lsp.lua` and
  `lua/config/diagnostics.lua`. A second run must produce no changes, and each file must show
  0 diagnostics (Principle V)
- [X] T018 Run quickstart.md §8 (`:map <leader>` shows exactly the four new mappings, each
  with `desc`; SC-006) and §1 again (`nvim --headless "+qa"` silent; `--startuptime` under
  100 ms and not above the ≈ 8 ms baseline by more than noise; SC-005)
- [X] T019 Run `:checkhealth` and confirm no new errors. With `lua-language-server` on
  `PATH`, `vim.lsp` lists `lua_ls` as enabled (Constitution workflow)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies.
- **Foundational (Phase 2)**: depends on T001 and T003.
- **US1 (Phase 3)**: depends on Phase 2, because T007 calls `setup()`.
- **US2 (Phase 4)**: depends on Phase 2 for implementation. It can be coded alongside US1,
  but verifying it (T013) needs US1 as the diagnostic source.
- **US3 (Phase 5)**: depends on US1 (T005–T007). Formatting needs an attached server.
- **Polish (Phase 6)**: depends on all stories.

### Within Each Story

- US1: T005 → T006 (same file). T007 can run in parallel with T005/T006 (different file).
  T008 and T009 come after all three.
- US2: T010 → T011 → T012 (same file) → T013.
- US3: T014 → T015.

### Parallel Opportunities

- T001 ∥ T002 (different new files).
- T005 ∥ T007 (`lsp/lua_ls.lua` vs `lua/config/lsp.lua`).
- US2 implementation (T010–T012, `lua/config/diagnostics.lua`) ∥ US1 implementation
  (`lsp/lua_ls.lua`, `lua/config/lsp.lua`).
- T016 (README) ∥ any task after the stories are implemented.

## Parallel Example: User Story 1

```text
Task: "T005 [US1] Create lsp/lua_ls.lua with cmd, filetypes, root_markers, settings"
Task: "T007 [US1] Deferred FileType hook in lua/config/lsp.lua"
```

## Parallel Example: User Story 2 alongside User Story 1

```text
Task: "T010–T012 [US2] Toggles in lua/config/diagnostics.lua"
Task: "T005–T006 [US1] Server definition in lsp/lua_ls.lua"
```

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 → Phase 2 → Phase 3.
2. Stop and validate with T009. The config is then served by lua_ls with no false `vim`
   warnings. Commit (`feat: add lua language server`).

### Incremental Delivery

1. MVP as above.
2. Add US2 (toggles), validate with T013, and commit.
3. Add US3 (`<leader>lf`), validate with T015, and commit.
4. Polish (T016–T019), and commit README updates with the last feature commit or as `docs:`.
