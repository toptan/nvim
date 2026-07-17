## ADDED Requirements

### Requirement: mini.pick default fuzzy finder

The system SHALL provide fuzzy-finding via `mini.pick` (part of `mini.nvim`, configured in
`plugin/60-mini.lua`) with its default configuration: default in-picker mappings (`<CR>` choose,
`<Esc>` stop, `<C-n>`/`<C-p>` move, etc.), and the auto-created `:Pick` user command.

#### Scenario: Using the :Pick command directly

- **WHEN** the user runs `:Pick files` (or any other registered picker name)
- **THEN** the corresponding picker opens using `mini.pick`'s default window and mappings

### Requirement: Keymaps for all builtin pickers under the Find group

The system SHALL provide a normal-mode keymap for each of `mini.pick`'s seven builtin pickers,
under the existing `<Leader>f` "+Find" group:
- `<Leader>ff` opens `files`
- `<Leader>fg` opens `grep_live`
- `<Leader>fG` opens `grep`
- `<Leader>fb` opens `buffers`
- `<Leader>fh` opens `help`
- `<Leader>fr` opens `resume`
- `<Leader>fc` opens `cli`

#### Scenario: Finding files

- **WHEN** the user presses `<Leader>ff`
- **THEN** the `files` picker opens, listing files under the current working directory

#### Scenario: Live grep

- **WHEN** the user presses `<Leader>fg` and types a search pattern
- **THEN** the `grep_live` picker updates matches interactively as the pattern is typed

#### Scenario: Prompted grep

- **WHEN** the user presses `<Leader>fG`
- **THEN** the user is prompted once for a search pattern, then the `grep` picker shows all matches
  for that fixed pattern

#### Scenario: Finding buffers

- **WHEN** the user presses `<Leader>fb`
- **THEN** the `buffers` picker opens, listing currently open buffers

#### Scenario: Finding help tags

- **WHEN** the user presses `<Leader>fh`
- **THEN** the `help` picker opens, listing available help tags

#### Scenario: Resuming the last picker

- **WHEN** a picker was previously opened and closed, and the user presses `<Leader>fr`
- **THEN** that same picker re-opens with its previous query and position

#### Scenario: Picking from CLI output

- **WHEN** the user presses `<Leader>fc`
- **THEN** the `cli` picker opens, prompting for a shell command and listing its output as items
