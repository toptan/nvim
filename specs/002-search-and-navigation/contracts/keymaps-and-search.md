# Contract: Keymaps and Search Behaviour

What the user, and later features, can rely on once this feature is in place.

## Normal-mode key mappings

| Key | Effect | `desc` |
|-----|--------|--------|
| `<Esc>` | Clear search highlights and the position label | `Clear search highlights` |
| `<Tab>` | Next file buffer (open order, wraps) | `Next buffer` |
| `<S-Tab>` | Previous file buffer (open order, wraps) | `Previous buffer` |
| `n` | Original behaviour, then refresh the position label | `Next search match` |
| `N` | Original behaviour, then refresh the position label | `Previous search match` |
| `*` | Original behaviour, then refresh the position label | `Search word forward` |
| `#` | Original behaviour, then refresh the position label | `Search word backward` |
| `g*` | Original behaviour, then refresh the position label | `Search partial word forward` |
| `g#` | Original behaviour, then refresh the position label | `Search partial word backward` |

- Only normal mode is mapped. Insert, visual and operator-pending behaviour is unchanged
  (FR-012).
- `<C-i>` (jump forward) is lost in terminals that send it as `<Tab>`, and is deliberately not
  remapped. `<C-o>` is unchanged (FR-012a).
- Later features MUST NOT remap `<Tab>`, `<S-Tab>` or `<Esc>` in normal mode without amending
  this contract. A feature that needs to run code when highlights are cleared SHOULD call
  `require("config.search").clear()` rather than re-mapping `<Esc>`.

## `config.search` module API

| Function | Behaviour |
|----------|-----------|
| `clear()` | Remove the position label if present. Never errors. |
| `refresh()` | Recompute and place or remove the label for the current cursor position. Never errors. |

## Visual guarantees

- At most one `[current/total]` label, right-aligned on the current match's line, in highlight
  group `SearchCountLabel`.
- The label is virtual text only: it is never written to the file and never yanked.
- Command-line search count (`[3/7]` in the command area) is suppressed (`shortmess` += `S`).
- Line-number column is at least 6 cells wide (5 digits + separator).
