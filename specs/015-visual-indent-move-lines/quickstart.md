# Quickstart: Validate Sticky Indent and Line Moving

## Prerequisites

- Neovim 0.12+ with this config.
- Terminal sending Alt as Meta, or macOS US layout (then Option+j / Option+k type `∆` / `˚`,
  which are mapped too).

## Smoke checks

```sh
nvim --headless "+qa"          # must exit with no output
```

`:verbose map <M-j>` and `:verbose xmap >` should show the mappings with their `desc`, from
`lua/config/keymaps.lua`.

## Manual scenarios

Open a scratch buffer with five lines: `a`, `b`, `c`, `d`, `e` (`:set sw=2 et`).

| # | Keys (from line 1) | Expected buffer | Expected mode / selection |
|---|--------------------|-----------------|---------------------------|
| 1 | `Vj>>` | `    a`, `    b`, `c`, `d`, `e` | `V`, lines 1–2 |
| 2 | then `<` | `  a`, `  b`, … | `V`, lines 1–2 |
| 3 | `Vj3>` | 6 spaces before `a` and `b` | `V`, lines 1–2 |
| 4 | `jVj<M-j><M-j>` | `a d e b c` | `V`, lines 4–5 |
| 5 | `jjjVj<M-k>` | `a b d e c` | `V`, lines 3–4 |
| 6 | `jjjVj5<M-j>` | unchanged | `V`, lines 4–5, no message |
| 7 | `Vj<M-k>` | unchanged | `V`, lines 1–2, no message |
| 8 | `<M-j>` | `b a c d e` | Normal, cursor on `a` (line 2) |
| 9 | `3<M-j>` | `b c d a e` | Normal, cursor on `a` (line 4) |
| 10 | `G<M-j>` | unchanged | Normal, no message |
| 11 | `jvj<M-j>` (charwise) | `a d b c e` | `v`, lines 3–4 |
| 12 | `j<C-v>j<M-j>` (block) | `a d b c e` | `<C-v>`, lines 3–4 |
| 13 | `jVj<M-j><M-j><Esc>u` | `a d b c e` (only the last move undone) | Normal |
| 14 | `jVj` then Option+j on macOS without Meta (`∆`) | `a d b c e` | `V`, lines 3–4 |
| 15 | `i∆<Esc>` | `∆` inserted as text | Normal |
| 16 | `:2,3fold`, then `G` `<M-k>` `<M-k>` `<M-k>` | `e` moves up one buffer line per press, as `:move` does | Normal, no error message |

A headless version of scenarios 1–13 can be run with `nvim_feedkeys(keys, "mtx", false)`
from a throwaway script, as done in [research.md](research.md).

## Startup time

Record a baseline before changing `lua/config/keymaps.lua`, then measure again afterwards
(each log file gets one block per run; compare the last line of each block):

```sh
for i in 1 2 3; do nvim --startuptime before.log +qa; done   # before the change
for i in 1 2 3; do nvim --startuptime after.log +qa; done    # after the change
grep "NVIM STARTED" before.log after.log
```

Totals should differ by under 1 ms and stay under 100 ms. Delete the two log files
afterwards.

## Regression checks

- Normal-mode `>>`, `<<`, `>ip` still shift as before and do not enter visual mode.
- `:checkhealth` shows no new errors.
