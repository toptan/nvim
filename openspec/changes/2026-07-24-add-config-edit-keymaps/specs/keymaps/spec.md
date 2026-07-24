## ADDED Requirements

### Requirement: Quick edit access to this config's own files

The system SHALL provide, in normal mode, one `<Leader>e`-prefixed keymap per config entry point
that opens that file for editing via `:edit`, resolved against `vim.fn.stdpath("config")`:
`<Leader>ei` → `init.lua`, `<Leader>eo` → `plugin/10-options.lua`, `<Leader>ek` →
`plugin/20-keymaps.lua`, `<Leader>ea` → `plugin/30-autocmds.lua`, `<Leader>el` →
`plugin/40-lsp.lua`, `<Leader>ep` → `plugin/50-plugins.lua`, `<Leader>em` →
`plugin/60-mini.lua`.

#### Scenario: Editing init.lua

- **WHEN** the user presses `<Leader>ei`
- **THEN** `init.lua` (under `vim.fn.stdpath("config")`) opens in the current window

#### Scenario: Editing a numbered plugin file

- **WHEN** the user presses one of `<Leader>eo`, `<Leader>ek`, `<Leader>ea`, `<Leader>el`,
  `<Leader>ep`, or `<Leader>em`
- **THEN** the corresponding `plugin/NN-*.lua` file (under `vim.fn.stdpath("config")`) opens in the
  current window
