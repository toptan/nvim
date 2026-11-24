# Quickstart: Validating the Diagnostics List

## Prerequisites

- Neovim 0.12+, lua-language-server on `PATH`.
- A scratch Lua project with errors in several files (none of them need to be open):

```sh
mkdir -p /tmp/diag-proj && cd /tmp/diag-proj
echo '{}' > .luarc.json
printf 'local a = 1\nlocal function f()\n  return undefined_x + 1\nend\nreturn f\n' > a.lua
printf 'local x = nil\nreturn x.y + zzz_unknown\n' > b.lua
printf 'local p = 1\nreturn u1 + u2 + u3 + u4 + u5 + u6 + u7 + u8 + p\n' > c.lua
```

`a.lua` gives a warning (undefined global `undefined_x`) and a hint (unused local `a`); lua_ls
reports undefined globals as warnings and unused locals as hints. `b.lua` and `c.lua` are
never opened; lua_ls reports their problems on its own once a file in the project is
opened (for unopened files it reports undefined globals, not unused locals). `c.lua` adds
8 undefined globals, so the workspace has 3 files and 11
diagnostics: 2 in `a.lua`, 1 in `b.lua`, 8 in `c.lua` (SC-002; verified with lua_ls).

## Scenarios

| # | Steps | Expected | Covers |
|---|-------|----------|--------|
| 1 | `nvim a.lua`, wait ~1 s, `<Space>ld` | List below, focused, 2 entries: warning first, then hint; title `Diagnostics` | US1-1, FR-001, FR-004, FR-005 |
| 2 | In the list, `j` then `<CR>` | Cursor in `a.lua` on line 1, col 7; list still open | US1-2, FR-008 |
| 3 | `<C-w>j`, `<Esc>` | List closed; cursor in `a.lua` where step 2 left it; search highlight not touched | US1-3, FR-007, FR-011 |
| 4 | `<Space>lD` | List shows entries from `a.lua`, `b.lua` and `c.lua`; every warning comes before the hint | US2-1, FR-002, FR-004 |
| 5 | Select the `b.lua` entry, `<CR>` | Window shows `b.lua` line 2 | US2-2 |
| 6 | `<Space>ld` twice | One list window; refreshed and focused | FR-009 |
| 7 | `<Space>ld` while in the list window | No error; list still `a.lua`'s diagnostics | Edge case |
| 8 | `:enew`, `<Space>ld` | No window opens; notice `No diagnostics` | US1-4, FR-006 |
| 9 | `<Space>td` (off), `<Space>ld` | Notice `No diagnostics` | Edge case |
| 10 | Open list, look at colours | `warning` + message in warning colour, `hint` + message in hint colour; file name and `1 col 7` in usual list colours | FR-003a, SC-004a |
| 11 | With list open, `:colorscheme default` then back | Entry colours follow the scheme | Edge case |
| 12 | `:lvimgrep /local/ %`, `:lopen` | Not coloured by severity; `<Esc>` closes it | Edge case |
| 13 | `:copen`, `<Esc>` | Quickfix window stays open (only search highlight cleared) | FR-011 |
| 14 | `<Space>l` and pause | Clue window lists `d` Buffer diagnostics, `D` Workspace diagnostics, `f` | US3, FR-010 |
| 15 | `:lvimgrep /local/ %`, `:lopen`, `<C-w>k`, `<Space>ld` | Same list window now shows the diagnostics with full text and colours (no blank lines); `:lolder` brings back the grep list | FR-003, FR-009 |
| 16 | `<Space>lD`, then `:!rm b.lua` in a shell, select the `b.lua` entry, `<CR>` | Neovim's usual message (empty new buffer or E-message), no Lua error trace | Edge case |
| 17 | `<Space>ld`, then `:lclose` (or `<C-w>c` in the list) | List closes; no error | Edge case |

## Headless checks

```sh
nvim --headless "+qa"                       # no output (FR-013)
nvim --headless --startuptime /tmp/st.log +qa; grep "NVIM STARTED" /tmp/st.log  # < 100 ms
nvim --headless +"lua print(package.loaded['vim.diagnostic'] ~= nil)" +qa  # false
```

Colours can be checked headlessly: open the list, `:redraw`, compare
`screenattr(row, col)` of the label and message cells with a cell drawn in the severity's
`Diagnostic*` group, and against the file name cells.

Entry count (SC-002), run inside the scratch project after the list opens:

```lua
-- in the list window after <Space>ld: expect 2 (a.lua)
local fw = vim.fn.getloclist(0, { filewinid = 0, }).filewinid
print(#vim.fn.getloclist(0), #vim.diagnostic.get(vim.api.nvim_win_get_buf(fw)))
-- in the list window after <Space>lD: expect 11 (3 files)
print(#vim.fn.getloclist(0), #vim.diagnostic.get())
```

Timing (SC-001): wrap the key's callback, e.g.
`local t = vim.uv.hrtime(); vim.api.nvim_feedkeys(vim.keycode("<Space>ld"), "x", false);
print((vim.uv.hrtime() - t) / 1e6)` → < 500 ms for `<Space>ld`, < 2500 ms for
`<Space>lD`.
