---

description: "Task list for Prominent Diagnostic Popup"
---

# Tasks: Prominent Diagnostic Popup

**Input**: Design documents from `/specs/004-diagnostic-popup-border/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/popup-style.md,
quickstart.md

**Tests**: No automated test suite was requested. Each story ends with a verification task that
runs the matching steps from `quickstart.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and
testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- Include exact file paths in descriptions

## Path Conventions

Neovim config directory at repository root; all edits are in existing `lua/config/*.lua`
modules (see plan.md "Project Structure"). All Lua follows `.editorconfig` (2-space indent,
80 columns, double quotes, trailing table separators, explicit call parentheses). No key
mapping is added, removed or changed (FR-009). No new module, augroup or plugin.

---

## Phase 1: Setup (Shared Infrastructure)

No setup needed: every change goes into an existing module that `init.lua` already loads.

---

## Phase 2: Foundational (Blocking Prerequisites)

No foundational work: US1 and US2 edit different files and do not depend on each other.

---

## Phase 3: User Story 1 - Bordered popups (Priority: P1) 🎯 MVP

**Goal**: Every floating popup, including the diagnostic popup, has a clearly visible rounded
border in both dark and light mode (FR-001 – FR-003, FR-007, FR-010)

**Independent Test**: quickstart.md §2 and §4. `<C-w>d` on a line with a diagnostic, and `K`
for hover, both show a full blue rounded border. A float opened with `border = "none"` stays
borderless.

- [X] T001 [P] [US1] In `lua/config/options.lua`, add `vim.opt.winborder = "rounded"` with a
  short comment, in its own small section after "Visual aids". The comment says that it is the
  default border for floats that do not set their own and uses plain Unicode, not Nerd Font
  glyphs. See data-model.md Popup border `'winborder'` and research R1
- [X] T002 [P] [US1] In `lua/config/colorscheme.lua`, extend the existing `ColorScheme`
  autocommand callback in augroup `config_transparency`. After the transparency loop, resolve
  `FloatTitle` and `NormalFloat` with `vim.api.nvim_get_hl(0, { name = ..., link = false, })`.
  If `FloatTitle` has an `fg`, set `FloatBorder` to `{ fg = <title fg>, bg = <float bg>, }`,
  where `bg` is omitted when `NormalFloat` has none. Otherwise leave `FloatBorder` untouched.
  Add a comment explaining why: catppuccin draws the border almost in the background colour.
  Update the file's header comment so it covers the float border colour. See data-model.md
  Popup border colour `FloatBorder.fg` and `FloatBorder.bg`, and research R2. Keep the
  augroup name `config_transparency` (renaming it is out of scope); its header comment
  states that the group also adjusts the float border colour
- [X] T003 [US1] Verify US1 with quickstart.md §1, §2 and §4. Also check headlessly that
  `FloatBorder` resolves to `#89b4fa` (dark) and `#1e66f5` (light) under the bundled
  catppuccin (data-model.md Popup border colour). Includes the signature-help check in
  quickstart.md §4 (SC-005). Depends on T001 and T002

**Checkpoint**: All popups are bordered and visible; US1 is shippable on its own.

---

## Phase 4: User Story 2 - Easier-to-read diagnostic popup (Priority: P2)

**Goal**: The diagnostic popup shows a centred title, the source of each entry, and
severity-coloured entries (FR-004 – FR-006, FR-008)

**Independent Test**: quickstart.md §3. `<C-w>d` shows `Diagnostics` in the top border, with no
in-body header. Entries with a source are prefixed by it, entries without a source have no
`nil`, and the colours match the signs.

- [X] T004 [P] [US2] In `lua/config/diagnostics.lua` `M.setup()`, extend the existing
  `vim.diagnostic.config({ ... })` call with
  `float = { title = " Diagnostics ", header = "", source = true, }`.
  - Keep `virtual_text = true, virtual_lines = false` unchanged.
  - Keep the call inside `M.setup()`, so `vim.diagnostic` still does not load at startup.
  - Update the module's header comment to mention the popup style.
  - Do not touch the toggles.
  - See data-model.md Diagnostic popup style `float.title`, `float.header` and
    `float.source`, plus research R3. Severity colour needs no code.
- [X] T005 [US2] Verify US2 with quickstart.md §3 and §5. This includes checking that
  `<leader>td/tt/tl` behave as before and leave `vim.diagnostic.config().float` intact.
  Depends on T004

**Checkpoint**: US1 and US2 both work; the feature is complete.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [X] T006 Run quickstart.md §1 and §6 on the final tree:
  - `nvim --headless "+qa"` is silent.
  - Startup is < 100 ms, and `vim.diagnostic` is not loaded at startup.
  - `:checkhealth` shows no new errors.
  - `lua/config/options.lua`, `lua/config/colorscheme.lua` and `lua/config/diagnostics.lua`
    have 0 `lua_ls` diagnostics and are unchanged by `<leader>lf`.
- [X] T007 Confirm that `README.md` needs no change: there is no new dependency or key mapping.
  If the README describes popups or the colour scheme, add one line noting that floats are
  bordered

---

## Dependencies & Execution Order

- **US1 (T001–T003)** and **US2 (T004–T005)** are independent and touch different files.
  Either can ship alone. US2's border comes from US1, so without US1 its title has no frame
  to sit on, but nothing breaks.
- T003 depends on T001 and T002; T005 depends on T004.
- Polish (T006–T007) runs after the stories that are being shipped.

## Parallel Example

```text
# All three code edits touch different files and can be made at once:
T001 lua/config/options.lua      (winborder)
T002 lua/config/colorscheme.lua  (FloatBorder colour)
T004 lua/config/diagnostics.lua  (float title/header/source)
# Then verify: T003, T005, T006
```

## Implementation Strategy

- **MVP**: Phase 3 (US1). This delivers what was literally asked: a visible border. Verify,
  then commit (`feat: add visible border to floating windows`).
- **Increment**: Phase 4 (US2), then verify and commit
  (`feat: add title and source to diagnostic popup`). Alternatively, commit both together as
  one small `feat:` if preferred.
- Finish with Phase 5 before the final commit.
