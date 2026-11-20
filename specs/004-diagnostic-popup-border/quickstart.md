# Quickstart: Validating the Prominent Diagnostic Popup

## Prerequisites

- Neovim 0.12+ with this config as `~/.config/nvim`.
- `lua-language-server` on `PATH` (for real diagnostics with a source).
- A test file:

  ```sh
  mkdir -p /tmp/popup && printf 'local unused = 1\nprint(undefined_thing)\n' > /tmp/popup/t.lua
  ```

## 1. Clean start, no startup cost (FR-011, SC-004)

```sh
nvim --headless "+qa"                                              # expect: no output
nvim --headless --startuptime /tmp/st.log +qa && grep STARTED /tmp/st.log  # expect: < 100 ms
nvim --headless -c 'lua print(package.loaded["vim.diagnostic"] ~= nil)' +qa  # expect: false
nvim --headless -c 'lua print(vim.o.winborder)' +qa                # expect: rounded
```

## 2. Bordered diagnostic popup (US1, FR-001 – FR-003, SC-001, SC-002)

`nvim /tmp/popup/t.lua`, wait for diagnostics, then:

1. Put the cursor on line 1 and press `<C-w>d`. Expect a popup with a full rounded border on
   all four sides. The border is the same blue as the title and clearly stands out from both
   the popup text and the code behind it.
2. Press `<Esc>` or move the cursor. Expect the popup and its border to close together, with no
   stray characters left.
3. Run `:set background=light` and repeat step 1. Expect the border to still be clearly visible
   (dark blue on a light popup). Run `:set background=dark` to restore.
4. Resize the terminal very narrow (e.g. 30 columns) and repeat step 1 on line 2. The message
   wraps; expect all text inside the border and no errors.
5. Scroll so line 2 is the last screen line and press `<C-w>d`. Expect the popup to open above
   the line with its border fully visible. Repeat with the cursor at the far right of a long
   line.

## 3. Popup contents (US2, FR-004 – FR-006, SC-003)

1. On line 2, press `<C-w>d`. Expect `Diagnostics` centred in the top border, no
   "Diagnostics:" line inside, and the entry prefixed `Lua Diagnostics.:` (the server's source
   name).
2. Run `:lua vim.diagnostic.set(vim.api.nvim_create_namespace("t"), 0, {{lnum=0,col=0,message="no source",severity=1},{lnum=0,col=0,message="a hint",severity=4,source="test"}})`,
   then press `<C-w>d` on line 1. Expect the error in the error colour with no prefix (no
   `nil`), and the hint in the hint colour prefixed `test:`. The colours match the signs in the
   sign column.
3. Run `:lua vim.diagnostic.open_float()`. Expect the same style without passing any options
   (FR-007).

## 4. Other popups share the border (FR-010, SC-005)

1. On `print`, press `K`. Expect hover documentation in the same rounded, blue-bordered popup.
2. On line 2, enter insert mode right after `print(` and press `<C-s>`. Expect signature help in
   the same rounded, blue-bordered popup.
3. Run `:lua vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {relative="editor",row=2,col=2,width=10,height=1,border="none"})`.
   Expect no border: explicit choices are kept. Close it with `:only`.
4. In insert mode, press `<C-n>`. Expect the completion menu to look as before (no border).

## 5. Interplay with the toggles (spec edge cases)

1. Press `<leader>td` (diagnostics off), then `<C-w>d` on line 2. Expect the popup to still open
   in the same style (core behaviour). Press `<leader>td` again.
2. Press `<leader>tt` and `<leader>tl`, then `<C-w>d`. Expect the popup unchanged and the
   toggles to keep working as before.
3. On a line with no diagnostics, press `<C-w>d`. Expect nothing to open.

## 6. Health and style

- Run `:checkhealth vim.lsp` and `:checkhealth`. Expect no new errors.
- Expect `lua/config/options.lua`, `colorscheme.lua` and `diagnostics.lua` to show 0 `lua_ls`
  diagnostics, and `<leader>lf` to leave them unchanged.
