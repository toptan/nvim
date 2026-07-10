## 1. Implementation

- [ ] 1.1 Add an `<Esc>` insert-mode expr-mapping in `plugin/60-mini.lua`, alongside the existing
  `<Tab>`/`<S-Tab>`/`<CR>` mappings: return `"<C-e><Esc>"` when `pumvisible() == 1`, else `"<Esc>"`.

## 2. Verification

- [ ] 2.1 Manually (or via headless RPC) verify: trigger completion, navigate to select a
  candidate so its text is inserted, press `<Esc>`, and confirm the buffer reverts to the
  originally-typed text and insert mode exits.
- [ ] 2.2 Verify `<Esc>` with the popup not visible still behaves as ordinary `<Esc>`.
- [ ] 2.3 Verify `<Esc>` when the popup is visible but nothing is selected (multi-match, no
  preselect) still cleanly cancels with no unexpected text change.

## 3. Finalize

- [ ] 3.1 Update `openspec/specs/completion/spec.md` via archive once implementation is verified.
