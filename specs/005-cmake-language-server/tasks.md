---

description: "Task list for CMake Language Server with Gersemi Formatting"
---

# Tasks: CMake Language Server with Gersemi Formatting

**Input**: Design documents from `/specs/005-cmake-language-server/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/keymaps-and-lsp.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested
on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root. Server configs live in `lsp/`, modules in
`lua/config/`. All Lua follows `.editorconfig` (2-space indent, 80 columns, double quotes,
trailing table separators, explicit call parentheses). No plugin and no new key mapping
(FR-010).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the external tools behave as research.md expects

- [X] T001 Check that `neocmakelsp --version` reports ≥ 0.11 (takes the `stdio` subcommand) and that `gersemi --version` runs, and create the scratch project from the Prerequisites in specs/005-cmake-language-server/quickstart.md

---

## Phase 2: Foundational (Blocking Prerequisites)

No foundational work is needed. Each story touches its own code path: US1 is the server and
its activation, US2 is the formatter and `<leader>lf` dispatch. Both edit
`lua/config/lsp.lua`, but in different functions.

---

## Phase 3: User Story 1 - Language intelligence while editing CMake files (Priority: P1) 🎯 MVP

**Goal**: neocmakelsp attaches to CMake buffers on demand, provides diagnostics, completion,
hover and go-to-definition, and never offers formatting.

**Independent Test**: quickstart.md scenarios 1–6, 13, 15, 17 and 18. The server attaches in a
`CMakeLists.txt`, not in other buffers. Hover, completion, definition and diagnostics work.
`formatexpr` is empty and formatting is unsupported.

- [X] T002 [P] [US1] Create lsp/neocmake.lua returning a server config with `cmd`, `filetypes` and `root_markers` exactly as given in data-model.md (neocmake server config.cmd, .filetypes, .root_markers), with a header comment explaining the root choice (research R2)
- [X] T003 [US1] In lsp/neocmake.lua add `on_init(client)` that sets `documentFormattingProvider`, `documentRangeFormattingProvider` and `documentOnTypeFormattingProvider` to `false` on `client.server_capabilities` (data-model.md neocmake server config.on_init; research R3), with a comment that this also keeps `formatexpr` unset so `gq` uses plain text formatting
- [X] T004 [US1] In lua/config/lsp.lua replace the `pattern = "lua", once = true` FileType autocommand (same `config_lsp` augroup, `clear = true`) with `pattern = { "lua", "cmake", }` driven by a local `servers` map and an `enabled` set per data-model.md (Filetype → server map): call `require("config.diagnostics").setup()` and `vim.lsp.enable(servers[args.match])` only when that server is not yet enabled; update the file's header comment
- [X] T005 [US1] Verify US1: run quickstart.md scenarios 1–6, 13, 15, 17 and 18 (also confirm `:checkhealth vim.lsp` lists `neocmake` and lua_ls still attaches in Lua files), and fix any lua_ls diagnostics in lsp/neocmake.lua and lua/config/lsp.lua

**Checkpoint**: CMake buffers have language features; `<leader>lf` in a CMake buffer reports
"No language server can format this buffer" (expected until US2).

---

## Phase 4: User Story 2 - Format CMake files with gersemi (Priority: P2)

**Goal**: `<leader>lf` in CMake buffers formats the whole buffer with gersemi, honouring the
project's `.gersemirc`, as a single undo step, with one clear message on failure.

**Independent Test**: quickstart.md scenarios 7–12, 14, 16 and 19. Output matches the gersemi CLI.
An already formatted buffer stays unmodified. A single undo reverts the change. The
`.gersemirc` is honoured. Parse errors and a missing gersemi each give one notice and leave
the buffer unchanged.

- [X] T006 [P] [US2] Create lua/config/gersemi.lua exposing `M.format(bufnr)`. Build the request from data-model.md (Gersemi format request.Input text, .--stdin-filepath, .Working directory, .Timeout) as `{ "gersemi", "--stdin-filepath", path, "-" }` (drop the flag pair for unnamed buffers) and run it synchronously with `vim.system(cmd, { stdin = text, cwd = dir, text = true, }):wait(timeout)` (research R4); pass no style options (FR-006)
- [X] T007 [US2] In lua/config/gersemi.lua implement the outcome states from data-model.md (Gersemi format request outcome states): return early with WARN `gersemi is not installed` when `vim.fn.executable("gersemi") == 0`; WARN `gersemi timed out` on `code == 124`; WARN `gersemi: <first non-empty stderr line>` on any other non-zero code; ignore stderr on exit 0 (research R5); never raise (wrap in `pcall` if needed) and show at most one notice
- [X] T008 [US2] In lua/config/gersemi.lua apply a successful result: split stdout into lines, drop the trailing empty element, and if it differs from the buffer, apply each hunk from `vim.text.diff(old, new, { result_type = "indices", })` with `nvim_buf_set_lines` in reverse order. If the text is identical, make no call at all (research R6; FR-008)
- [X] T009 [US2] In lua/config/lsp.lua `<leader>lf` callback, after the read-only check and before the LSP client lookup, add `if vim.bo.filetype == "cmake" then require("config.gersemi").format(0) return end` per contracts/keymaps-and-lsp.md; keep `desc = "Format buffer"` and the existing non-CMake path unchanged (FR-009)
- [X] T010 [US2] Verify US2: run quickstart.md scenarios 7–12, 14, 16 and 19 (compare output byte-for-byte with the gersemi CLI for SC-002), and fix any lua_ls diagnostics in lua/config/gersemi.lua and lua/config/lsp.lua

**Checkpoint**: Both stories work; CMake formatting comes only from gersemi.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T011 [P] Update README.md: add neocmakelsp and gersemi to Requirements as optional tools (install hints, what happens when they are missing), change the `<leader>lf` row to "Format the buffer with its language server, or with gersemi for CMake", and add a short "CMake" section (root detection, `.gersemirc` lookup, `gq` is plain text formatting, restart with `:lsp restart`) (FR-013)
- [X] T012 Run the repository checks from quickstart.md: `nvim --headless "+qa"` prints nothing and exits 0, both normally and with neocmakelsp and gersemi removed from `PATH` (FR-011, SC-005); startup time on an empty buffer stays < 100 ms; `:checkhealth` shows no new errors; `:map <leader>` shows no new mappings (SC-006)
- [X] T013 Commit in small Conventional Commits: `feat: add neocmakelsp language server` (T002–T004), `feat: format cmake buffers with gersemi` (T006–T009), `docs: document cmake support` (T011); commit the spec artifacts as `docs: add spec, plan and tasks for cmake language server`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none
- **Foundational (Phase 2)**: empty
- **US1 (Phase 3)**: after Setup
- **US2 (Phase 4)**: after Setup. It doesn't need US1 to work: gersemi formatting runs
  without a server, since `<leader>lf` checks the filetype before looking for LSP clients.
  T009 and T004 both edit lua/config/lsp.lua, so don't do them at the same time.
- **Polish (Phase 5)**: after the stories it describes. T011 can start at any time; T012
  and T013 come last.

### Within Each Story

- US1: T002 → T003 (same file) → T004 → T005
- US2: T006 → T007 → T008 (same file) → T009 → T010

### Parallel Opportunities

- T002 (lsp/neocmake.lua) and T006 (lua/config/gersemi.lua) are new files with no shared state.
- T011 (README.md) can be written alongside either story.

## Parallel Example

```text
# Start both stories together:
Task: "T002 [US1] Create lsp/neocmake.lua"
Task: "T006 [US2] Create lua/config/gersemi.lua"
Task: "T011 Update README.md"
# Then serialise the lua/config/lsp.lua edits: T004, then T009.
```

## Implementation Strategy

### MVP First (User Story 1)

1. T001 → T002–T004 → T005: CMake language features with neocmakelsp formatting turned off.
2. Stop and validate; this alone is usable.

### Incremental Delivery

1. Add US2 (T006–T010): gersemi formatting through `<leader>lf`.
2. Polish (T011–T013): README, repository checks, commits.
