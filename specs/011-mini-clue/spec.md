# Feature Specification: Next-Key Clues via mini.clue

**Feature Branch**: `master` (no feature branch)

**Created**: 2026-11-22

**Status**: Implemented

**Input**: User description: "Add `mini.clue` plugin to show next key clues. When it comes to
triggers and clues they should match ones given in quick-start here:
https://nvim-mini.org/mini.nvim/readmes/mini-clue.html#config-quick-start"

## Overview

Many editor commands are multi-key sequences (`<Leader>…`, `g…`, `z…`, `[…`, `]…`, `<C-w>…`,
marks, registers, Insert-mode `<C-x>…`). Today, after pressing the first key of such a
sequence, nothing tells the user which keys may follow. This feature adds the `mini.clue`
plugin, installed through the editor's built-in plugin manager (as `mini.notify` and
`mini.completion` were in features 009 and 010), so that a small window listing the possible
next keys and what they do appears after a short pause. The set of trigger keys and the clue
descriptions MUST be exactly those of the plugin's published "Config quick start", plus the
two `<Leader>` group names the quick start invites (`<Leader>l` Language, `<Leader>t` Toggle).

## Clarifications

### Session 2026-11-22

- Q: Should `<Leader>` group names be added, as the quick start's comment invites? → A: Yes,
  for now only two: `<Leader>l` named "Language" and `<Leader>t` named "Toggle".
- Q: Should the group names apply in Normal mode only, or in Visual mode too? → A: Both
  Normal and Visual mode, matching the `<Leader>` trigger's modes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See what keys can follow (Priority: P1)

As the editor's sole user, when I press the first key of a multi-key sequence and hesitate, I
want a window to list every key that can follow and what it does, so that I can discover and
recall commands without leaving the editor to look them up.

**Why this priority**: This is the whole point of the feature.

**Independent Test**: In Normal mode press `g` and wait; a window opens listing next keys such
as `g` (go to first line), `v` and `i` with descriptions. Press `<Esc>`; the window closes and
nothing else happens.

**Acceptance Scenarios**:

1. **Given** Normal mode, **When** I press a trigger key (e.g. `g`, `z`, `[`, `]`, `<C-w>`,
   `'`, `` ` ``, `"` or `<Leader>`) and pause for the plugin's default delay, **Then** a window
   lists the possible next keys with a description for each.
2. **Given** the clue window is open, **When** I press one of the listed keys, **Then** that
   command runs exactly as it would without the plugin, or, if the key starts a longer
   sequence, the window updates to show the next level.
3. **Given** I press a trigger key, **When** I type the rest of the sequence before the delay
   passes, **Then** the command runs and no window ever appears.
4. **Given** the clue window is open, **When** I press `<Esc>`, **Then** the window closes and
   no command runs.
5. **Given** the clue window is open, **When** I press `<BS>`, **Then** the last key of the
   pending sequence is removed and the window shows the clues for the shorter sequence.

---

### User Story 2 - Clues in Visual, Insert and Command-line modes (Priority: P1)

As the user, I want the same help in the other modes the quick start covers: `<Leader>`, `g`,
`z`, marks and registers in Visual mode; built-in completion (`<C-x>`) and registers (`<C-r>`)
in Insert mode; and registers (`<C-r>`) on the command line.

**Why this priority**: The quick start defines these triggers; the request is to match it.

**Independent Test**: In Insert mode press `<C-r>` and wait; a window lists the registers with
their contents. On the `:` command line, `<C-r>` does the same. In Insert mode, `<C-x>` lists
the built-in completion sub-modes.

**Acceptance Scenarios**:

1. **Given** Visual mode, **When** I press `<Leader>`, `g`, `z`, `'`, `` ` `` or `"` and pause,
   **Then** the clue window lists the next keys valid in Visual mode.
2. **Given** Insert mode, **When** I press `<C-x>` and pause, **Then** the clue window lists
   the built-in completion sub-modes with descriptions.
3. **Given** Insert mode or the command line, **When** I press `<C-r>` and pause, **Then** the
   clue window lists the registers, and choosing one inserts its contents as without the plugin.

---

### User Story 3 - My own mappings appear too (Priority: P2)

As the user, I want mappings I define (for example `<Leader>lf`, format buffer) to appear in
the clue window with their descriptions, so that the clues reflect my configuration and not
only built-in commands.

**Why this priority**: Useful, but the built-in clues already deliver most of the value.

**Independent Test**: Press `<Leader>` in Normal mode and wait; the window lists `l` as the
"Language" group; pressing `l` shows `f` with the description "Format buffer" (or whatever
the existing mapping's description is).

**Acceptance Scenarios**:

1. **Given** a user mapping under a trigger key with a description, **When** the clue window
   for that trigger is shown, **Then** the mapping appears with its description.
2. **Given** Normal or Visual mode, **When** I press `<Leader>` and pause, **Then** `l` is
   listed as
   "Language" and `t` as "Toggle" (group names), not as unnamed prefixes.
3. **Given** a mapping created only for one buffer (e.g. when a language server attaches),
   **When** I press its trigger in that buffer, **Then** the clue window still opens and the
   mapping is listed and works.

---

### User Story 4 - Plugin installs itself and never breaks the editor (Priority: P2)

As the user setting up a new machine, I want the plugin installed automatically the first time
the editor starts, and if it cannot be installed I want the editor to keep working with plain
key sequences.

**Why this priority**: Required by the constitution (Principle IV), but only matters on first
start or on failure.

**Independent Test**: Remove the plugin's installed copy, start the editor with network access;
the plugin is installed and clues work in the same session. Then block network access and
remove it again; the editor starts, shows a single non-blocking notice, and `gg`, `zz`, `<C-w>v`
work as normal.

**Acceptance Scenarios**:

1. **Given** a fresh clone with network access, **When** the editor starts, **Then** the plugin
   is installed without prompts and clues work in the same session.
2. **Given** the plugin cannot be installed or loaded, **When** the editor starts, **Then**
   there are no errors, at most one non-blocking notice says clues are unavailable, and every
   key sequence still works.

### Edge Cases

- Macro recording: triggers are disabled while recording (a documented plugin limitation);
  key sequences typed during recording still work and are recorded correctly.
- Count and register prefixes (`3gg`, `"ayy`, `2<C-w>>`): commands behave exactly as without
  the plugin.
- Operator-pending sequences (e.g. `dgg`, `yiw`): unaffected, since no operator-pending
  triggers are defined by the quick start.
- `<Leader>` with no user mappings beneath a key: the window lists only what exists; no errors.
- `<Leader>l` or `<Leader>t` in Visual mode, where no mappings exist yet: the group name is
  shown, pressing its key raises no errors, and Visual mode is not left in a broken state.
- Existing Normal-mode mappings `<Tab>`, `<S-Tab>` and `<Esc>` are not triggers and keep their
  current behaviour.
- Insert-mode completion from feature 010 (`<Tab>`, `<S-Tab>`, `<CR>`, `<C-Space>`) is not
  affected; `<C-x>` and `<C-r>` behave as before apart from the clue window.
- Special buffers (help, quickfix, command-line window, file pickers, terminal): no errors are
  raised when a trigger key is pressed.
- Headless runs (no screen): starting and quitting produce no errors or messages.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After the first key(s) of a multi-key sequence starting with a trigger key, a clue
  window MUST list every valid next key with its description, after the plugin's default delay.
- **FR-002**: The trigger keys MUST be exactly those of the quick start: `<Leader>` (Normal,
  Visual); `[` and `]` (Normal); `<C-x>` (Insert); `g` (Normal, Visual); `'` and `` ` ``
  (Normal, Visual); `"` (Normal, Visual); `<C-r>` (Insert, Command-line); `<C-w>` (Normal);
  `z` (Normal, Visual). No other triggers MAY be added.
- **FR-003**: The clue sets MUST be exactly those of the quick start: square brackets,
  built-in completion, `g`, marks, registers, windows and `z`. No other clue sets MAY be added.
- **FR-003a**: Exactly two `<Leader>` group names MUST be added, in both Normal and Visual
  mode: `<Leader>l` "Language" and `<Leader>t` "Toggle", shown with the plugin's `+` group
  marker (`+Language`, `+Toggle`). No other custom clues or group names MAY be added.
- **FR-004**: Every key sequence MUST produce the same result with the plugin as without it,
  whether or not the clue window was shown.
- **FR-005**: User mappings under a trigger key MUST appear in the clue window with their
  descriptions, including mappings local to a buffer.
- **FR-006**: The plugin MUST use its default settings apart from triggers and clues; any other
  overridden option MUST be justified beside it.
- **FR-007**: The plugin MUST be installed and managed by the editor's built-in plugin manager
  (`vim.pack`); no third-party plugin manager MAY be introduced.
- **FR-008**: If the plugin is missing or fails to load, the editor MUST start without errors,
  with at most one non-blocking notice, and all key sequences MUST keep working.
- **FR-009**: The plugin MUST carry a one-line justification stating what core Neovim lacks
  (Constitution Principle I).
- **FR-010**: The README MUST describe the clue window, list the plugin and its triggers.
- **FR-011**: Starting the editor headlessly and quitting MUST still produce no errors, and
  startup time on an empty buffer MUST stay under 100 ms.

### Key Entities

- **Trigger**: a key (or keys) in one or more modes that, when pressed, starts showing clues.
- **Clue**: a next key and its description, coming from the plugin's built-in clue sets or from
  a mapping's description.
- **Clue window**: the floating window listing the clues for the keys pressed so far.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: For each of the 18 trigger/mode combinations in FR-002, pressing the trigger and
  pausing opens the clue window in 100% of attempts, within the plugin's default delay plus
  half a second.
- **SC-002**: 0 key sequences behave differently with the plugin than without it (checked on a
  sample covering every trigger: e.g. `gg`, `zz`, `]d`, `<C-w>v`, `'a`, `"ayy`, `<C-r>a`,
  `<C-x><C-n>`, `<Leader>lf`).
- **SC-003**: The configured triggers and clue sets match the quick start one-to-one, and
  exactly the two group names of FR-003a are present: 0 missing, 0 extra.
- **SC-004**: On a fresh clone, clues work with 0 manual steps beyond starting the editor with
  network access.
- **SC-005**: With the plugin unavailable, the editor starts with 0 errors.
- **SC-006**: Headless start/quit produces 0 messages with the plugin installed, and startup
  time on an empty buffer stays under 100 ms.

## Assumptions

- The user has explicitly chosen `mini.clue`; following features 009 and 010, it is installed
  as the standalone module with the editor's built-in plugin manager. These named technologies
  are constraints of the request, not implementation choices left open.
- "Match the quick start" means the same triggers in the same modes and the same built-in clue
  sets. The quick start's comment inviting descriptions for `<Leader>` groups is acted on with
  two group names only (`<Leader>l` Language, `<Leader>t` Toggle); more may follow later.
- The group names apply in Normal and Visual mode, the same modes as the `<Leader>` trigger.
  Today every `<Leader>l…` and `<Leader>t…` mapping (`<Leader>lf`; `<Leader>td`,
  `<Leader>tt`, `<Leader>tl`) is Normal-mode only, so in Visual mode the two groups are listed
  by name but have no keys beneath them until Visual-mode mappings are added.
- Plugin defaults are accepted for everything else: clue window delay (1 second), window look
  and placement, scroll keys and sorting.
- `'timeoutlen'` is left unchanged; the plugin's key query does not depend on it.
- Because triggers act on the first key press, the plugin is loaded at startup rather than on
  a later event; it adds about 1.5 ms, well within the 100 ms budget (Constitution Principle
  III; measured during planning, where deferring it to the first screen saved nothing).
- Leader is `<Space>` (set in the options module); this is unchanged.
- Only the clue part of the `mini` family is added; no other modules are enabled.
- The plugin is tracked at its default (latest) version; the machine-local lockfile stays
  uncommitted.
- Justification for the plugin (Principle I): core Neovim has no way to show which keys may
  follow a partially typed key sequence; it only waits silently for `'timeoutlen'`.
