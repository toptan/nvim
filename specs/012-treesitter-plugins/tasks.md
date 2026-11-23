---

description: "Task list for Tree-sitter Parsers and Syntax-Aware Text Objects"
---

# Tasks: Tree-sitter Parsers and Syntax-Aware Text Objects

**Input**: Design documents from `/specs/012-treesitter-plugins/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/treesitter.md,
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

The Neovim config directory is the repository root. All feature code lives in the new module
`lua/config/treesitter.lua`, so most tasks edit the same file and run in order. All Lua follows
`.editorconfig` (2-space indent, 80 columns, double quotes, trailing table separators, explicit
call parentheses). Every call into plugin code or `vim.treesitter` that can fail is wrapped in
`pcall` (contracts/treesitter.md "Module API"); the module shows no messages of its own.

Destructive or fresh-machine checks run with `XDG_DATA_HOME`, `XDG_STATE_HOME` and
`XDG_CACHE_HOME` pointed at a scratch directory (quickstart.md "Prerequisites"), never against
the real data directory.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the external tools and sample files exist

- [X] T001 Check that `git`, `curl`, `tar`, a C compiler (`$CC`, `cc`, `gcc` or `clang`) and `tree-sitter --version` (≥ 0.26.1) are on `PATH` (research.md R11), and create the sample files listed in the Prerequisites of specs/012-treesitter-plugins/quickstart.md in a scratch directory outside the repository

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Module skeleton, plugin registration and lazy loading that every story builds on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T002 Create lua/config/treesitter.lua with a header comment, the `LANGUAGES` list (data-model.md Supported language list), the `FILETYPES` map (data-model.md Filetype map), the module-local state fields `loaded`, `install`, `update_pending`, `pending`, `tools_warned` (data-model.md Module state.loaded, Module state.install, Module state.update_pending, Module state.pending, Module state.tools_warned; `install` starts as `"idle"`), and the augroup `config_treesitter` created with `clear = true`
- [X] T003 In lua/config/treesitter.lua call `vim.pack.add()` for nvim-treesitter and nvim-treesitter-textobjects with `{ confirm = false, load = function() end }` and no `version`, with the one-line justification comment beside each spec from contracts/treesitter.md "Plugins" (research.md R1, R3, R4); leave a marked spot above this call for the `PackChanged` autocommand added in T015
- [X] T004 In lua/config/treesitter.lua add a local `ensure_loaded()` that, once per session (data-model.md Module state.loaded), runs `vim.cmd.packadd()` for both plugins inside `pcall` and returns whether loading succeeded
- [X] T005 Add `require("config.treesitter")` after `require("config.lsp")` in init.lua
- [X] T006 Verify the foundation: `nvim --headless "+qa"` exits silently (with a scratch data dir it only shows vim.pack's install progress the first time), `nvim --startuptime` stays under 100 ms with the module costing at most a few ms, and on an empty buffer `package.loaded["nvim-treesitter"]` is `nil` (quickstart.md §1)

**Checkpoint**: Plugins are registered and installed, nothing is loaded at startup

---

## Phase 3: User Story 1 - Syntax-tree features in supported languages (Priority: P1) 🎯 MVP

**Goal**: Supported buffers get tree-sitter highlighting, folding and indentation (where the
language has the query); unsupported buffers are untouched.

**Independent Test**: With parsers present (in a scratch data dir, run `:TSInstall` for the
12 languages after opening a supported file), quickstart.md §5 passes for every sample file,
and an empty start loads no plugin code (§1).

- [X] T007 [US1] In lua/config/treesitter.lua add a local `attach(buf, lang)` per data-model.md "Buffer attachment": `pcall(vim.treesitter.start, buf, lang)` and return `false` on failure; when a `folds` query exists set `foldmethod=expr`, `foldexpr=v:lua.vim.treesitter.foldexpr()` and `foldlevel=99` via `vim.wo[win][0]` for every window showing `buf`; when an `indents` query exists and the plugins are loaded (data-model.md Module state.loaded) set `vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`; otherwise leave the built-in indentation (installed queries stay on `runtimepath` even when the plugin folders are missing); record the language in `vim.b[buf].config_treesitter` (data-model.md Buffer attachment.config_treesitter); detect queries with `vim.treesitter.query.get_files(lang, kind)` (research.md R8); leave a call site for the US3 mappings
- [X] T008 [US1] In lua/config/treesitter.lua add a local `detach(buf)` that runs `pcall(vim.treesitter.stop, buf)`, resets `foldmethod`, `foldexpr` and `foldlevel` to their `vim.go` values via `vim.wo[win][0]` for every window showing `buf`, resets `vim.bo[buf].indentexpr` to `vim.go.indentexpr` only if it still equals the tree-sitter expression, and clears `vim.b[buf].config_treesitter` (data-model.md Buffer attachment, "Detach"), with a call site for removing the US3 mappings
- [X] T009 [US1] In lua/config/treesitter.lua create the `FileType` autocommand (pattern `*`, group `config_treesitter`) from contracts/treesitter.md "Autocommands": for a filetype in `FILETYPES`, call `ensure_loaded()` then `attach(args.buf, lang)`; for any other filetype, call `detach(args.buf)` only if `vim.b[args.buf].config_treesitter` is set; leave a call site for starting the US2 install
- [X] T010 [US1] Verify US1 with quickstart.md §5 (highlighting, folds opening unfolded, indentation, Markdown and regex injections, JSON unchanged, and the "detach" row: `:set filetype=text` in `sample.c` restores the global fold options, empties `indentexpr` and removes tree-sitter highlighting) and §1 (lazy, silent start)

**Checkpoint**: MVP: tree-sitter features work once parsers exist

---

## Phase 4: User Story 2 - Parsers installed and kept in sync automatically (Priority: P2)

**Goal**: The first supported file installs all missing parsers in the background, waiting
buffers switch over automatically, and every plugin change runs one parser update.

**Independent Test**: quickstart.md §2–§4 and §7 in a scratch data dir: empty start installs
nothing; opening `sample.c` installs all 12 parsers and the buffer switches over; a normal
restart is silent; a plugin update runs one update.

- [X] T011 [US2] In lua/config/treesitter.lua add a local `missing_tools()` returning the missing build tools (`tree-sitter`, `curl`, `tar`, and a C compiler when none of `$CC`, `cc`, `gcc`, `clang` is executable) via `vim.fn.executable()`, and a local `warn_missing(tools)` that shows one `vim.notify(..., vim.log.levels.WARN)` per session, `Tree-sitter parsers not installed, missing: <tools>` (research.md R7 "Tool pre-check"; data-model.md Module state.tools_warned; contracts/treesitter.md "Messages")
- [X] T012 [US2] In lua/config/treesitter.lua add a local `run_update()` that returns at once when `update_pending` is false (so extra scheduled calls from one batch of plugin changes do nothing), otherwise clears `update_pending` and, if `missing_tools()` is empty, runs `require("nvim-treesitter").update(LANGUAGES)` in `pcall` without a `summary` option, otherwise calls `warn_missing()` (data-model.md "Update flow", Module state.update_pending)
- [X] T013 [US2] In lua/config/treesitter.lua add a local `install_parsers()` following the install state transitions in data-model.md (Module state.install): when `"idle"` and `missing_tools()` is non-empty, call `warn_missing()`, set `"done"` and run `run_update()` if `update_pending`; when `"idle"` and the tools are present, set `"running"` and call `require("nvim-treesitter").install(LANGUAGES)` in `pcall` without a `summary` option (research.md R5, R7); put the completion steps in a local `finish_install()` (set `"done"`, re-attach every buffer in `pending` that is still valid and still has a supported filetype (data-model.md Module state.pending), empty `pending`, then call `run_update()` if `update_pending`); call it from the task's `:await()` callback wrapped in `vim.schedule`, or directly if the `pcall` fails, so the state never stays `"running"`; when already `"done"`, call `run_update()` if `update_pending`
- [X] T014 [US2] In lua/config/treesitter.lua call `install_parsers()` from the `FileType` handler after `ensure_loaded()` succeeds, and add the buffer to `pending` when `attach()` returns `false` (FR-004, FR-004a)
- [X] T015 [US2] In lua/config/treesitter.lua create the `PackChanged` autocommand in group `config_treesitter` *before* the `vim.pack.add()` call (research.md R5, R6, contracts/treesitter.md "Autocommands"): for `ev.data.kind` `"install"` or `"update"` and `ev.data.spec.name` in {`nvim-treesitter`, `nvim-treesitter-textobjects`}, set `update_pending` (data-model.md Module state.update_pending); only if `loaded` is true and `install` is not `"running"` (data-model.md Module state.install), `vim.schedule(run_update)` (repeated scheduling is harmless, see T012); otherwise leave it for `install_parsers()`; never call `ensure_loaded()` here (FR-002); ignore `"delete"`; because this autocommand sits above `vim.pack.add()`, place the `missing_tools`, `warn_missing` and `run_update` locals (and the state they use) above it so the callback sees them
- [X] T016 [US2] Verify US2 with quickstart.md §1.3, §2, §3, §4 and §7 in a scratch data dir: the first (plugin-installing) start never loads nvim-treesitter; no parsers after an empty start; 12 parsers and an automatic switch after opening `sample.c`, with no second install when another file is opened meanwhile; no messages on restart; one update per plugin change, not overlapping a running install; with `tree-sitter` hidden from `PATH` exactly one warning naming it, no install attempt and no Lua traceback, also after a restart; with the plugin folders removed but parsers still installed, opening `sample.c` gives highlighting, `indentexpr` stays the built-in one, and typing raises no errors

**Checkpoint**: Fresh clone → first supported file → working tree-sitter, with no manual steps

---

## Phase 5: User Story 3 - Syntax-aware text objects and jumps (Priority: P3)

**Goal**: Buffer-local `af/if`, `ac/ic`, `aa/ia`, `]f/[f`, `]c/[c` in supported buffers that
have a `textobjects` query, with diff-aware `]c/[c`.

**Independent Test**: quickstart.md §6 in the C, C++, Lua and Python samples, including the
diff-mode check with `nvim -d`.

- [X] T017 [US3] In lua/config/treesitter.lua add a local `map_textobjects(buf)` that, only when `vim.treesitter.query.get_files(lang, "textobjects")` is non-empty, sets the buffer-local `x`/`o` select mappings `af`, `if`, `ac`, `ic`, `aa`, `ia` calling `require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")`, and the `n`/`x`/`o` jumps `]f`/`[f` calling `require("nvim-treesitter-textobjects.move").goto_next_start` / `goto_previous_start` with `"@function.outer"`, using the keys and `desc` values from contracts/treesitter.md "Buffer-local key mappings" (research.md R9)
- [X] T018 [US3] In lua/config/treesitter.lua add `]c`/`[c` to `map_textobjects(buf)` as buffer-local `expr` mappings (modes `n`, `x`, `o`, non-recursive) that return `"]c"`/`"[c"` when `vim.wo.diff` is set and otherwise a `<Cmd>` call to the class jump on `"@class.outer"`, with the `desc` values from contracts/treesitter.md (research.md R9, FR-010a)
- [X] T019 [US3] In lua/config/treesitter.lua call `map_textobjects(buf)` from `attach()` only when the plugins are loaded (data-model.md Module state.loaded), and in `detach()` delete those buffer-local mappings with `pcall(vim.keymap.del, mode, lhs, { buffer = buf })` (FR-010b)
- [X] T020 [US3] Verify US3 with quickstart.md §6: selections and deletions, jumps with counts and `<C-o>`, silent no-ops, `:map <buffer>` descriptions, diff-mode `]c`/`2]c` and the class jump after `:diffoff`, and no `]c` buffer mapping in the JSON sample

**Checkpoint**: All user stories work on their own

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentation and final checks across all stories

- [X] T021 [P] Update README.md: add `tree-sitter` CLI ≥ 0.26.1, a C compiler, `curl` and `tar` to Requirements; add a "Tree-sitter" section (the two plugins, the 12 languages, install on the first supported file, update on plugin change, highlighting/folding/indentation per language, `:TS*` commands and `:checkhealth nvim-treesitter` only after the first supported file; the single warning when build tools are missing); add the text objects and jumps to the key-mappings table, noting that `]c`/`[c` keep their diff meaning in diff mode (FR-013)
- [X] T022 Check lua/config/treesitter.lua against Constitution Principle V: no lua_ls diagnostics, 80 columns, every mapping has a `desc`, every autocommand is in `config_treesitter`
- [X] T023 Run the full specs/012-treesitter-plugins/quickstart.md once more against the real config, then run `:checkhealth nvim-treesitter` and `:checkhealth vim.pack` and confirm there are no new errors (quickstart.md §8)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies
- **Foundational (Phase 2)**: after Setup; blocks all stories
- **US1 (Phase 3)**: after Foundational
- **US2 (Phase 4)**: after US1 (hooks into the `FileType` handler and `attach()` from T007/T009)
- **US3 (Phase 5)**: after US1 (hooks into `attach()`/`detach()`); independent of US2
- **Polish (Phase 6)**: after the stories you want to ship

### User Story Dependencies

- **US1 (P1)**: no dependencies on other stories; parsers for testing come from `:TSInstall`
- **US2 (P2)**: needs US1's handler and `attach()`; testable on its own via quickstart §2–§4
- **US3 (P3)**: needs US1's `attach()`/`detach()`; can be built before or after US2

### Within Each User Story

- Tasks edit the same file and run in ID order; each phase ends with its verification task

### Parallel Opportunities

- T005 (init.lua) can be written alongside T002–T004 but must not be committed before them
- T021 (README.md) can be written in parallel with T022–T023
- US2 and US3 touch different functions of the same file; do them one after the other to
  avoid edit conflicts

---

## Parallel Example: Polish

```bash
Task: "Update README.md with requirements, Tree-sitter section and key mappings (T021)"
Task: "Check lua/config/treesitter.lua against Principle V (T022)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 and Phase 2
2. Phase 3 (US1), then **stop and validate** with quickstart §1 and §5
3. Commit (`feat: add tree-sitter highlighting, folding and indentation`)

### Incremental Delivery

1. US1 → commit
2. US2 → commit (`feat: install and update tree-sitter parsers automatically`)
3. US3 → commit (`feat: add tree-sitter text objects and jumps`)
4. Polish → commit (`docs: document tree-sitter support`)

---

## Notes

- [P] tasks = different files, no dependencies
- Commit after each phase, following Conventional Commits
- Never run fresh-machine or destructive checks against the real `~/.local/share/nvim`
