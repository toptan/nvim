## Purpose

Defines general-purpose autocommands not tied to LSP or plugin setup (`plugin/30-autocmds.lua`),
and the shared helpers in `init.lua` used to register autocommands consistently across the
configuration.

## Requirements

### Requirement: Shared autocommand helper
The system SHALL expose `Config.new_autocmd(event, pattern, callback, desc)` as the standard way
to register an autocommand, which attaches it to a single shared augroup (`custom-config`) so
autocommands defined across different files do not need to manage their own augroups.

#### Scenario: Registering an autocommand via the helper
- **WHEN** any configuration file calls `Config.new_autocmd(event, pattern, callback, desc)`
- **THEN** the autocommand is created under the `custom-config` augroup with the given event,
  pattern, callback, and description

### Requirement: Plugin-update reaction helper
The system SHALL expose `Config.on_packchanged(plugin_name, kinds, callback, desc)`, which reacts
to `vim.pack`'s `PackChanged` event for a specific plugin and set of change kinds, ensures the
plugin is loaded (`packadd`) if it was not active, and then invokes the callback.

#### Scenario: A tracked plugin is updated
- **WHEN** `vim.pack` reports a `PackChanged` event for a plugin registered via
  `Config.on_packchanged`, with a `kind` in the registered set
- **THEN** the plugin is loaded if inactive, and the registered callback runs

### Requirement: Yank highlight
The system SHALL briefly highlight the yanked text region whenever text is yanked, using
`vim.hl.on_yank()` on the `TextYankPost` event.

#### Scenario: Yanking a region of text
- **WHEN** the user yanks (copies) any text in any buffer
- **THEN** the yanked region is briefly highlighted
