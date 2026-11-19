# Neovim daily driver config

## Requirements

- Neovim 0.12 or newer (uses the built-in `catppuccin` colour scheme)

## Key mappings

Normal mode only; the leader key is Space.

| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlights and the match counter |
| `<Tab>` / `<S-Tab>` | Next / previous file buffer (open order, wraps; skips help, quickfix and terminal buffers) |
| `n` `N` `*` `#` `g*` `g#` | Native search jumps, plus a `[current/total]` counter right-aligned on the match's line |

The counter stays until highlights are cleared, the buffer is edited, or another buffer
is shown. In terminals `<Tab>` and `<C-i>` are the same key, so jump-forward (`<C-i>`) is
not available; `<C-o>` (jump back) still works.
