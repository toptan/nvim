# Research: Search, Yank Feedback and Buffer Navigation

All findings verified against Neovim 0.12.6 (`nvim --clean --headless`) on 2026-11-19.

## R1 — Search options (FR-001, FR-002, FR-003)

- **Decision**: In `config.options` set `incsearch = false`, `ignorecase = true`,
  `smartcase = true`; leave `hlsearch` at its default (`true`).
- **Rationale**: Core options give exactly the requested behaviour. `smartcase` only applies to
  typed patterns; `*`/`#` stay case-insensitive per `ignorecase`, which matches the spec's
  "smart case" for typed searches.
- **Alternatives considered**: Per-search `\c`/`\C` — rejected as manual.

## R2 — Clearing highlights with Escape (FR-004)

- **Decision**: Normal-mode `<Esc>` mapped to a function that runs `:nohlsearch` and clears the
  position label.
- **Rationale**: `:nohlsearch` hides highlights but keeps the last pattern; `n`/`N` turn them
  back on automatically. Mapping `<Esc>` in normal mode doesn't touch insert, visual or
  operator-pending Escape. It's silent when there is no highlight.
- **Alternatives considered**: `<Esc>` → `<cmd>nohlsearch<CR><Esc>` — rejected because a bare
  `<Esc>` in normal mode can ring the bell.

## R3 — Position label source (FR-005, FR-009)

- **Decision**: Use `vim.fn.searchcount({ recompute = true, maxcount = 999, timeout = 100 })`.
  Show the label only when `exact_match == 1` (cursor is on a match) and `total > 0`.
  Formatting: `[current/total]`. When `incomplete == 2` (more than `maxcount`), show the total as
  `>999` (and current as `>999` if it exceeds the cap). When `incomplete == 1` (timed out), show
  `[?/?]`.
- **Rationale**: Built in, honours `ignorecase`/`smartcase` and search offsets, and is bounded
  by `maxcount`/`timeout`, which satisfies FR-009. `exact_match` was confirmed to exist and
  avoids a second `searchpos()` call. `exact_match` is 1 anywhere inside the match
  (verified), so `/pat/e` still gets a label.
- **Alternatives considered**: Counting with `vim.regex` over all lines — rejected (slower, no
  timeout, duplicates core). Plugin `nvim-hlslens` — rejected (Principle I: core suffices).

## R4 — Label rendering (FR-005, FR-008; clarification: right-aligned)

- **Decision**: One extmark in a dedicated namespace with
  `virt_text = { { label, "SearchCountLabel" } }` and `virt_text_pos = "right_align"` on the
  match's line. `SearchCountLabel` is defined with `default = true` and linked to `Comment`,
  so users or colour schemes can override it.
- **Rationale**: Virtual text never changes buffer content and is not yanked (FR-008).
  `right_align` matches the clarified placement. The extmark moves with its line when text
  shifts.
- **Alternatives considered**: `eol` / `inline` positions — rejected per the clarification.

## R5 — When to show/refresh the label (FR-005, FR-006)

- **Decision**:
  - `n`, `N`, `*`, `#`, `g*`, `g#` in normal mode: `expr` mappings that return the original
    key and `vim.schedule` a label refresh. Counts, search offsets, wrap messages and E486
    errors therefore behave exactly as before.
  - `/` and `?`: a `CmdlineLeave` autocommand for cmdtype `/` or `?` (not aborted) schedules a
    refresh. The cursor has moved by the time the scheduled callback runs.
  - Each refresh first removes any existing label (in any buffer), so only one label exists at
    a time.
- **Rationale**: Neovim has no "search jumped" event. Wrapping the keys with `expr` keeps the
  original behaviour, and `vim.schedule` runs after the motion.
- **Alternatives considered**: `CursorMoved` polling — rejected because it fires for every
  motion. FR-007 also says the label must *not* move with ordinary motions.

## R6 — When to remove the label (FR-007)

- **Decision**: Remove the label on:
  - `<Esc>` (R2).
  - `CmdlineLeave` for cmdtype `:` when `v:hlsearch` becomes 0 after the command; checked in a
    scheduled callback. This covers a typed `:nohlsearch`/`:noh`.
  - `TextChanged` / `TextChangedI` in the labelled buffer.
  - `BufLeave` of the labelled buffer.

  Ordinary cursor motions do nothing (clarification Q2).
- **Rationale**: Covers every removal event in the spec with core autocommands only.
- **Alternatives considered**: `OptionSet hlsearch` — doesn't fire for `:nohlsearch`, which
  doesn't change the option.

## R7 — Built-in command-line search count

- **Decision**: Add `S` to `shortmess` so the built-in `[3/7]` in the command line is hidden.
- **Rationale**: The new label already shows the same information; showing it twice is noise.
- **Alternatives considered**: Keep both — harmless, but redundant. Easy to revert by removing
  the flag.

## R8 — Buffer cycling (FR-010–FR-012a)

- **Decision**: Use a small Lua function instead of `:bnext`/`:bprevious`.
  - Candidates: buffers with `buflisted == true` and `buftype == ""` (normal file buffers),
    ordered by buffer number. Buffer numbers are assigned when a buffer is opened, so this is
    the fixed open order (clarification Q3).
  - Find the next/previous candidate after the current buffer number, wrapping around, and
    switch with `vim.cmd.buffer(n)`.
  - With fewer than two candidates, and the current buffer among them, do nothing.
  - From a special buffer (help, quickfix), go to the nearest candidate in that direction.
- **Rationale**: Verified that `:bnext` visits the quickfix buffer (it is listed) and terminal
  buffers. The spec requires skipping both. The filter is about 15 lines and needs no plugin.
- **Alternatives considered**: `:bnext` — rejected (visits quickfix/terminal). Bufferline
  plugins — rejected (Principle I).
- **Ctrl+I**: Mapping `<Tab>` in normal mode also replaces `<C-i>` in terminals. Accepted per
  clarification Q1; `<C-o>` is untouched and jump-forward gets no replacement key (FR-012a).

## R9 — Yank highlight (FR-013)

- **Decision**: A `TextYankPost` autocommand calling `vim.hl.on_yank()` with defaults
  (`IncSearch` group, 150 ms).
- **Rationale**: `vim.hl.on_yank` (Neovim 0.11+) only acts on yank operators, so deletes and
  changes are ignored. 150 ms is within the 150–300 ms range in the spec's assumptions.
- **Alternatives considered**: Deprecated `vim.highlight.on_yank` — rejected because it will be
  removed.

## R10 — Line-number width (FR-014)

- **Decision**: `numberwidth = 6`.
- **Rationale**: `numberwidth` counts the separating space, so 6 = 5 digits + 1 space. The
  column stays the same width up to 99 999 lines with both `number` and `relativenumber` on.

## R11 — Module layout and startup (Principles II, III)

- **Decision**:
  - `config.options` gets the new options (R1, R7, R10).
  - New `config.search` owns the label, the search-key wrappers and `<Esc>`.
  - New `config.keymaps` owns `<Tab>`/`<S-Tab>`.
  - New `config.autocmds` owns the yank highlight.
  - All are loaded from `init.lua` after `config.options`.
- **Rationale**: One concern per module. The search label, its triggers and its clearing
  key form one tightly related group. Keymaps and a few autocommands are first-buffer
  essentials and cost well under 1 ms. The label code only runs on search keys, so nothing
  heavy happens at startup.
