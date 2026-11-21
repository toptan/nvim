---

description: "Task list for Completion via mini.completion"
---

# Tasks: Completion via mini.completion

**Input**: Design documents from `/specs/010-mini-completion/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/completion.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`. Drive the TUI with tmux
(`tmux -L <name> new-session -d -x 120 -y 30 "nvim -n <file>"`, `send-keys`, `capture-pane`);
`-n` avoids swap-file prompts that swallow keys after a killed session.

**Isolation rule**: any run with a modified copy of the config MUST override all four of
`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` together, and any run
of the real config MUST unset all four. Mixing them lets `vim.pack` write entries for the wrong
plugin set into the real `nvim-pack-lock.json` (happened during planning).

**Verification note (implementation)**: T001–T015 were run against the real config in a
tmux-driven TUI (C++ checks with clangd, Lua with lua_ls). Startup ~11.3 ms → ~11.1 ms;
mappings n 68 → 68, i 8 → 7 at startup (`<C-Space>` is now mapped by the plugin on first
Insert mode); `:checkhealth` errors 0 → 0 (`vim.pack` notes `mini.completion` as "not active"
in headless runs, expected for a lazily loaded plugin); lua_ls: 0 diagnostics. T002 placed
`shortmess+=c` beside `'completeopt'` (completion concern) rather than beside the search `S`
flag. tmux pitfalls found while testing: a lone `;` argument is a tmux command separator (send
`'\;'`), and tmux's `S-Tab` key name does not send Shift-Tab (use `BTab`).

**Organization**: Tasks are grouped by user story. The completion module is one file, so its
code tasks are sequential; `options.lua` and README work can run in parallel with it.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root; modules live in `lua/config/`. Lua follows
`.editorconfig`: 2-space indent, 80 columns, double quotes, trailing table separators, explicit
call parentheses. Every mapping has a `desc`; no global defined by the config.

---

## Phase 1: Setup

**Purpose**: Confirm the starting point.

- [X] T001 Record baselines from the repo root (real config, `XDG_*` unset): `nvim --headless "+qa"`
  (expect no output); five runs of `nvim --headless --startuptime <scratch>/before-N.log +qa`
  (note the `NVIM STARTED` times, ~11–12 ms expected); insert-mode keymap count via
  `nvim --headless "+lua print(#vim.api.nvim_get_keymap('i'))" +qa` and normal-mode count
  (`'n'`); `:checkhealth` error count. For comparison in T015

---

## Phase 2: Foundational

**Purpose**: Editor options the plugin relies on; needed by US1 and US2.

- [X] T002 [P] In `lua/config/options.lua`, change `'completeopt'` to
  `{ "menuone", "noselect", "fuzzy", }` (drop `popup`, per `data-model.md`
  `Editor options.'completeopt'`; research R3) and add `vim.opt.shortmess:append("c")` next to
  the existing `shortmess` line (per `data-model.md` `Editor options.'shortmess'`). Update the
  comments: the completion comment says item details come from mini.completion's Info window;
  the `c` flag silences fallback-completion messages

**Checkpoint**: Options ready; old completion still works (only the `popup` preview is gone).

---

## Phase 3: User Story 1 - Completion still appears while typing (Priority: P1) 🎯 MVP

**Goal**: The plugin, with defaults, opens the menu by itself (LSP first, buffer words as
fallback, every buffer), shows Info and Signature windows, and expands snippets.

**Independent Test**: quickstart.md scenarios 1, 4, 6, 7 (menu opens by itself; signature;
plain-text buffer; C++ triggers).

- [X] T003 [US1] Replace the entire contents of `lua/config/completion.lua` with a module that:
  (1) has a header comment describing the behaviour (mini.completion with defaults, loaded on
  first Insert mode; IDE-style keys) and the Principle I justification (core `'autocomplete'` +
  `vim.lsp.completion` needed ~250 lines of workarounds to merge server and buffer suggestions;
  plugin does it natively); (2) creates augroup `config_completion` (`clear = true`) with a
  `once = true` `InsertEnter` autocommand (per `data-model.md` `Plugin spec.Loaded`) that `pcall`s
  `vim.pack.add({ "https://github.com/nvim-mini/mini.completion", }, { confirm = false, })`
  (source per `data-model.md` `Plugin spec.Source`, no version per `Plugin spec.Version`,
  opts per `Plugin spec.vim.pack.add opts`; research R1, R5), then, only on success, `pcall`s
  `require("mini.completion").setup()` with no arguments (`Plugin spec.Setup`; research R2),
  then on success sets `vim.bo.completefunc = "v:lua.MiniCompletion.completefunc_lsp"` for the
  current buffer (its `BufEnter` happened before the plugin existed; R5); keep the success flag
  in a module-local variable; (3) on failure, `vim.schedule`s one
  `vim.notify("mini.completion unavailable: using built-in completion", vim.log.levels.WARN)`
  (research R6); (4) returns an empty module table. Do not carry over any of the code listed in
  research R9. Keymaps are added in T005–T006
- [X] T004 [US1] Verify US1 in a tmux-driven TUI with the real config (quickstart.md 1, 4, 6, 7):
  first Insert mode installs the plugin with no prompt; `vim.ap` opens a menu of lua_ls items
  without a key press, visible in a `capture-pane` taken 0.5 s after the last key (SC-001);
  `(` after `vim.api.nvim_buf_get_lines` shows ` Signature `; in a `.txt` file `alp` lists
  buffer words; in C++ `std::stri`, `q->`, `p.` list the right members; typing
  `std::unordered_m` lists `unordered_map` / `unordered_multimap` (clangd returns at most 100
  items for `std::`, so the list must be re-requested as the word grows; spec Edge Cases);
  with an item highlighted via `<Down>`, exactly one ` Info ` window shows (no `popup` preview);
  accepting a snippet item (`std::to_stri` → `to_string`) expands it with a placeholder
  selected; in the Lua file, after adding the line `-- zebracorn` and typing `zebr` on a new
  line, `zebracorn` is offered (server has no match, buffer-word fallback; US1-3); no
  "match N of M" messages appear on the command line

**Checkpoint**: Completion works via the plugin (with built-in keys); MVP reached.

---

## Phase 4: User Story 2 - Familiar keys keep working (Priority: P1)

**Goal**: `<Tab>` / `<S-Tab>` / `<CR>` behave as before; `<C-Space>` / `<C-@>` use the
plugin's trigger (clarification Q1 = B).

**Independent Test**: quickstart.md scenarios 2, 3, 5, 8–11.

- [X] T005 [US2] In `lua/config/completion.lua`, add the expression mappings from
  `contracts/completion.md` (Keys table; research R4): `<Tab>` / `<S-Tab>` → `<Down>` / `<Up>`
  when `pumvisible()`, else `vim.snippet.jump(±1)` via `<Cmd>` if `vim.snippet.active`, else the
  key itself; `<CR>` → `<C-y>` if `complete_info({ "selected" }).selected ~= -1`, `<C-e><CR>`
  if the menu is open with nothing selected, else `<CR>`. Reuse the descriptions of the old
  mappings ("Next completion item, snippet jump or Tab", etc.). Short comment: `<Down>`/`<Up>`
  select without inserting, unlike `<C-n>`/`<C-p>`
- [X] T006 [US2] In `lua/config/completion.lua`, map Insert-mode `<C-@>` (comment: terminals
  usually send Ctrl+Space as `<C-@>`; the plugin maps `<C-Space>` itself) to a function that
  calls `MiniCompletion.complete_twostage()` only if the plugin loaded (module-local flag from
  T003), `desc = "Trigger completion"`. Do not map `<C-Space>` (plugin default `force_twostep`)
- [X] T007 [US2] Verify US2 in tmux (quickstart.md 2, 3, 5, 8–11): `<Tab>` highlights without
  inserting, `<S-Tab>` goes back; `<CR>` accepts without a new line; `<CR>` with nothing
  highlighted closes the menu and breaks the line; after a snippet expands, typing replaces the
  placeholder and `<Tab>` jumps; with the menu closed `<Tab>` inserts a tab; `<C-@>` (tmux
  `C-Space`) on an empty line opens the menu; normal-mode `<Tab>` / `<S-Tab>` still switch
  buffers; type `std::unordered_map` quickly in one burst (tmux `send-keys -l`) right after
  `std::`: the full text appears exactly as typed (SC-002)

**Checkpoint**: Daily key workflow unchanged.

---

## Phase 5: User Story 3 - The custom implementation is gone (Priority: P1)

**Goal**: No trace of the custom completion; docs describe the plugin.

**Independent Test**: quickstart.md scenario 12; README review.

- [X] T008 [P] [US3] Rewrite the "Completion" section of `README.md` per
  `contracts/completion.md`: menu opens by itself in every buffer after a short pause or a
  trigger character (`.`, `->`, `::`), server suggestions first, buffer words when the server
  has none or there is no server; Info window for the highlighted item, Signature window inside
  call arguments; key table: `<Tab>` / `<S-Tab>`, `<CR>`, `<C-Space>` (`<C-@>`), `<A-Space>`
  (buffer words only), `<C-f>` / `<C-b>` (scroll Info/Signature); keep the paragraph on
  Neovim's own keys (`<C-y>`, `<C-e>`, `<Up>`/`<Down>`, `<C-n>`/`<C-p>`); remove "Buffers
  without a language server keep Neovim's usual manual completion"; keep the sentence that
  `<C-@>` no longer inserts the previously typed text (still true)
- [X] T009 [P] [US3] In `README.md` "Plugins" list, add
  [`mini.completion`](https://github.com/nvim-mini/mini.completion) with its one-line reason
  (Neovim's built-in automatic completion cannot merge server and buffer suggestions without
  extensive custom code) and the fallback note (without network on first Insert mode, Neovim's
  manual completion keys remain); in the "Popups" section mention the completion Info and
  Signature windows share the rounded border. Same file as T008: do them one after the other
- [X] T010 [US3] Verify US3: `grep -n "autocomplete\|TextChangedP\|TextChangedI\|matchfuzzypos\|LspDetach\|LspAttach\|vim.lsp.completion" lua/config/completion.lua`
  returns nothing (SC-003); `grep -rn "config.completion'.source\|config_completion" lua init.lua`
  shows only the new augroup; while typing, only one menu ever opens (no double popups or
  flicker from competing triggers)

**Checkpoint**: Code and docs reflect only the plugin-based behaviour.

---

## Phase 6: User Story 4 - Plugin installs itself on a fresh machine (Priority: P2)

**Goal**: Zero-step install and graceful degradation.

**Independent Test**: quickstart.md "Startup and robustness".

- [X] T011 [US4] Verify fresh install: move `~/.local/share/nvim/site/pack/core/opt/mini.completion`
  to a scratch location, start `nvim` on a Lua file and enter Insert mode; the plugin installs
  without a prompt and the menu works in the same session; `:checkhealth vim.pack` lists
  `mini.completion` without errors. Delete the moved copy
- [X] T012 [US4] Verify fault tolerance in an isolated copy (all four `XDG_*` overridden, see
  Isolation rule): change the URL in the copy's `lua/config/completion.lua` to a non-existent
  repository, start `nvim` in a real TUI, enter Insert mode: no "Press ENTER" prompt, no stack
  trace, exactly one WARN notice; `<Tab>` / `<CR>` behave as plain keys; `<C-@>` does nothing;
  `<C-n>` gives built-in completion. If a prompt appears, fix it in `lua/config/completion.lua`
  (research R6) and repeat. Confirm afterwards that the real `nvim-pack-lock.json` lists only
  `mini.notify` and `mini.completion`

**Checkpoint**: All user stories verified.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T013 Run lua_ls diagnostics on `lua/config/completion.lua` and `lua/config/options.lua`
  (`lua-language-server --check lua/config`) and fix errors/warnings (`MiniCompletion` is a
  plugin global: suppress `undefined-global` only if lua_ls reports it, with a comment); check
  `.editorconfig` style (80 columns, trailing separators)
- [X] T014 Edge cases (spec): open `:help`, a terminal (`:terminal`, Insert mode) and the
  command-line window (`q:`) and type a few words: no errors; stop the server (`:lsp stop`)
  while typing in a Lua buffer: no errors, buffer words still offered
- [X] T015 Regression checks against T001: headless start/quit prints nothing (exit 0); startup
  < 100 ms and within ~1 ms of the baseline (plugin is lazy, research R5); normal-mode keymap
  count unchanged; Insert-mode count differs only by the plugin's mappings; `:checkhealth`
  shows no new errors
- [X] T016 Commit in focused Conventional Commits: `feat: complete with mini.completion`
  (T002–T006, plugin justification in the body), `docs: document mini.completion completion`
  (T008–T009), and `docs: add spec, plan and tasks for mini.completion` (this feature's
  `specs/010-mini-completion/`)

---

## Dependencies & Execution Order

- **Setup (T001)** → **Foundational (T002)** → **US1 (T003–T004)** → **US2 (T005–T007)** →
  **US3 verification (T010)** and **US4 (T011–T012)** → **Polish (T013–T016)**.
- T002 (options.lua) can be written in parallel with T003 (different file), but T004 verifies
  both.
- T008 and T009 (README) depend only on the design docs; they can run any time, in parallel
  with code work, but one after the other (same file).
- US2 code (T005–T006) edits the file written in T003, so it follows T003.
- US4 depends on T003 (lazy `vim.pack.add`).

### Parallel Opportunities

```text
# Alongside T003 (completion.lua):
T002 options.lua
T008 README Completion section → T009 README Plugins/Popups (same file, sequential)
```

## Implementation Strategy

1. **MVP**: T001–T004 — completion comes from mini.completion; custom triggers gone.
2. **Increment 2**: T005–T007 — familiar keys restored on top of the plugin.
3. **Increment 3**: T008–T010 — docs match, no leftovers.
4. **Increment 4**: T011–T012 — fresh-install and failure paths proven.
5. **Finish**: T013–T016 — style, edge cases, regressions, commits.
