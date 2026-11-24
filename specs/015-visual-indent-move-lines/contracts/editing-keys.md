# Contract: Editing Keys in `lua/config/keymaps.lua`

All mappings are global, `noremap`, and carry the `desc` shown. No autocommands, no
exported functions.

## Indent (Visual mode, `x`)

| Keys | Right-hand side | `desc` |
|------|-----------------|--------|
| `>` | `>gv` | `Indent selection` |
| `<` | `<gv` | `Dedent selection` |

Count is honoured (`3>`). The selection stays active in the same visual mode.

## Move lines (Normal `n` and Visual `x`)

| Keys | Modes | Action | `desc` |
|------|-------|--------|--------|
| `<M-j>` | `n`, `x` | `move_lines(1)` | `Move line down` (n) / `Move selection down` (x) |
| `<M-k>` | `n`, `x` | `move_lines(-1)` | `Move line up` (n) / `Move selection up` (x) |
| `∆` | `n`, `x` | same as `<M-j>` | same as `<M-j>` |
| `˚` | `n`, `x` | same as `<M-k>` | same as `<M-k>` |

Behaviour (see [data-model.md](../data-model.md)):

- Moves `count` lines (default 1), clamped at the buffer edge; at the edge it is a silent
  no-op.
- Whole lines move, keeping their indentation; registers and the jumplist are untouched.
- Normal mode: the cursor stays on the moved line. Visual mode: the moved lines stay
  selected in the same visual mode.
- One undo step per key press.
- Not mapped in insert mode, so `∆` / `˚` can still be typed as text.

## Unchanged

Normal-mode `>>`, `<<`, `>{motion}`, `<{motion}`, and all existing mappings.

## README

Add rows for the indent and move keys to the "Key mappings" table, mentioning the `∆` / `˚`
fallback for macOS terminals without "Option as Meta".
