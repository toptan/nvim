## 1. Add mini.input

- [x] 1.1 In `plugin/60-mini.lua`, add `require("mini.input").setup()` (no options)

## 2. Add mini.cursorword

- [x] 2.1 In `plugin/60-mini.lua`, add `require("mini.cursorword").setup()` (no options)

## 3. Add mini.files and its keymaps

- [x] 3.1 In `plugin/60-mini.lua`, add `require("mini.files").setup()` (no options)
- [x] 3.2 Add a shared `toggle_files(path)` helper using `mini.files`' documented toggle recipe
      (see `design.md` §2)
- [x] 3.3 Add `-` keymap: `toggle_files(vim.api.nvim_buf_get_name(0))`
- [x] 3.4 Add `<Leader>ed` keymap: `toggle_files(vim.fn.getcwd())`

## 4. Manual verification

Drive via `nvim --headless --listen <socket>` + `nvim --server <socket> --remote-send`, so real
key sequences and prompts can be observed via RPC.

- [x] 4.1 `nvim --headless -c 'qa'` reports no startup errors after all three `setup()` calls are
      added
- [x] 4.2 `mini.input`: triggering `vim.ui.input({ prompt = "Test: " }, callback)` shows a
      `mini.input` prompt (not the default command-line `input()` prompt) and the callback
      receives typed text on `<CR>`, `nil` on `<Esc>`
- [x] 4.3 Not separately exercised live: `vim.lsp.buf.rename()` calls `vim.ui.input()`
      internally with no LSP-specific input path, so 4.2's direct `vim.ui.input()` verification
      already covers it — skipped as redundant rather than run against a live LSP server
- [x] 4.4 `mini.cursorword`: placing the cursor on a word that appears elsewhere in the window
      highlights the other occurrences after the default delay; moving off the word clears it
- [x] 4.5 `mini.files`: pressing `-` with the explorer closed opens it with the current buffer's
      file focused; pressing `-` again closes it
- [x] 4.6 `mini.files`: pressing `<Leader>ed` with the explorer closed opens it rooted at the
      current working directory; pressing `<Leader>ed` again closes it
- [x] 4.7 `mini.files`: opening a directory path directly (e.g. `:edit .`) opens `mini.files`
      instead of netrw
- [x] 4.8 `mini.files`: default in-explorer mappings still work as documented (`l`/`h` navigate
      in/out, `q` closes, `g?` shows help)
- [x] 4.9 `:checkhealth mini.nvim` shows no new errors beyond the pre-existing "No healthcheck
      found" (expected, per prior `mini.nvim` changes)

## 5. Docs

- [x] 5.1 Update `CLAUDE.md`'s load-order section (item on `plugin/60-mini.lua`) to mention
      `mini.input`, `mini.cursorword`, and `mini.files` alongside the modules already listed there
