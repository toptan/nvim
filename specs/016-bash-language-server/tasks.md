---

description: "Task list for Bash Language Server"
---

# Tasks: Bash Language Server

**Input**: Design documents from `/specs/016-bash-language-server/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/keymaps-and-lsp.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested
on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root. Server configs live in `lsp/`, modules in
`lua/config/`. All Lua follows `.editorconfig` (2-space indent, 80 columns, double quotes,
trailing table separators, explicit call parentheses). No plugin and no new key mapping
(FR-010).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the external tools behave as research.md expects

- [X] T001 Check that `bash-language-server --version`, `shellcheck --version` and `shfmt --version` run, and create the scratch project from the Prerequisites in specs/016-bash-language-server/quickstart.md

---

## Phase 2: Foundational (Blocking Prerequisites)

No foundational work is needed. US2 (formatting) uses the existing `<leader>lf` LSP path
unchanged and only needs the server from US1; US3 (tree-sitter) is independent of the server.

---

## Phase 3: User Story 1 - Language intelligence while editing shell scripts (Priority: P1) 🎯 MVP

**Goal**: bashls attaches to `sh`/`bash` buffers on demand and provides completion, hover,
go-to-definition (including `source`d files), references, rename and ShellCheck diagnostics.

**Independent Test**: quickstart.md scenarios 1–8, 8a–8c and 13: no client on an empty buffer;
bashls attaches in `run.sh` and `noext` with root `/tmp/shproj`, not for zsh; hover,
definition into `lib/util.sh`, rename, completion and the SC2086 diagnostic work; a missing
server raises no error.

- [X] T002 [P] [US1] Create lsp/bashls.lua returning a server config with `cmd`, `filetypes` and `root_markers` exactly as given in data-model.md (Server config.cmd, .filetypes, .root_markers) and no `settings` (research R1, R5), with a header comment in the style of lsp/neocmake.lua explaining the root choice (git repository, otherwise single file; research R1) and that ShellCheck and shfmt are found on `PATH`; `on_init` is added later by T005
- [X] T003 [US1] Add `sh = "bashls"` and `bash = "bashls"` to the `servers` table in lua/config/lsp.lua per data-model.md (Filetype → server map), keeping the table's style; nothing else in the file changes (research R8)
- [X] T004 [US1] Verify US1: run quickstart.md scenarios 1–8, 8a–8c and 13 and confirm `nvim --headless "+qa"` exits cleanly

**Checkpoint**: Shell scripts get language intelligence; MVP usable.

---

## Phase 4: User Story 2 - Format shell scripts with `<leader>lf` (Priority: P2)

**Goal**: `<leader>lf` formats the whole shell buffer through bashls/shfmt honouring
`.editorconfig`, and shows the existing single notice when shfmt is missing.

**Independent Test**: quickstart.md scenarios 9–12, 11a, 12a and 12b: 2-space re-indent in
one undo step, no diff against `shfmt -d`, no change on a second run, 4 spaces without
`.editorconfig`, the "No language server can format this buffer" warning without shfmt,
formatting without ShellCheck, and the read-only notice.

- [X] T005 [US2] Add `on_init` to lsp/bashls.lua per data-model.md (Server config.on_init): when `vim.fn.executable("shfmt") == 0`, set `client.server_capabilities.documentFormattingProvider = false`, guarding `server_capabilities` for nil as lsp/neocmake.lua does, with a comment explaining that the server advertises formatting even without shfmt (research R4); depends on T002
- [X] T005a [US2] (Added during implementation) In lua/config/lsp.lua make `<leader>lf` undo a format edit that leaves the text identical and created its own undo step, keeping the view (research R3 "Already formatted buffer")
- [X] T006 [US2] Verify US2: run quickstart.md scenarios 9–12, 11a, 12a and 12b and confirm `gq` in `run.sh` does plain text formatting (`:set formatexpr?` is empty; research R3)

**Checkpoint**: US1 and US2 both work.

---

## Phase 5: User Story 3 - Tree-sitter support for shell scripts (Priority: P3)

**Goal**: `sh`/`bash` buffers get tree-sitter highlighting, folding, indentation, text objects
and jumps via the `bash` parser.

**Independent Test**: quickstart.md scenarios 14–15: tree-sitter highlighter active, the
function folds, `vaf` selects it, class keys do nothing without error.

- [X] T007 [P] [US3] In lua/config/treesitter.lua add `"bash"` to `LANGUAGES` directly after `"asm"`, and `bash = "bash"`, `sh = "bash"` to `FILETYPES` directly after `asm = "asm"` (the table is not strictly alphabetical: `help` is last), per data-model.md (Tree-sitter tables) and research R7; no other changes
- [X] T008 [US3] Verify US3: open a shell script so the `bash` parser installs, then run quickstart.md scenarios 14–15

**Checkpoint**: All three stories work independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and constitution checks

- [X] T009 [P] Update README.md per contracts/keymaps-and-lsp.md (README) and plan.md Implementation Notes item 4: Requirements entries for `bash-language-server` (`brew install bash-language-server`), `shellcheck` and `shfmt`, each optional with what is lost without it (FR-009); the `<leader>lf` row mentions shell scripts following `.editorconfig`; a new "Shell scripts" section after "C and C++" (starts on first `sh`/`bash` file, git root or single file, ShellCheck diagnostics, formatting via shfmt; indentation from `.editorconfig`, else 4 spaces, `gq` stays plain, zsh not covered); in the Tree-sitter section add shell (sh/bash) to the languages and to the languages with text objects and jumps (FR-012)
- [X] T010 Check lua_ls diagnostics for lsp/bashls.lua, lua/config/lsp.lua and lua/config/treesitter.lua are clean, `:checkhealth vim.lsp` shows bashls without new errors, and startup time is unchanged (quickstart.md scenarios 16–17)
- [X] T011 Update the stale note in specs/016-bash-language-server/checklists/requirements.md that still calls the tree-sitter parser out of scope

---

## Dependencies & Execution Order

- **Setup (T001)**: first.
- **US1 (T002 → T003 → T004)**: after Setup. T003 needs T002 so the enabled server exists.
- **US2 (T005 → T006)**: needs T002 (same file) and T003 (server running).
- **US3 (T007 → T008)**: independent of US1/US2; can start after Setup.
- **Polish (T009–T011)**: T009 and T011 any time; T010 after T002, T003, T005 and T007.

### Parallel Opportunities

- T002 (lsp/bashls.lua) and T007 (lua/config/treesitter.lua) touch different files and can run
  together.
- T009 (README.md) and T011 (checklist) can run alongside any implementation task.

### Parallel Example

```text
T002 [US1] Create lsp/bashls.lua
T007 [US3] Add bash parser to lua/config/treesitter.lua
T009       Update README.md
```

## Implementation Strategy

1. **MVP**: T001–T004 (US1) gives shell scripts language features; commit as
   `feat: enable bash-language-server for shell scripts`.
2. **Increment 2**: T005–T006 (US2) adds the shfmt guard; commit as
   `feat: format shell scripts with <leader>lf`.
3. **Increment 3**: T007–T008 (US3); commit as `feat: tree-sitter support for shell scripts`.
4. **Polish**: T009–T011; commit README as `docs: document shell script support`.
