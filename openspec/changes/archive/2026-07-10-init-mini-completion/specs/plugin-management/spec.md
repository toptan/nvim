## MODIFIED Requirements

### Requirement: Native plugin declaration
The system SHALL declare plugins via `vim.pack.add({...})` (native Neovim package management), with
no third-party plugin-manager dependency (e.g. lazy.nvim, packer). `mini.nvim` module
configuration (e.g. `mini.completion`) SHALL be declared and configured in `plugin/60-mini.lua`,
separate from other plugins configured in `plugin/50-plugins.lua`.

#### Scenario: Adding a new plugin
- **WHEN** a new plugin git URL is added to a `vim.pack.add({...})` call in
  `plugin/50-plugins.lua`
- **THEN** Neovim installs and loads it on next startup via its native `vim.pack` mechanism, and
  its resolved revision is recorded in `nvim-pack-lock.json`

#### Scenario: Adding a new mini.nvim module
- **WHEN** a new `mini.nvim` module is configured in the future
- **THEN** it is added via `vim.pack.add` and set up in `plugin/60-mini.lua`, not in
  `plugin/50-plugins.lua`
