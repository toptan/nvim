# notifications Specification

## Purpose
TBD - created by archiving change add-mini-ai-surround-bufremove-notify-trailspace. Update Purpose after archive.

## Requirements

### Requirement: mini.notify as the vim.notify backend

The system SHALL render all `vim.notify` calls (including LSP progress notifications) through
`mini.notify` (part of `mini.nvim`, configured in `plugin/60-mini.lua`), by setting `vim.notify =
require("mini.notify").make_notify()`, with `mini.notify`'s default configuration otherwise
unchanged (including `lsp_progress.enable = true`).

#### Scenario: A plugin or LSP server emits a notification

- **WHEN** any code path calls `vim.notify(...)`, or an attached LSP server reports progress
- **THEN** the notification renders as a `mini.notify` floating window instead of the default
  `:messages`-only echo

### Requirement: Notification history popup

The system SHALL show a history of past notifications with `<Leader>on` in normal mode, via
`mini.notify`'s `show_history()`.

#### Scenario: Reviewing past notifications

- **WHEN** one or more notifications have already been shown and the user presses `<Leader>on`
- **THEN** a buffer/window listing prior notifications, most recent included, is displayed
