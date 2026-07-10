## Context

`plugin/60-mini.lua` already has expr-mappings for `<Tab>`, `<S-Tab>`, and `<CR>` that branch on
`vim.fn.pumvisible()`. Native Vim ins-completion distinguishes `<C-e>` (stop completion, revert to
originally-typed text) from most other keys, including `<Esc>` (stop completion, keep the current
match) — `<Esc>` then also exits insert mode as usual. That mismatch is the bug: users expect
`<Esc>` to be a clean cancel.

## Goals / Non-Goals

**Goals:**
- `<Esc>` while the popup is visible reverts any inserted candidate text and exits insert mode,
  matching the mental model of "cancel."

**Non-Goals:**
- No change to `<C-e>`'s existing (already correct) revert behavior.
- No change to Tab/Shift-Tab/Enter/`<C-Space>` behavior.

## Decisions

- Add a fourth expr-mapping, `imap("<Esc>", ...)`, following the same `pumvisible()`-branching
  pattern as the existing mappings: when the popup is visible, return `"<C-e><Esc>"` (revert, then
  exit insert mode); otherwise return plain `"<Esc>"`.
  - Alternative considered: use `<C-y>`-style manual text deletion. Rejected — `<C-e>` is the
    built-in, exact-semantics primitive for "revert completion," so composing it with `<Esc>` is
    simpler and avoids reimplementing revert logic.

## Risks / Trade-offs

- [Risk] `<C-e>` when the popup is visible but no candidate text has actually been inserted yet
  (e.g., popup just opened, nothing selected) is a no-op, so `<C-e><Esc>` is safe to send
  unconditionally whenever `pumvisible()` is true → Mitigation: none needed, this is standard Vim
  behavior.
