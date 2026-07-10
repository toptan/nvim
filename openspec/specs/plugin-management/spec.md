## Purpose

Defines how plugins are declared, pinned, and configured (`plugin/50-plugins.lua`,
`nvim-pack-lock.json`), using Neovim's native `vim.pack` package manager rather than a third-party
plugin manager.

## Requirements

### Requirement: Native plugin declaration
The system SHALL declare plugins via `vim.pack.add({...})` (native Neovim package management), with
no third-party plugin-manager dependency (e.g. lazy.nvim, packer).

#### Scenario: Adding a new plugin
- **WHEN** a new plugin git URL is added to a `vim.pack.add({...})` call in
  `plugin/50-plugins.lua`
- **THEN** Neovim installs and loads it on next startup via its native `vim.pack` mechanism, and
  its resolved revision is recorded in `nvim-pack-lock.json`

### Requirement: Pinned plugin revisions
The system SHALL record the exact installed revision and source URL of every plugin in
`nvim-pack-lock.json`, keyed by plugin name.

#### Scenario: Inspecting installed plugin versions
- **WHEN** a user reads `nvim-pack-lock.json`
- **THEN** each entry lists the plugin's `src` (git URL) and pinned `rev` (commit SHA)

### Requirement: Code formatting via conform.nvim
The system SHALL format buffers using `conform.nvim`, with Lua files formatted by `stylua` and
CMake files formatted by `gersemi`, LSP-based formatting used as a fallback when no dedicated
formatter is configured for the filetype, and manual formatting bound to `<Leader>cf`.

#### Scenario: Formatting a Lua buffer
- **WHEN** the user presses `<Leader>cf` in a `.lua` buffer and `stylua` is available
- **THEN** the buffer is formatted with `stylua`

#### Scenario: Formatting a buffer with no dedicated formatter
- **WHEN** the user presses `<Leader>cf` in a buffer whose filetype has no entry in
  `formatters_by_ft` and the attached LSP client supports formatting
- **THEN** the buffer is formatted using the LSP server's formatting capability

### Requirement: Tree-sitter parser installation
The system SHALL install Tree-sitter parsers for a configured list of languages
(`plugin/50-plugins.lua`'s `languages` table) that are not already present, on startup.

#### Scenario: Adding a new language to the list
- **WHEN** a language is added to the `languages` table and Neovim is restarted
- **THEN** the parser for that language is installed automatically if not already present, and
  Tree-sitter highlighting/parsing becomes available for its filetypes once installation
  completes

### Requirement: Automatic Tree-sitter start per filetype
The system SHALL start Tree-sitter highlighting automatically for any filetype mapped to a
language in the configured `languages` list, on `FileType`.

#### Scenario: Opening a file with a configured language
- **WHEN** the user opens a file whose filetype maps to a language in the `languages` list
- **THEN** `vim.treesitter.start()` runs for that buffer automatically

### Requirement: Tree-sitter parser auto-update
The system SHALL run `:TSUpdate` automatically when `nvim-treesitter` itself is updated via
`vim.pack` (using `Config.on_packchanged`).

#### Scenario: Updating the nvim-treesitter plugin
- **WHEN** `vim.pack` reports an `update` `PackChanged` event for `nvim-treesitter`
- **THEN** `:TSUpdate` runs automatically to refresh installed parsers
