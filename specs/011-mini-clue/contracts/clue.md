# Contract: Next-Key Clues (mini.clue)

## Triggers and what they show

After a trigger key, the clue window opens once no further key has been pressed for 1 s
(plugin default). Typing the full sequence faster never shows a window.

| Mode | Trigger | Window lists |
|------|---------|--------------|
| Normal, Visual | `<Leader>` (Space) | User mappings; groups `l  +Language`, `t  +Toggle` |
| Normal | `[` / `]` | Built-in and user bracket motions (`]d`, `[q` …) |
| Normal, Visual | `g` | `g` commands, incl. LSP (`+LSP` for `gr`) and `g*` / `g#` |
| Normal, Visual | `'` / `` ` `` | Marks with their positions |
| Normal, Visual | `"` | Registers with their contents |
| Normal | `<C-w>` | Window commands |
| Normal, Visual | `z` | Fold, scroll and spelling commands |
| Insert | `<C-x>` | Built-in completion sub-modes |
| Insert, Command-line | `<C-r>` | Registers with their contents |

## Keys while the window is open (plugin defaults)

| Key | Effect |
|-----|--------|
| A listed key | Runs the command, or opens the next level for a group |
| `<BS>` | Drops the last typed key; window shows the shorter sequence |
| `<Esc>` | Closes; nothing runs |
| `<C-d>` / `<C-u>` | Scroll the window |

## Guarantees

- Every sequence does exactly what it does without the plugin (FR-004); counts, registers
  and `expr` mappings (`g*`, `g#`) included.
- A prefix with no mappings beneath it in the current mode (today: `<Leader>l`, `<Leader>t`
  in Visual mode) falls through as plain keys; no error.
- No triggers during macro recording (plugin limitation); recorded keys are unaffected.
- Not triggers, unchanged: Normal `<Tab>`, `<S-Tab>`, `<Esc>`; Insert `<Tab>`, `<S-Tab>`,
  `<CR>`, `<C-Space>` (feature 010); Operator-pending mode.

## Failure

Plugin cannot be installed or loaded: one WARN notification "mini.clue unavailable: …";
no clue window; every key works as in stock Neovim.

## Configuration

`lua/config/clue.lua`: installs with `vim.pack`, calls `setup()` with the quick-start
`triggers` and `clues` plus the two `<Leader>` group names; nothing else overridden.
`init.lua` requires it last.
