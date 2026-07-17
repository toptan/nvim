## Purpose

Defines the general-purpose keymaps set in `plugin/20-keymaps.lua` that are not owned by a
specific plugin or LSP feature, and the leader-key group-description table
(`Config.leader_group_clues`) other tooling reads to label `<Leader>` prefixes.

## Requirements

### Requirement: Leader key
The system SHALL set both `mapleader` and `maplocalleader` to `<Space>` (in `init.lua`, before any
keymap is defined).

#### Scenario: Pressing space in normal mode
- **WHEN** the user presses `<Space>` in normal mode followed by a mapped leader sequence
- **THEN** the corresponding leader keymap is triggered

### Requirement: Leader group descriptions

The system SHALL expose a table, `Config.leader_group_clues`, describing the purpose of each
`<Leader>` prefix in normal and visual mode (`b` Buffer, `c` Code, `e` Explore/Edit, `f` Find,
`g` Git, `l` Language, `m` Map, `o` Other, `s` Session, `t` Toggle, `v` Visits), for consumption by
`mini.clue` (configured in `plugin/60-mini.lua`, see the `keybinding-clues` capability).

#### Scenario: Opening the leader-key popup
- **WHEN** `mini.clue` reads `Config.leader_group_clues` and the user presses `<Leader>` and waits
- **THEN** the popup shows the configured group description for each prefix key

### Requirement: Search-highlight clearing
The system SHALL clear search highlighting when `<Esc>` is pressed in normal mode.

#### Scenario: Dismissing a search
- **WHEN** the user has an active search highlight and presses `<Esc>` in normal mode
- **THEN** the search highlight is cleared

### Requirement: Register-preserving delete and paste
The system SHALL delete a single character with `x` in normal mode, and replace a visual
selection with `p`, without overwriting the unnamed/yank register (both routed through the black
hole register `"_`).

#### Scenario: Deleting a character with x
- **WHEN** the user presses `x` in normal mode
- **THEN** the character under the cursor is deleted without changing the contents of the unnamed
  register

#### Scenario: Pasting over a visual selection
- **WHEN** the user has previously yanked text, selects other text in visual mode, and presses `p`
- **THEN** the selection is replaced by the previously yanked text, and the unnamed register still
  holds that same previously yanked text (not the replaced selection)

### Requirement: Window-focus navigation
The system SHALL move focus between splits with `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` in normal mode.

#### Scenario: Moving focus to an adjacent split
- **WHEN** the user presses `<C-h>`, `<C-j>`, `<C-k>`, or `<C-l>` in normal mode with multiple
  windows open
- **THEN** focus moves to the window in the corresponding direction

### Requirement: Buffer cycling
The system SHALL cycle to the next buffer with `<Tab>` and the previous buffer with `<S-Tab>` in
normal mode.

#### Scenario: Cycling buffers
- **WHEN** multiple buffers are listed and the user presses `<Tab>` (or `<S-Tab>`) in normal mode
- **THEN** the next (or previous) buffer becomes active

### Requirement: Indent-preserving visual re-indent
The system SHALL re-select the visual selection after indenting with `<` or `>` in visual mode, so
repeated indent presses do not require re-selecting.

#### Scenario: Indenting a visual selection repeatedly
- **WHEN** the user selects lines in visual mode and presses `>` (or `<`) more than once in a row
- **THEN** the selection remains active after each press, allowing further indent/outdent without
  reselecting

### Requirement: Move line/selection up or down
The system SHALL move the current line (normal mode) or selection (visual mode) up or down with
`<M-j>`/`<M-k>` and the equivalent `<A-j>`/`<A-k>`, in normal, visual, and insert mode, and
re-indent the moved line(s).

#### Scenario: Moving a line down in normal mode
- **WHEN** the user presses `<M-j>` (or `<A-j>`) in normal mode
- **THEN** the current line moves one line down and is re-indented

#### Scenario: Moving a visual selection up
- **WHEN** the user selects multiple lines in visual mode and presses `<M-k>` (or `<A-k>`)
- **THEN** the selection moves one line up, remains selected, and is re-indented

#### Scenario: Moving the current line from insert mode
- **WHEN** the user is in insert mode and presses `<M-j>` (or `<A-j>`)
- **THEN** the current line moves down, is re-indented, and insert mode is resumed at the same
  column

### Requirement: Fold-level toggle
The system SHALL toggle all folds open/closed with `<Leader>tf` in normal mode, by switching
`foldlevel` between `0` and `99`.

#### Scenario: Toggling folds closed
- **WHEN** `foldlevel` is currently non-zero and the user presses `<Leader>tf`
- **THEN** `foldlevel` becomes `0`, collapsing folds to their top level

#### Scenario: Toggling folds back open
- **WHEN** `foldlevel` is currently `0` and the user presses `<Leader>tf`
- **THEN** `foldlevel` becomes `99`, effectively opening all folds

### Requirement: Code-lens toggle
The system SHALL toggle LSP code lenses on/off with `<Leader>tl` in normal mode.

#### Scenario: Toggling code lenses
- **WHEN** the user presses `<Leader>tl`
- **THEN** LSP code lens display is enabled if it was disabled, or disabled if it was enabled
