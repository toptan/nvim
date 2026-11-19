# Quickstart: Validating the Lua Language Server and Diagnostic Toggles

## Prerequisites

- Neovim 0.12+ with this config as `~/.config/nvim`.
- `lua-language-server` on `PATH` (`brew install lua-language-server`).
- Test files:

  ```sh
  mkdir -p /tmp/ls/proj /tmp/ls/plain && cd /tmp/ls
  echo '{}' > proj/.luarc.json
  printf 'vim.o.number = true\n' > proj/a.lua
  printf 'hello\n' > plain/notes.txt
  printf 'print(1)\n' > loose.lua      # no .git or .luarc.json above it
  ```

## 1. Clean start and deferred loading (FR-001, FR-018, SC-005)

```sh
nvim --headless "+qa"                                     # expect: no output
nvim --headless --startuptime /tmp/st.log +qa && grep STARTED /tmp/st.log   # expect: < 100 ms
nvim --headless -c 'lua print(package.loaded["vim.lsp"] ~= nil)' +qa      # expect: false
nvim --headless /tmp/ls/plain/notes.txt \
  -c 'lua vim.wait(2000); print(#vim.lsp.get_clients())' +qa              # expect: 0 (US1 #6)
```

## 2. Server in the config (US1, FR-002, FR-003, SC-001, SC-002)

`nvim ~/.config/nvim/init.lua`:

1. Run `:checkhealth vim.lsp`. Expect `lua_ls` to be listed as an active client, with root
   `~/.config/nvim`.
2. Expect no diagnostic signs. Run `:lua =vim.diagnostic.count()` and expect `{}`.
3. Put the cursor on `keymaps` in `require("config.keymaps")` and press `<C-]>`. Expect
   `lua/config/keymaps.lua` to open.
4. Open `lua/config/autocmds.lua` and press `K` on `nvim_create_autocmd`. Expect its signature
   and docs.
5. Type `print(undefined_thing)` on a new line. Expect an "Undefined global" diagnostic shown
   as virtual text at the end of the line, with no virtual lines (FR-012). Keep it for §3.
   Undo it at the end.

## 3. Diagnostic toggles (US2, FR-007–FR-011, SC-003)

With the diagnostic from §2.5 visible:

1. Press `<leader>tl`. Expect a virtual line below the code and `Diagnostic virtual lines: on`.
   The virtual text stays.
2. Press `<leader>tt`. Expect the virtual text to go and `Diagnostic virtual text: off`.
   The virtual line stays.
3. Press `<leader>td`. Expect all signs, underlines and virtual lines to go and
   `Diagnostics: off`.
4. Press `<leader>tt`. Expect `Diagnostic virtual text: on (diagnostics are off)` and still
   nothing shown.
5. Press `<leader>td`. Expect diagnostics back with virtual text and virtual lines, and
   `Diagnostics: on`.
6. Run `:e /tmp/ls/plain/notes.txt` and press each toggle. Expect messages and no errors
   (US2 #5).

## 4. Formatting (US3, FR-005, FR-013–FR-015, SC-004)

1. In `lua/config/autocmds.lua`, press `<leader>lf`. Expect no change (`:echo &modified` → 0).
2. Change a line to `local t = {a=1,b='x'}` with 4-space indent and press `<leader>lf`. Expect
   `local t = { a = 1, b = "x", }` at 2-space indent.
3. Press `u` once. Expect the unformatted text back. Then discard with `:e!`.
4. In `/tmp/ls/plain/notes.txt`, press `<leader>lf`. Expect
   `No language server can format this buffer` and an unmodified buffer.
5. Run `:view ~/.config/nvim/init.lua`, wait for attach and press `<leader>lf`. Expect
   `Buffer is read-only` and an unmodified buffer.

## 5. Project-local settings win, and no stray workspace (clarification, FR-002, FR-006)

1. `nvim /tmp/ls/proj/a.lua`. Expect `Undefined global vim`, because the project's
   `.luarc.json` governs the server and nothing is injected.
2. `nvim /tmp/ls/loose.lua`, then `:checkhealth vim.lsp`. Expect `lua_ls` attached with no
   root directory and no workspace folders, so nothing above `/tmp/ls` is scanned.

## 6. Plugins are discovered (FR-003a, SC-002)

Uses an isolated copy (`NVIM_APPNAME`) so the real config, data and lockfile stay untouched.
Needs network access.

```sh
cp -R ~/.config/nvim ~/.config/nvim-lsptest
printf 'vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })\nlocal _ = require("plenary.async")\n' \
  >> ~/.config/nvim-lsptest/init.lua
NVIM_APPNAME=nvim-lsptest nvim ~/.config/nvim-lsptest/init.lua
```

1. Accept the install prompt and wait for the server to attach.
2. Expect no diagnostic on the `require("plenary.async")` line.
3. Press `<C-]>` on `plenary.async`. Expect plenary's `lua/plenary/async/init.lua` to open.
4. Quit and clean up:

   ```sh
   rm -rf ~/.config/nvim-lsptest ~/.local/share/nvim-lsptest \
     ~/.local/state/nvim-lsptest ~/.cache/nvim-lsptest
   ```

## 7. Missing server (FR-018, FR-018a)

```sh
PATH=/usr/bin:/bin nvim --headless ~/.config/nvim/init.lua +qa   # expect: no output
PATH=/usr/bin:/bin nvim ~/.config/nvim/init.lua                  # expect: no message
```

In the second run, `:checkhealth vim.lsp` shows
`'lua-language-server' is not executable. Configuration will not be used.`

## 8. Keymap count and style (FR-016, FR-017, SC-006, Principle V)

1. Run `:map <leader>`. Expect exactly `<Space>td`, `<Space>tt`, `<Space>tl` and `<Space>lf`,
   each with its `desc`.
2. Check `git diff --stat`. Expect no other `vim.keymap.set` calls added.
3. Open each changed Lua file. Expect 0 diagnostics, and `<leader>lf` to produce no changes.

## 9. Server stops or crashes (Edge Cases)

`nvim ~/.config/nvim/init.lua`, add `print(undefined_thing)` so a diagnostic shows, then run
`:lsp stop`. Expect the diagnostic to disappear, no error messages, and editing to keep
working. Run `:e!` to discard the change. Expect the server to attach again.
