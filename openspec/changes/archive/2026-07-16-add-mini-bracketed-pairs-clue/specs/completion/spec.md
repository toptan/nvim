## MODIFIED Requirements

### Requirement: Confirmation with Enter

The system SHALL, in insert mode, confirm the currently selected completion popup entry when
`<Enter>` is pressed while the popup is visible and an item is selected. When the popup is not
visible, or is visible with no item selected, `<Enter>` SHALL fall through to `mini.pairs`' smart
`<CR>` handling (see the `auto-pairs` capability), which itself inserts an ordinary line break
when no auto-inserted pair applies.

#### Scenario: An item is selected and Enter is pressed

- **WHEN** the completion popup is visible with an item selected and the user presses `<Enter>`
- **THEN** the selected item is inserted and the popup closes

#### Scenario: No item is selected and Enter is pressed, cursor inside an empty pair

- **WHEN** the completion popup is not visible (or visible with no item selected), the cursor is
  between an auto-inserted empty bracket pair, and the user presses `<Enter>`
- **THEN** `mini.pairs` splits the pair across two lines, as if completion were not active

#### Scenario: No item is selected and Enter is pressed, cursor not inside any pair

- **WHEN** the completion popup is not visible (or visible with no item selected), the cursor is
  not inside any auto-inserted pair, and the user presses `<Enter>`
- **THEN** a normal line break is inserted, as if completion were not active
