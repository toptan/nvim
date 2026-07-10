## Why

Pressing `<Esc>` while the completion popup is visible currently leaves the selected candidate's
text inserted in the buffer before exiting insert mode. Native Vim ins-completion treats a plain
`<Esc>` as "stop completion, keep the current match" (only `<C-e>` explicitly reverts to what was
typed before completion started), which is surprising here: `<Esc>` is expected to cancel, not
confirm.

## What Changes

- Add an insert-mode `<Esc>` mapping in `plugin/60-mini.lua`: when the completion popup is
  visible, revert to the originally-typed text (equivalent to `<C-e>`) before exiting insert mode.
  When the popup is not visible, `<Esc>` behaves as ordinary `<Esc>`.

## Capabilities

### Modified Capabilities
- `completion`: adds a requirement that cancelling completion with `<Esc>` reverts any inserted
  candidate text back to what the user had typed, rather than leaving the selected match inserted.

## Impact

- `plugin/60-mini.lua`: one new insert-mode `<Esc>` mapping, alongside the existing
  Tab/Shift-Tab/Enter mappings.
- `openspec/specs/completion/spec.md`: one new requirement (via delta spec) describing
  cancel-reverts-text behavior for `<Esc>`.
