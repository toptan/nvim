## ADDED Requirements

### Requirement: mini.extra pickers enabled

The system SHALL enable `mini.extra`'s pickers (part of `mini.nvim`, configured in
`plugin/60-mini.lua`) via `require("mini.extra").setup()` with no options, registering all of
`mini.extra`'s pickers with `mini.pick`'s auto-created `:Pick` user command.

#### Scenario: Using a mini.extra picker via :Pick directly

- **WHEN** the user runs `:Pick <name>` for any `mini.extra` picker name (e.g. `:Pick oldfiles`,
  `:Pick git_files scope='modified'`)
- **THEN** the corresponding picker opens using `mini.pick`'s default window and mappings

### Requirement: Keymaps for general mini.extra pickers under the Find group

The system SHALL provide a normal-mode keymap for each of the following `mini.extra` pickers,
under the existing `<Leader>f` "+Find" group, each called with no non-default `local_opts`:
- `<Leader>fd` opens `diagnostic`
- `<Leader>fe` opens `explorer`
- `<Leader>fk` opens `keymaps`
- `<Leader>fl` opens `buf_lines`
- `<Leader>fm` opens `manpages`
- `<Leader>fM` opens `marks`
- `<Leader>fo` opens `oldfiles`
- `<Leader>fO` opens `options`
- `<Leader>fR` opens `registers`
- `<Leader>fs` opens `spellsuggest`
- `<Leader>fT` opens `colorschemes`
- `<Leader>fx` opens `hl_groups`
- `<Leader>fy` opens `history`
- `<Leader>fC` opens `commands`
- `<Leader>ft` opens `treesitter`

#### Scenario: Finding diagnostics across the workspace

- **WHEN** the user presses `<Leader>fd`
- **THEN** the `diagnostic` picker opens, listing all diagnostics sorted by severity

#### Scenario: Browsing the file system with the picker explorer

- **WHEN** the user presses `<Leader>fe`
- **THEN** the `explorer` picker opens rooted at the current working directory; choosing a
  directory navigates inside it, choosing a file opens it

#### Scenario: Finding keymaps

- **WHEN** the user presses `<Leader>fk`
- **THEN** the `keymaps` picker opens, listing Neovim's active keymaps

#### Scenario: Searching lines in open buffers

- **WHEN** the user presses `<Leader>fl`
- **THEN** the `buf_lines` picker opens, listing lines from all normal listed buffers

#### Scenario: Finding a manual page

- **WHEN** the user presses `<Leader>fm`
- **THEN** the `manpages` picker opens, listing available manual pages

#### Scenario: Jumping to a mark

- **WHEN** the user presses `<Leader>fM`
- **THEN** the `marks` picker opens, listing all marks (global and buffer-local)

#### Scenario: Reopening a recently edited file

- **WHEN** the user presses `<Leader>fo`
- **THEN** the `oldfiles` picker opens, listing recently opened files

#### Scenario: Finding a Neovim option

- **WHEN** the user presses `<Leader>fO`
- **THEN** the `options` picker opens, listing Neovim options and their current values

#### Scenario: Finding a register's contents

- **WHEN** the user presses `<Leader>fR`
- **THEN** the `registers` picker opens, listing register contents

#### Scenario: Getting a spelling suggestion

- **WHEN** the cursor is on a misspelled word and the user presses `<Leader>fs`
- **THEN** the `spellsuggest` picker opens, listing suggested corrections

#### Scenario: Previewing and applying a colorscheme

- **WHEN** the user presses `<Leader>fT`
- **THEN** the `colorschemes` picker opens; moving the selection previews that colorscheme live,
  and canceling restores the colorscheme active before the picker opened

#### Scenario: Finding a highlight group

- **WHEN** the user presses `<Leader>fx`
- **THEN** the `hl_groups` picker opens, listing highlight groups colored with themselves

#### Scenario: Searching command/search history

- **WHEN** the user presses `<Leader>fy`
- **THEN** the `history` picker opens, listing all `:history` entries across scopes

#### Scenario: Finding a Neovim command

- **WHEN** the user presses `<Leader>fC`
- **THEN** the `commands` picker opens, listing built-in and user-defined commands

#### Scenario: Finding a Tree-sitter node

- **WHEN** the user presses `<Leader>ft`
- **THEN** the `treesitter` picker opens, listing Tree-sitter nodes in the current buffer

### Requirement: Keymaps for Git pickers under the Git group

The system SHALL provide a normal-mode keymap for each of the following `mini.extra` Git pickers,
under the existing `<Leader>g` "+Git" group, each called with no non-default `local_opts`:
- `<Leader>gb` opens `git_branches`
- `<Leader>gc` opens `git_commits`
- `<Leader>gf` opens `git_files`
- `<Leader>gh` opens `git_hunks`

#### Scenario: Finding a Git branch

- **WHEN** the user presses `<Leader>gb` inside a Git repository
- **THEN** the `git_branches` picker opens, listing all local and remote branches; choosing one
  shows its commit history

#### Scenario: Finding a Git commit

- **WHEN** the user presses `<Leader>gc` inside a Git repository
- **THEN** the `git_commits` picker opens, listing commits from the repository; choosing one shows
  its diff

#### Scenario: Finding a tracked Git file

- **WHEN** the user presses `<Leader>gf` inside a Git repository
- **THEN** the `git_files` picker opens, listing tracked files (`git ls-files --cached`)

#### Scenario: Reviewing unstaged Git hunks

- **WHEN** the user presses `<Leader>gh` inside a Git repository with unstaged changes
- **THEN** the `git_hunks` picker opens, listing unstaged hunks; choosing one navigates to that
  hunk's first change
