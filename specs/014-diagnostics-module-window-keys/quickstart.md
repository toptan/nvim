# Quickstart: Validating Feature 014

Prerequisites: Neovim 0.12+, `lua-language-server` on `PATH`, config at `~/.config/nvim`.

## 1. Module merge (US3, FR-001–FR-003)

```sh
test ! -e lua/config/diagnostic_list.lua && echo deleted
grep -rn diagnostic_list init.lua lua README.md   # expect no output
nvim --headless "+qa"                              # expect no output
nvim --headless "+lua print(package.loaded['vim.diagnostic'] == nil)" +qa  # true
nvim --startuptime /dev/stdout --headless +qa | tail -1   # < 100 ms
```

Then repeat the acceptance scenarios of spec 013 (keys `<leader>ld`, `<leader>lD`, `<CR>`
and `<Esc>` in the list, the empty-list notice) and of spec 004 (`<leader>td/tt/tl`).

## 2. Aligned list (US1, FR-004–FR-006)

Create a scratch Lua file whose diagnostics include an error on line 3, a warning on a
line ≥ 100 at column ≥ 10, and an info or hint diagnostic. Open a second file with a
longer path that also has a diagnostic.

1. `<leader>ld`: in the list, every `error`/`warning`/`info`/`hint` label starts at the
   same screen column, and every message starts at the same screen column.
2. `<leader>lD`: the same holds across both files.
3. Scripted check from inside the list window:
   `:lua for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do print(vim.fn.strdisplaywidth(l:match("^(.-) %a+ *| "))) end`.
   Every number is the same.
4. Colours: put the cursor on padding after a label; `:Inspect` shows no `Diagnostic*`
   highlight there. On the label and on the message it shows the severity's group.
5. `:colorscheme` to another scheme: colours follow, alignment unchanged.
6. `<CR>` on an entry lands on the right file, line and column.

## 3. Window keys (US2, FR-007–FR-010)

1. `:vsplit`, then `<C-l>` / `<C-h>` move right / left; `:split`, then `<C-j>` / `<C-k>`
   move down / up.
2. In the leftmost window `<C-h>` does nothing and shows no message.
3. `<leader>ld`, then `<CR>` on an entry, then `<C-j>`: the cursor is back in the list.
4. Insert mode `<C-h>` still deletes a character; `<C-w>l` still works; `<C-w>` + pause
   still shows the window clues.
5. `:verbose nmap <C-l>` shows `Go to right window`, defined in `lua/config/keymaps.lua`.
6. Other special windows (FR-008): `:copen`, then `<C-k>` goes to the window above the
   quickfix list and `<C-j>` comes back; `:help`, then `<C-j>` leaves the help window and
   `<C-k>` returns to it. Neither raises an error.

## 4. Style

- lua_ls reports no diagnostics in `diagnostics.lua` or `keymaps.lua`.
- `:checkhealth` shows no new errors.
