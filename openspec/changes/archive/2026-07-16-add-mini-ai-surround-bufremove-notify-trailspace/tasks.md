## 1. Add mini.ai

- [x] 1.1 In `plugin/60-mini.lua`, add `mini.ai` with a pcall-wrapped `treesitter_textobject()`
      helper for the `f`/`c` custom textobjects (see `design.md` §1 for why the wrapper is needed —
      `gen_spec.treesitter()` raises an error, not a silent no-match, on unsupported filetypes)

## 2. Add mini.surround

- [x] 2.1 In `plugin/60-mini.lua`, add `require("mini.surround").setup()` (no options)

## 3. Add mini.bufremove and its keymaps

- [x] 3.1 In `plugin/60-mini.lua`, add `require("mini.bufremove").setup()`
- [x] 3.2 Add `<Leader>bd` keymap: `require("mini.bufremove").delete(0, false)`
- [x] 3.3 Add `<Leader>bD` keymap: `require("mini.bufremove").delete(0, true)`

## 4. Add mini.notify and its keymap

- [x] 4.1 In `plugin/60-mini.lua`, add `require("mini.notify").setup()`
- [x] 4.2 Set `vim.notify = require("mini.notify").make_notify()`
- [x] 4.3 Add `<Leader>on` keymap: `require("mini.notify").show_history`

## 5. Add mini.trailspace and its keymap

- [x] 5.1 In `plugin/60-mini.lua`, add `require("mini.trailspace").setup()` (no options)
- [x] 5.2 Add `<Leader>cw` keymap: `require("mini.trailspace").trim()`

## 6. Manual verification

Drive via `nvim --headless --listen <socket>` + `nvim --server <socket> --remote-send`, so real
normal/visual-mode key sequences and popups can be observed via RPC.

- [x] 6.1 `nvim --headless -c 'qa'` reports no startup errors after all five `setup()` calls are
      added
- [x] 6.2 `mini.ai`: in a Lua file, `daf` with the cursor inside a function deletes the whole
      function; `dac` inside a class-like construct (or nested table/module pattern) deletes it
- [x] 6.3 `mini.ai`: `di(`, `va"`, `cit` (in an HTML/JSX-like buffer if available, otherwise skip)
      still work as built-in `mini.ai` textobjects
- [x] 6.4 `mini.ai`: typing `an`/`in` in visual mode runs `mini.ai`'s next-textobject expansion,
      not Neovim's built-in incremental selection
- [x] 6.5 `mini.ai`: in a buffer whose language has no `textobjects.scm` query (verified with a
      `vimdoc`/help-filetype buffer, and separately a filetype-less buffer), `daf` finds nothing
      and raises no error — confirms the `treesitter_textobject()` pcall wrapper in `design.md` §1
      actually prevents the raw `gen_spec.treesitter()` error surfaced during initial testing
- [x] 6.6 `mini.surround`: `saiw)` around a word wraps it in parentheses; `sd)` on that same text
      removes the wrapping; `sr)]` replaces the parens with brackets
- [x] 6.7 `mini.surround`: pressing bare `s` in normal mode (waiting past `timeoutlen` without a
      further key) still runs substitute-character on the character under the cursor
- [x] 6.8 `mini.bufremove`: with two buffers open in one window, `<Leader>bd` on an unmodified
      buffer removes it from the buffer list and the window shows the other buffer, without
      closing the window
- [x] 6.9 `mini.bufremove`: with unsaved changes in the current buffer, `<Leader>bD` removes it
      without a save prompt
- [x] 6.10 `mini.notify`: triggering a `vim.notify("test")` call shows a `mini.notify` floating
      window instead of a plain `:messages` echo
- [x] 6.11 `mini.notify`: after at least one notification has fired, `<Leader>on` opens the
      notification history
- [x] 6.12 `mini.notify`: an LSP-attached buffer still shows LSP progress notifications (e.g. on
      initial diagnostics/indexing) through `mini.notify`'s styling
- [x] 6.13 `mini.trailspace`: a normal buffer with a line ending in trailing spaces shows the
      highlight; a `nofile`/terminal buffer with trailing spaces does not
- [x] 6.14 `mini.trailspace`: `<Leader>cw` removes trailing whitespace from every line in the
      current buffer; saving without pressing it leaves trailing whitespace intact
- [x] 6.15 `:checkhealth mini.nvim` shows no new errors beyond the pre-existing "No healthcheck
      found" (expected — `mini.nvim` ships no per-module healthcheck, per prior changes)

## 7. Docs

- [x] 7.1 Update `CLAUDE.md`'s load-order section (item on `plugin/60-mini.lua`) to mention
      `mini.ai`, `mini.surround`, `mini.bufremove`, `mini.notify`, and `mini.trailspace` alongside
      the modules already listed there
