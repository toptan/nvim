## ADDED Requirements

### Requirement: Cancellation with Escape reverts inserted text

The system SHALL, in insert mode, revert any completion-inserted text back to what the user
originally typed when `<Esc>` is pressed while the completion popup is visible, before exiting
insert mode. When the popup is not visible, `<Esc>` SHALL behave as ordinary `<Esc>`.

#### Scenario: Popup visible with a selected candidate and Escape is pressed
- **WHEN** the completion popup is visible, a candidate is selected (its text is currently
  inserted in the buffer), and the user presses `<Esc>`
- **THEN** the buffer text reverts to what the user had typed before the candidate was selected,
  the popup closes, and insert mode exits

#### Scenario: Popup not visible and Escape is pressed
- **WHEN** the completion popup is not visible and the user presses `<Esc>`
- **THEN** the key behaves as ordinary `<Esc>`, unaffected by completion
