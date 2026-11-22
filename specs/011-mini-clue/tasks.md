---

description: "Task list for Next-Key Clues via mini.clue"
---

# Tasks: Next-Key Clues via mini.clue

**Input**: Design documents from `/specs/011-mini-clue/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/clue.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching scenarios from `quickstart.md`. Drive the TUI with tmux
(`tmux -L <name> new-session -d -x 120 -y 40 "nvim -n <file>"`, `send-keys`, `capture-pane`);
`-n` avoids swap-file prompts that swallow keys after a killed session. Send each key with a
short pause (≥ 0.3 s) between `send-keys` calls: keys sent in one burst can complete a sequence
before the 1 s clue delay, which is correct behaviour but hides the window. tmux pitfalls from
feature 010: a lone `;` argument is a tmux command separator (send `'\;'`); Shift-Tab is `BTab`.

**Isolation rule**: any run with a modified copy of the config MUST override all four of
`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` together, and any run
of the real config MUST unset all four. Mixing them lets `vim.pack` write entries for the wrong
plugin set into the real `nvim-pack-lock.json`.

**Verification note (implementation)**: T001–T013 were run against the real config in a
tmux-driven TUI (Lua with lua_ls). Startup median 10.2 ms → 12.0 ms (+1.8 ms); global
keymaps n 68 / x 23 / i 7 / c 0 before and after (triggers are buffer-local: n 9, x 6, i 2,
c 1); `:checkhealth` errors 0 → 0; lua_ls: 0 diagnostics in `lua/config/clue.lua` and
`init.lua`. Deviations: (1) the planning prototype redirected data and state but not
`XDG_CONFIG_HOME`, so `vim.pack` added `mini.clue` to the real lockfile; T001's headless run
then installed it (at the planned `7e27c16`) and printed install progress once; later runs were
silent. This is the pitfall the Isolation rule describes. (2) On Neovim 0.12 LSP's `gO` is a
global mapping (only `K` is buffer-local, and it is not under a trigger), so T004 checked
FR-005 with a temporary buffer-local `gZ` mapping instead: listed in the `g` window (after
`<C-d>` scroll) and run through the trigger. (3) `<BS>` on a lone trigger key ends the query
and closes the window, which is the plugin's behaviour for an empty sequence. (4) The `lua_ls`
CLI (`--check`) does not load the Neovim runtime and reports `vim` as undefined everywhere;
diagnostics were taken from lua_ls attached inside Neovim instead.

**Organization**: Tasks are grouped by user story. The whole feature is one setup table in one
module, so code tasks are sequential; README work can run in parallel with verification.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Include exact file paths in descriptions

## Path Conventions

The Neovim config directory is the repository root; modules live in `lua/config/`. Lua follows
`.editorconfig`: 2-space indent, 80 columns, double quotes, trailing table separators, explicit
call parentheses. No global defined by the config (`MiniClue` is the plugin's own).

---

## Phase 1: Setup

**Purpose**: Confirm the starting point.

- [X] T001 Record baselines from the repo root (real config, `XDG_*` unset): `nvim --headless "+qa"`
  (expect no output); five runs of `nvim --headless --startuptime <scratch>/before-N.log +qa`
  (note the median `NVIM STARTED` time, ~10–12 ms expected); Normal / Visual / Insert /
  Command-line global keymap counts via
  `nvim --headless "+lua for _, m in ipairs({'n','x','i','c'}) do print(m, #vim.api.nvim_get_keymap(m)) end" +qa`;
  `:checkhealth` error count; contents of `nvim-pack-lock.json` (expect only `mini.notify` and
  `mini.completion`). For comparison in T013

---

## Phase 2: Foundational

**Purpose**: None. The module created in US1 is the only shared piece and is small enough to
belong to that story.

---

## Phase 3: User Story 1 - See what keys can follow (Priority: P1) 🎯 MVP

**Goal**: The plugin is installed and set up with the quick-start triggers and clue sets; a
window lists next keys after a pause; sequences behave as before.

**Independent Test**: quickstart.md scenarios 2, 3, 8, 9, 10, 14, 15, 16, 17.

- [X] T002 [US1] Create `lua/config/clue.lua` (pattern: `lua/config/notifications.lua`) that:
  (1) has a header comment describing the behaviour (mini.clue shows the keys that may follow a
  trigger key after a pause; quick-start triggers and clues; loaded at startup because the
  triggers must exist before the first key, research R2) and the Principle I justification
  "core Neovim cannot show which keys may follow a partially typed key sequence; it only waits
  for 'timeoutlen'" (research R6); (2) `pcall`s
  `vim.pack.add({ "https://github.com/nvim-mini/mini.clue", }, { confirm = false, })`
  (per `data-model.md` `Plugin spec.Source`, `Plugin spec.Version` (no version),
  `Plugin spec.Installed by`; research R1); (3) only on success, `pcall`s a function that does
  `local miniclue = require("mini.clue")` and `miniclue.setup({ triggers = {...}, clues = {...}, })`
  with `triggers` exactly the 11 entries of `data-model.md` `Trigger` (same order and comment
  groups as the quick start: Leader, `[`/`]`, built-in completion, `g`, marks, registers,
  window commands, `z`) and `clues` exactly the seven `miniclue.gen_clues.*()` calls of
  `data-model.md` `Clue` (square_brackets, builtin_completion, g, marks, registers, windows,
  z); no other options (`data-model.md` `Other options`: plugin defaults); (4) on failure,
  `vim.schedule`s one
  `vim.notify("mini.clue unavailable: no key clues", vim.log.levels.WARN)` (one short line so it
  never asks for Enter, as in `config.notifications`); (5) returns an empty module table
  `local M = {}` … `return M`. The two `<Leader>` group names are added in T007
- [X] T003 [US1] In `init.lua`, add `require("config.clue")` as the last line, with a short
  comment that load order does not matter (the plugin reads mappings when a trigger is
  pressed, research R5) and it is last only to keep plugin modules together (plan Source Code)
- [X] T004 [US1] Verify US1 in a tmux-driven TUI with the real config on `lua/config/keymaps.lua`
  (quickstart.md 2, 3, 8, 9, 10, 14–17): the first start installs `mini.clue` with no prompt;
  `g` + 1.5 s shows the `g` window (incl. `+LSP` once lua_ls has attached); confirm with
  `:lua =vim.fn.maparg("gO", "n", false, true).buffer` that LSP's `gO` is a buffer-local
  mapping (non-zero), that it is listed as `O` in the `g` window, and that `g` then `O` opens
  the document symbols list (US3 scenario 3, FR-005); `gg` sent in one
  burst jumps to the top with no window; `g` then `<Esc>` closes the window and nothing runs;
  `<C-w>` then `<BS>` drops the key, then `<C-w>v` splits; `[`, `]`, `z`, `'`, `` ` ``, `"` each
  open their window in Normal mode (SC-001); `3gg`, `"ayy`, `2<C-w>>` (after `<C-w>v`), `zz`,
  `]d`, `ma` then `'a`, and `g*` (counter shown) behave as without the plugin (SC-002);
  operator-pending sequences `dgg` (then `u`) and `yiw` (then `:echo @"`) work and show no
  window (spec Edge Cases); recording `qa` `gg` `q` and `@a` works; feature 010 Insert
  completion (`vim.` + `<Tab>`, `<CR>`) is unchanged; a trigger in `:help`, `:copen`,
  `:terminal` (Normal mode) and the command-line window (`q:`) raises no error

**Checkpoint**: Clues work for every Normal-mode trigger; MVP reached.

---

## Phase 4: User Story 2 - Clues in Visual, Insert and Command-line modes (Priority: P1)

**Goal**: The non-Normal triggers from the quick start work. Already configured by T002
(`data-model.md` `Trigger` modes `x`, `i`, `c`); this phase verifies them.

**Independent Test**: quickstart.md scenarios 6 (triggers part), 10 (Visual), 11, 12, 13.

- [X] T005 [US2] Verify US2 in tmux (quickstart.md 10–13): in Visual mode (`v`), `g`, `z`, `'`,
  `` ` `` and `"` each open their window and `<Esc>` leaves Visual mode intact; in Insert mode
  `<C-r>` + 1.5 s lists registers and `"` inserts the unnamed register; `<C-x>` + 1.5 s lists
  completion sub-modes and `<C-n>` runs keyword completion; on the `:` command line `<C-r>` +
  1.5 s lists registers. Confirm all 18 mode/key pairs of `data-model.md` `Trigger` are
  buffer-local trigger mappings in the current buffer:
  `:lua for _, m in ipairs({"n","x","i","c"}) do print(m, #vim.tbl_filter(function(k) return (k.desc or ""):find("^Query keys") end, vim.api.nvim_buf_get_keymap(0, m))) end`
  prints n 9, x 6, i 2, c 1 (18 in all) — adjust the expected counts only if the
  plugin documents a different mapping scheme, and record why (SC-001, SC-003)

**Checkpoint**: All 18 trigger/mode pairs verified.

---

## Phase 5: User Story 3 - My own mappings appear too (Priority: P2)

**Goal**: User mappings appear with their descriptions; `<Leader>l` and `<Leader>t` are named
"Language" and "Toggle" in Normal and Visual mode (FR-003a).

**Independent Test**: quickstart.md scenarios 4, 5, 6, 7.

- [X] T006 [US3] Before T007, in tmux, press `<Space>` in Normal mode and wait: note that `l` and
  `t` appear as unnamed groups (`+1`, `+3` or similar), to compare with T008
- [X] T007 [US3] In `lua/config/clue.lua`, add at the top of `clues` (before the
  `gen_clues` calls, with a comment "`<Leader>` groups") the two entries of `data-model.md`
  `Clue` marked custom: `{ mode = { "n", "x", }, keys = "<Leader>l", desc = "+Language", }` and
  `{ mode = { "n", "x", }, keys = "<Leader>t", desc = "+Toggle", }` (the `+` marks a group, as
  in the plugin's own clues; research R3). Replace the quick start's "Enhance this…" comment
  with this one; add nothing else (FR-003a)
- [X] T008 [US3] Verify US3 in tmux (quickstart.md 4–7): Normal `<Space>` + 1.5 s shows
  `l  +Language` and `t  +Toggle`; then `l` shows `f  Format buffer` (window title
  `+Language`); `<Space>t` shows the `d`, `t`, `l` toggles with their descriptions; Visual
  `<Space>` + 1.5 s shows the same two groups; Visual `<Space>l` raises no error and stays in
  Visual mode (keys fall through, research R4); in a `CMakeLists.txt` buffer `<Space>l` still
  lists `f` (the global `<leader>lf` covers gersemi); in a Lua buffer, indent a line wrongly,
  then `<Space>`, pause, `l`, pause, `f`: the buffer is formatted exactly as `<Space>lf`
  typed quickly does (SC-002)

**Checkpoint**: Clue window reflects the user's own mappings and groups.

---

## Phase 6: User Story 4 - Plugin installs itself and never breaks the editor (Priority: P2)

**Goal**: Zero-step install and graceful degradation.

**Independent Test**: quickstart.md scenarios 1 and 18.

- [X] T009 [US4] Verify fresh install: move `~/.local/share/nvim/site/pack/core/opt/mini.clue`
  to a scratch location, start `nvim` on a Lua file (real config, `XDG_*` unset); the plugin
  installs without a prompt and `g` + 1.5 s shows clues in the same session; `:checkhealth
  vim.pack` lists `mini.clue` without errors. Delete the moved copy (SC-004)
- [X] T010 [US4] Verify fault tolerance in an isolated copy (all four `XDG_*` overridden, see
  Isolation rule): change the URL in the copy's `lua/config/clue.lua` to a non-existent
  repository, start `nvim` in a real TUI: no "Press ENTER" prompt, no stack trace, exactly one
  WARN notice; `gg`, `zz`, `<C-w>v`, `<Space>lf` work as plain mappings (SC-005). If a prompt
  appears, fix it in `lua/config/clue.lua` and repeat. Confirm afterwards that the real
  `nvim-pack-lock.json` lists only `mini.notify`, `mini.completion` and `mini.clue`

**Checkpoint**: All user stories verified.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T011 [P] Add a "Key clues" section to `README.md` (after "Key mappings", before
  "Completion") per `contracts/clue.md`: after a trigger key and a 1 s pause a window lists the
  keys that may follow; table of triggers and modes (`<Leader>` Normal/Visual; `[` `]` Normal;
  `g` `z` `'` `` ` `` `"` Normal/Visual; `<C-w>` Normal; `<C-x>` Insert; `<C-r>`
  Insert/Command-line); `<Leader>` groups `l` Language and `t` Toggle; keys in the window
  (`<BS>` back, `<Esc>` cancel, `<C-d>`/`<C-u>` scroll); note that typing a sequence quickly
  never shows the window and that clues are off while recording a macro. Leave "Key mappings"
  ("Normal mode only") as is: the config itself adds no mappings
- [X] T012 [P] In `README.md` "Plugins" list, add
  [`mini.clue`](https://github.com/nvim-mini/mini.clue) with its one-line reason (Neovim cannot
  show which keys may follow a partially typed key sequence) and the fallback note (without
  network on the first start the install fails with a notice and keys work as in stock
  Neovim). Same file as T011: do them one after the other
- [X] T013 Final checks against T001 baselines (real config, `XDG_*` unset): `nvim --headless "+qa"`
  prints nothing; median of five `--startuptime` runs stays under 100 ms (expect about
  +1.5 ms, research R2) (SC-006, FR-011); global keymap counts unchanged (trigger mappings
  are buffer-local); `:checkhealth` errors not increased; lua_ls reports 0 diagnostics for
  `lua/config/clue.lua` and `init.lua` (e.g. `lua-language-server --check lua/config/clue.lua`
  or `:lua =vim.diagnostic.get()` after opening it); `lua/config/clue.lua` lines ≤ 80
  columns; `grep -o "keys =" lua/config/clue.lua | wc -l` equals 13 (11 triggers + 2 groups)
  and `grep -o "gen_clues\." lua/config/clue.lua | wc -l` equals 7 (match counts, not line
  counts, so entries sharing a line are still counted) (SC-003)
- [X] T014 Mark T001–T013 done in `specs/011-mini-clue/tasks.md` and add a short
  "Verification note (implementation)" under the Isolation rule with measured startup, keymap
  counts, health and any deviations; set the spec **Status** to `Implemented` in
  `specs/011-mini-clue/spec.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (T001)**: first; baselines must precede any change.
- **US1 (T002–T004)**: after T001. T002 → T003 → T004.
- **US2 (T005)**: after T003 (verification only; no code).
- **US3 (T006–T008)**: T006 after T003; T007 after T006 (same file as T002); T008 after T007.
- **US4 (T009–T010)**: after T003; T010 after T007 so the copy has the final module.
- **Polish**: T011, T012 any time after T002 (README only); T013 after all code tasks
  (T002, T003, T007); T014 last.

### User Story Dependencies

```text
T001 ─▶ US1 (T002 ─▶ T003 ─▶ T004)
                     ├─▶ US2 (T005)
                     ├─▶ US3 (T006 ─▶ T007 ─▶ T008)
                     └─▶ US4 (T009; T010 after T007)
T011 ─▶ T012 (README, parallel with US2–US4) ─▶ T013 ─▶ T014
```

### Parallel Opportunities

- T011/T012 (`README.md`) can run while US2–US4 verifications run (they touch no code).
- T005 (US2) and T009 (US4) are read-only verifications and can run back to back in the same
  tmux session; T010 uses an isolated copy and does not interfere with the real config.
- T002 and T007 edit the same file and must not run in parallel.

### Parallel Example: after T003

```text
Session A (tmux, real config):  T004 → T005 → T006 → (T007) → T008 → T009
Session B (editor):             T011 → T012
Session C (isolated XDG copy):  T010 (after T007)
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. T001 baselines.
2. T002–T003: module and `init.lua` line; the quick-start config is complete at this point.
3. T004: verify Normal-mode triggers. Stop here for a working MVP: clues everywhere the quick
   start defines them, without the `<Leader>` group names.

### Incremental Delivery

1. MVP (US1) → commit `feat: show next-key clues with mini.clue`.
2. US2 verification (no code).
3. US3 group names (T007) → commit `feat: name <Leader> clue groups`.
4. US4 verification; README (T011–T012) → commit `docs: document mini.clue key clues`.
5. T013–T014 → commit `docs: add spec, plan and tasks for mini.clue`.
