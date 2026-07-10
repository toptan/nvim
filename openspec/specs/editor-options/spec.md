## Purpose

Defines the baseline `vim.opt` editor settings applied on startup (`plugin/10-options.lua`),
independent of any plugin.

## Requirements

### Requirement: Core editing options
The system SHALL configure Neovim on startup with: true-color support, absolute + relative line
numbers (width 5), hidden mode indicator (`showmode=false`), indent-aware line wrapping
(`breakindent`), persistent undo (`undofile`), case-insensitive search that becomes case-sensitive
when the pattern contains an uppercase letter (`ignorecase`+`smartcase`), an always-shown sign
column, `updatetime=250`, `timeoutlen=500`, right/below split placement, visible whitespace
(tabs as `» `, trailing space as `·`, nbsp as `␣`), inline substitution preview
(`inccommand=split`), cursorline highlighting, a color column at 80, a scroll offset of 10 lines,
spaces-for-tabs indentation (`expandtab`, `shiftwidth=4`, `tabstop=4`), and folds open by default
(`foldlevel=99`).

#### Scenario: Opening any buffer
- **WHEN** Neovim starts and a buffer is displayed
- **THEN** line numbers (absolute + relative), the sign column, cursorline, and the column-80
  guide are all visible, and whitespace characters render per `listchars`

#### Scenario: Searching with a lowercase pattern
- **WHEN** the user searches for a pattern containing only lowercase letters
- **THEN** the search ignores case

#### Scenario: Searching with an uppercase letter present
- **WHEN** the user searches for a pattern containing at least one uppercase letter
- **THEN** the search is case-sensitive

### Requirement: System clipboard integration
The system SHALL synchronize the unnamed register with the system clipboard
(`vim.opt.clipboard = "unnamedplus"`), deferred via `vim.schedule` so startup is not blocked
waiting on a clipboard provider.

#### Scenario: Yanking text
- **WHEN** the user yanks text in any buffer after startup has completed
- **THEN** the yanked text is also placed on the system clipboard

### Requirement: Disabled language providers
The system SHALL disable the Ruby, Node, Perl, and Python3 providers (set in `init.lua`) since no
plugin in this configuration depends on them, avoiding provider health-check warnings and startup
cost.

#### Scenario: Running `:checkhealth provider`
- **WHEN** the user runs `:checkhealth provider`
- **THEN** Ruby, Node, Perl, and Python3 providers are reported as disabled, not as missing/broken
