# Data Model: Next-Key Clues via mini.clue

No persistent data. The "model" is the plugin's setup table and its runtime states.

## Plugin spec

| Field | Value |
|-------|-------|
| Source | `https://github.com/nvim-mini/mini.clue` |
| Version | default branch (latest); lockfile git-ignored |
| Installed by | `vim.pack.add`, `confirm = false` |
| Loaded | at startup, from `require("config.clue")` (research R2) |
| Global exported by the plugin | `MiniClue` |

## Trigger

`{ mode = string | string[], keys = string }`. Exactly these (FR-002):

| Keys | Modes |
|------|-------|
| `<Leader>` | `n`, `x` |
| `[` | `n` |
| `]` | `n` |
| `<C-x>` | `i` |
| `g` | `n`, `x` |
| `'` | `n`, `x` |
| `` ` `` | `n`, `x` |
| `"` | `n`, `x` |
| `<C-r>` | `i`, `c` |
| `<C-w>` | `n` |
| `z` | `n`, `x` |

11 entries, 18 mode/key pairs. Validation: no other entries (SC-003).

## Clue

`{ mode, keys, desc }`, or a generated list. Exactly these (FR-003, FR-003a):

| Clue | Source |
|------|--------|
| `<Leader>l` → `+Language` (`n`, `x`) | custom |
| `<Leader>t` → `+Toggle` (`n`, `x`) | custom |
| square brackets | `gen_clues.square_brackets()` |
| built-in completion | `gen_clues.builtin_completion()` |
| `g` | `gen_clues.g()` |
| marks | `gen_clues.marks()` |
| registers | `gen_clues.registers()` |
| windows | `gen_clues.windows()` |
| `z` | `gen_clues.z()` |

Mapping descriptions (`desc`) of user and built-in mappings are added by the plugin at query
time (FR-005); no list is kept by the config.

## Other options

Plugin defaults (FR-006): `window.delay = 1000`, `window.config = {}` (border from
`'winborder'`), `scroll_down = "<C-d>"`, `scroll_up = "<C-u>"`.

## States

```text
idle ──trigger key──▶ querying ──delay (1 s) passes──▶ window shown
  ▲                     │  │                              │
  │                     │  └─key completes a mapping──────┤──▶ keys executed ──▶ idle
  │                     └─<Esc>───────────────────────────┤──▶ idle (nothing runs)
  └───────────────────── <BS> removes last key, stays querying / shown
```

A prefix with no mappings beneath it in the current mode (e.g. `<Leader>l` in Visual mode today)
does not open a level: the keys are executed as typed (research R4).

Failure state: plugin missing → no triggers; one WARN; all keys behave as stock Neovim.
