## ADDED Requirements

### Requirement: Toggle explorer anchored on the Neovim config directory

The system SHALL toggle the `mini.files` explorer with `<Leader>ec` in normal mode, anchored on
`vim.fn.stdpath("config")` (this Neovim config's directory), using the same toggle behavior as the
existing `-`/`<Leader>ed` keymaps.

#### Scenario: Opening the explorer on the config directory

- **WHEN** the explorer is closed and the user presses `<Leader>ec`
- **THEN** the explorer opens showing the contents of `vim.fn.stdpath("config")`

#### Scenario: Closing the explorer

- **WHEN** the explorer is open (with no pending unsaved file-system actions) and the user presses
  `<Leader>ec`
- **THEN** the explorer closes
