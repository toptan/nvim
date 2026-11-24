# Research: Sticky Visual Indent and Line Moving

The Technical Context had no open questions. The decisions below were checked with a headless
prototype (`nvim --clean --headless`, keys sent with `nvim_feedkeys(..., "mtx")`) on
Neovim 0.12.6.

## R1. Keeping the selection after `>` / `<`

- **Decision**: Visual-mode (`x`) mappings `>` → `>gv` and `<` → `<gv`.
- **Rationale**: A count typed before a mapped key goes to the first command of the
  right-hand side, so `3>` shifts three levels and then `gv` reselects. `gv` brings back the
  same visual mode (`v`, `V`, `<C-v>`) and the same `'<` / `'>` marks. Prototype: `Vj>>`
  gives two levels with `V` still active, `Vj3>` gives three levels, and `Vj>>2<` returns to
  zero. Each press is one undo step.
- **Note**: In charwise and blockwise selections the reselected columns are the same column
  positions, so after a shift they cover the text plus or minus one indent. This is the
  usual behaviour of `>gv`; the spec (FR-001, US1 scenario 4) requires the same lines, not
  the same characters, to stay selected.
- **Alternatives considered**: A Lua function that saves and restores the selection by text
  position: rejected as extra code for no practical gain. Mapping `<Tab>` / `<S-Tab>`:
  ruled out by the spec.

## R2. Moving lines

- **Decision**: A local `move_lines(dir)` helper in `keymaps.lua`, used for all six move
  mappings:
  1. Count = `vim.v.count1`. Range = the current line in normal mode. In visual mode it is
     `line("v")`..`line(".")`, ordered, and the helper then leaves visual mode with
     `normal! <Esc>`.
  2. Target: down → `min(line("$"), bottom + count)`; up → `max(0, top - count - 1)`.
  3. If the range is already at the edge in that direction, do nothing.
  4. Otherwise `silent keepjumps {top},{bottom}move {target}`.
  5. In visual mode, `normal! gv`. `:move` adjusts the `'<` / `'>` marks, so `gv`
     reselects the moved lines in the original visual mode.
- **Rationale**: `:move` moves lines without touching registers, keeps indentation exactly
  (FR-007), and is one undo step (FR-008). Clamping in Lua avoids `E16: Invalid range`
  at the buffer edges (FR-006). Prototype results with buffer `a b c d e`:
  `jVj<M-j><M-j>` → `a d e b c` with `V` on 4–5; `jjjVj5<M-j>` → no change, still `V`;
  `Vj<M-k>` → no change; `3<M-j>` on `a` → `b c d a e`; charwise and blockwise selections
  move whole lines and keep `v` / `<C-v>`; two moves followed by `u` undo only the last one.
- **Alternatives considered**: The common `:m '>+1<CR>gv=gv`: it re-indents (against
  FR-007), ignores counts, and raises E16 at the edges. `ddp` / `ddkP`: overwrites the
  unnamed register and breaks at the buffer edges. Plugins such as mini.move: rejected
  under Native-First.

## R3. Alt fallback characters

- **Decision**: Map `∆` (Option+j) and `˚` (Option+k) in `n` and `x` mode to the same
  helper as `<M-j>` / `<M-k>`. Do not map them in insert mode.
- **Rationale**: On macOS without "Option as Meta", the US layout types these characters.
  Terminals that send Alt as an Esc prefix already reach `<M-j>` through Neovim's
  `ttimeout` handling, and Linux terminals send Meta by default. Prototype: `jVj∆` moves
  like `<M-j>`. Mapping the characters in normal and visual mode only takes nothing away,
  because they have no built-in meaning there.
- **Alternatives considered**: Other layouts' characters: out of scope (clarification
  2026-11-24). Insert-mode mappings: would stop you typing `∆` / `˚` as text.

## R4. Interaction with existing config

- mini.clue triggers (`lua/config/clue.lua`) do not include `<`, `>`, `<M-…>`, `∆` or `˚`,
  so there is no interference.
- `keymaps.lua` maps only `<Tab>`, `<S-Tab>`, and `<C-h/j/k/l>` in normal mode. There is no
  clash, and normal-mode `>>` / `<<` / `>{motion}` are untouched (FR-010).
