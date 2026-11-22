# Quickstart: validating next-key clues

Expected behaviour is defined in [contracts/clue.md](contracts/clue.md); triggers and clues
in [data-model.md](data-model.md).

## Prerequisites

- Neovim 0.12+, `git`, network access for the first start.
- Open a Lua file of this config (lua_ls attached), e.g. `nvim lua/config/keymaps.lua`.

## Scenarios

| # | Steps | Expected | Covers |
|---|-------|----------|--------|
| 1 | Remove `stdpath("data")/site/pack/core/opt/mini.clue`; start `nvim` | Installed without prompt; scenario 2 works in the same session | US4, SC-004 |
| 2 | Normal: `g`, wait | Window with `g` clues (`g`, `v`, `i`, `+LSP` …) | US1, SC-001 |
| 3 | Normal: `gg` quickly | Jumps to top; no window | US1 #3 |
| 4 | Normal: `<Space>`, wait; then `l`, wait; then `f` | `l +Language`, `t +Toggle`; then `f Format buffer`; then the buffer is formatted | US3, FR-003a |
| 5 | Normal: `<Space>t`, wait | `d`, `t`, `l` toggles with descriptions | US3 |
| 6 | Visual (`v`): `<Space>`, wait | `l +Language`, `t +Toggle`; `<Esc>` leaves Visual intact | US2, FR-003a |
| 7 | Visual: `<Space>l` | No error; still in Visual mode | Edge case |
| 8 | Normal: `g`, wait, `<Esc>` | Window closes; nothing happens | US1 #4 |
| 9 | Normal: `<C-w>`, wait, `<BS>`… then `<C-w>v` | `<BS>` drops the key; `<C-w>v` splits | US1 #5, SC-002 |
| 10 | Each remaining trigger: `[`, `]`, `z`, `'`, `` ` ``, `"` (Normal and Visual where listed) | Window per contract | SC-001 |
| 11 | Insert: `<C-r>`, wait, `"` | Register list; unnamed register inserted | US2 |
| 12 | Insert: `<C-x>`, wait, `<C-n>` | Sub-mode list; keyword completion runs | US2 |
| 13 | `:` then `<C-r>`, wait | Register list on the command line | US2 |
| 14 | `3gg`, `"ayy`, `2<C-w>>`, `zz`, `]d`, `'a` (after `ma`), `g*`, `dgg`, `yiw`; `g`, wait, `O` | Same results as without the plugin; `g*` shows the `[n/m]` counter; `gO` (buffer-local LSP mapping) listed and runs | SC-002, FR-005 |
| 15 | `qa` `gg` `q`, then `@a` | Recording works; no window while recording | Edge case |
| 16 | Insert completion (feature 010): type `vim.` + `<Tab>`, `<CR>` | Unchanged | Edge case |
| 17 | `:help`, `:copen`, `:terminal`, `q:`, then a trigger in each | No errors | Edge case |
| 18 | Block network, remove the plugin, start `nvim` | One WARN notice; `gg`, `zz`, `<C-w>v` work | US4, SC-005 |

## Commands

```sh
nvim --headless "+qa"                       # no output (SC-006)
nvim --startuptime /tmp/st.log +qa && tail -1 /tmp/st.log   # < 100 ms
nvim -c "checkhealth"                       # no new errors
```

Lua files must be lua_ls-clean; the README lists the plugin and its triggers (FR-010).
