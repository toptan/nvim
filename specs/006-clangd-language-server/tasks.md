---

description: "Task list for clangd Language Server with Built-in Formatting"
---

# Tasks: clangd Language Server with Built-in Formatting

**Input**: Design documents from `/specs/006-clangd-language-server/`

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

- [X] T001 Check that `clangd --version` and `clang-format --version` run and report the same LLVM version, and create the scratch project from the Prerequisites in specs/006-clangd-language-server/quickstart.md

---

## Phase 2: Foundational (Blocking Prerequisites)

No foundational work is needed. US2 (formatting) uses the existing `<leader>lf` LSP path
unchanged and only needs the server from US1.

---

## Phase 3: User Story 1 - Language intelligence while editing C and C++ files (Priority: P1) 🎯 MVP

**Goal**: clangd attaches to C-family buffers on demand and provides diagnostics, completion
(with clangd's default include insertion), hover, go-to-definition and find-references, using
the project's compilation database via clangd's own discovery.

**Independent Test**: quickstart.md scenarios 1–9, 15 (attach part), 17 (server part) and
18–22. clangd attaches in `main.cpp` and `util.h`, not in other buffers; the database in
`build-debug/` is found only after adding `.clangd`; hover, completion, definition, references
and diagnostics work.

- [X] T002 [P] [US1] Create lsp/clangd.lua returning a server config with `cmd`, `filetypes` and `root_markers` exactly as given in data-model.md (clangd server config.cmd, .filetypes, .root_markers), no `on_init` (data-model.md clangd server config.on_init) (FR-004b needs no code; research R8), with a header comment in the style of lsp/neocmake.lua explaining the root choice (research R2), that clangd runs without flags so its own compilation-database discovery, include insertion and `.clang-format` handling apply (research R1, R3; FR-004, FR-004a), and that formatting is deliberately kept (research R4)
- [X] T003 [US1] In lua/config/lsp.lua extend the `servers` map with `c`, `cpp`, `objc`, `objcpp` and `cuda` → `"clangd"` per data-model.md (Filetype → server map), wrapped to 80 columns; leave the FileType autocommand, the `enabled` set and `<leader>lf` unchanged, and update the file's header comment only if needed
- [X] T004 [US1] Verify US1: run quickstart.md scenarios 1–9, 15 (no message, `:checkhealth vim.lsp` reports clangd missing), 17 (all three servers coexist) and 18–22; confirm `:checkhealth vim.lsp` lists `clangd`, and fix any lua_ls diagnostics in lsp/clangd.lua and lua/config/lsp.lua

**Checkpoint**: C-family buffers have language features.

---

## Phase 4: User Story 2 - Format C and C++ files with clangd (Priority: P2)

**Goal**: `<leader>lf` formats the whole C-family buffer through clangd following
`.clang-format` (or clangd's fallback style), as a single undo step; `gq` formats selected
lines through clangd.

**Independent Test**: quickstart.md scenarios 10–14, 15 (`<leader>lf` part) and 16. Output matches `clang-format`; an already
formatted buffer stays unmodified; one undo reverts; `gq` reformats only the selection;
fallback style without `.clang-format`; missing clangd and read-only buffers give one notice.

No code is needed: research R4 showed the existing `<leader>lf` LSP path and Neovim's attach
default `formatexpr` already provide this once US1 attaches clangd with its formatting
capabilities intact (contracts/keymaps-and-lsp.md).

- [X] T005 [US2] Verify US2: run quickstart.md scenarios 10–14, 15 (`<leader>lf` part only) and 16 (compare `<leader>lf` output byte-for-byte with `clang-format --assume-filename=src/main.cpp` for SC-002; check `:set formatexpr?` for FR-008a); if any fails, fix it in lsp/clangd.lua or lua/config/lsp.lua without adding a second formatting path (FR-008) and keeping `<leader>lf` unchanged for other filetypes (FR-009)

**Checkpoint**: Both stories work; C-family formatting comes only from clangd.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T006 [P] Update README.md: add clangd to Requirements as an optional tool (`brew install llvm` or Xcode command-line tools; what happens when it is missing), change the `<leader>lf` row to also mention clangd for C and C++ using the project's `.clang-format`, and add a short "C and C++" section after "CMake": when it starts and for which file types, root detection, compilation-database lookup and the `.clangd` (`CompileFlags: CompilationDatabase: <dir>`) / symlink recipe for other build directories (research R3), `gq` formats through clangd, accepting a completion with `<C-y>` also inserts a missing `#include` and expands function argument placeholders (`<Tab>`/`<S-Tab>` to jump) (FR-004b), the index lives in `.cache/clangd/` next to the database (research R6), restart with `:lsp restart` (FR-013)
- [X] T007 Run the repository checks from quickstart.md: `nvim --headless "+qa"` prints nothing and exits 0, both normally and with clangd removed from `PATH` (FR-011, SC-005); startup time on an empty buffer stays < 100 ms; `:checkhealth` shows no new errors; `:map <leader>` shows no new mappings (SC-006)
- [X] T008 Commit in small Conventional Commits: `docs: add spec, plan and tasks for clangd language server` (specs/006-clangd-language-server/), `feat: add clangd language server` (T002–T003), `docs: document c and c++ support` (T006)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: none
- **Foundational (Phase 2)**: empty
- **US1 (Phase 3)**: after Setup
- **US2 (Phase 4)**: after US1 (formatting comes from the clangd client US1 attaches)
- **Polish (Phase 5)**: T006 can start at any time; T007 and T008 come last.

### Within Each Story

- US1: T002 → T003 → T004 (T002 and T003 touch different files, but T003 is only useful
  once lsp/clangd.lua exists)
- US2: T005 only

### Parallel Opportunities

- T002 (lsp/clangd.lua) and T006 (README.md) are independent files.

## Parallel Example

```text
Task: "T002 [US1] Create lsp/clangd.lua"
Task: "T006 Update README.md"
# Then T003 (lua/config/lsp.lua), T004, T005.
```

## Implementation Strategy

### MVP First (User Story 1)

1. T001 → T002–T003 → T004: C-family language features with clangd.
2. Stop and validate; this alone is usable (and already formats, which US2 verifies).

### Incremental Delivery

1. Verify US2 (T005): clangd formatting through `<leader>lf` and `gq`.
2. Polish (T006–T008): README, repository checks, commits.
