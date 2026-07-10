## ADDED Requirements

### Requirement: mini.completion setup location
The system SHALL configure `mini.completion` (part of `mini.nvim`) entirely within
`plugin/60-mini.lua`. All `mini.nvim` module configuration SHALL live in that file.

#### Scenario: Adding another mini.nvim module later
- **WHEN** a new `mini.nvim` module (e.g. `mini.pairs`) is configured in the future
- **THEN** its setup is added to `plugin/60-mini.lua`, not scattered across other `plugin/*.lua`
  files

### Requirement: LSP-only completion source
The system SHALL source completion candidates only from the attached LSP client. Buffer-based
fallback completion (Vim's built-in keyword completion, `mini.completion`'s default
`fallback_action`) SHALL be disabled in any buffer that has an LSP client with completion support
attached, and SHALL remain available (the default `<C-n>` fallback) in buffers with no such
client attached.

#### Scenario: Requesting completion in a buffer with an attached LSP client
- **WHEN** the user triggers completion (automatically or via `<C-Space>`) in a buffer where an
  LSP client supporting `textDocument/completion` is attached, and the LSP returns zero matches
- **THEN** no buffer-based (keyword) completion candidates are shown as a fallback

#### Scenario: Requesting completion in a buffer with no LSP client
- **WHEN** the user triggers completion in a buffer with no LSP client attached (or the attached
  client does not support completion)
- **THEN** buffer-based keyword completion runs as the fallback and its candidates are shown

### Requirement: No snippet expansion
The system SHALL NOT expand LSP snippet-format completion items into editable tabstop templates.
Confirming a snippet-format item SHALL insert its plain text (label/filter text) as-is, with no
snippet engine invoked.

#### Scenario: Confirming a snippet-format completion item
- **WHEN** the user confirms a completion item whose LSP `insertTextFormat` is `Snippet`
- **THEN** the plain completion text is inserted and no snippet tabstops or placeholders are
  activated

### Requirement: Popup navigation with Tab and Shift-Tab
The system SHALL, in insert mode, move the completion popup selection to the next item on `<Tab>`
and the previous item on `<Shift-Tab>` when the popup is visible. When the popup is not visible,
`<Tab>` and `<Shift-Tab>` SHALL retain their normal (non-completion) insert-mode behavior.

#### Scenario: Popup is visible
- **WHEN** the completion popup is visible and the user presses `<Tab>` (or `<Shift-Tab>`)
- **THEN** the selection moves to the next (or previous) item in the popup

#### Scenario: Popup is not visible
- **WHEN** the completion popup is not visible and the user presses `<Tab>` (or `<Shift-Tab>`)
- **THEN** the key behaves as ordinary `<Tab>`/`<Shift-Tab>` insert-mode input, unaffected by
  completion

### Requirement: Confirmation with Enter
The system SHALL, in insert mode, confirm the currently selected completion popup entry when
`<Enter>` is pressed while the popup is visible and an item is selected. When the popup is not
visible, or is visible with no item selected, `<Enter>` SHALL behave as ordinary `<CR>`.

#### Scenario: An item is selected and Enter is pressed
- **WHEN** the completion popup is visible with an item selected and the user presses `<Enter>`
- **THEN** the selected item is inserted and the popup closes

#### Scenario: No item is selected and Enter is pressed
- **WHEN** the completion popup is visible with no item selected and the user presses `<Enter>`
- **THEN** a normal line break is inserted, as if completion were not active

### Requirement: Automatic and forced triggering
The system SHALL trigger completion automatically as the user types in insert mode. The user
SHALL also be able to force a completion request on demand with `<C-Space>`.

#### Scenario: Typing in insert mode
- **WHEN** the user types in insert mode within a buffer where completion is available
- **THEN** the completion popup appears automatically after a short delay, without requiring an
  explicit trigger key

#### Scenario: Forcing completion
- **WHEN** the user presses `<C-Space>` in insert mode
- **THEN** a completion request is issued immediately, regardless of the automatic-trigger delay

### Requirement: Preselect only a sole match
The system SHALL NOT preselect any completion popup entry by default. The sole exception: when
exactly one candidate matches the current filter, that candidate SHALL be auto-selected so that
`<Enter>` confirms it immediately without requiring explicit navigation.

#### Scenario: Multiple candidates match
- **WHEN** the completion popup shows two or more matching candidates
- **THEN** none of them is selected by default

#### Scenario: Exactly one candidate matches
- **WHEN** the completion popup's candidate list narrows to exactly one matching item (whether
  at the moment it first appears or after further filtering while typing)
- **THEN** that item becomes selected automatically, without the user pressing `<Tab>`/`<C-n>`
