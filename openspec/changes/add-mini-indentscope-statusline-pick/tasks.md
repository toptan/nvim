## 1. Add mini.indentscope

- [x] 1.1 In `plugin/60-mini.lua`, add `require("mini.indentscope").setup({ draw = { animation =
      require("mini.indentscope").gen_animation.none() } })`

## 2. Add mini.statusline

- [x] 2.1 In `plugin/60-mini.lua`, add a `diagnostics_by_severity(trunc_width)` helper that returns
      one `{ hl = Diagnostic<Level>, strings = {...} }` group per non-zero severity (see
      `design.md` §2)
- [x] 2.2 Add `require("mini.statusline").setup({ content = { active = ... } })` with a custom
      `content.active` that matches the module's documented default function, splicing in
      `diagnostics_by_severity()` in place of the single `section_diagnostics()` call

## 3. Add mini.pick and its keymaps

- [x] 3.1 In `plugin/60-mini.lua`, add `require("mini.pick").setup()` (no options)
- [x] 3.2 Add `<Leader>ff` keymap: `require("mini.pick").builtin.files()`
- [x] 3.3 Add `<Leader>fg` keymap: `require("mini.pick").builtin.grep_live()`
- [x] 3.4 Add `<Leader>fG` keymap: `require("mini.pick").builtin.grep()`
- [x] 3.5 Add `<Leader>fb` keymap: `require("mini.pick").builtin.buffers()`
- [x] 3.6 Add `<Leader>fh` keymap: `require("mini.pick").builtin.help()`
- [x] 3.7 Add `<Leader>fr` keymap: `require("mini.pick").builtin.resume()`
- [x] 3.8 Add `<Leader>fc` keymap: prompt via `vim.ui.input()`, then
      `require("mini.pick").builtin.cli({ command = vim.split(input, "%s+") })` (see `design.md`
      §3 — `builtin.cli()` takes `command` as an argv table, not an interactive prompt, so a bare
      call silently opens an empty picker)

## 4. Manual verification

Drive via `nvim --headless --listen <socket>` + `nvim --server <socket> --remote-send`, so real
key sequences can be observed via RPC.

- [x] 4.1 `nvim --headless -c 'qa'` reports no startup errors after all three `setup()` calls are
      added
- [x] 4.2 `mini.indentscope`: entering an indented block draws the scope symbol with no visible
      step animation (appears immediately after the draw delay, not progressively)
- [x] 4.3 `mini.indentscope`: `dii`/`dai` and `[i`/`]i` still work as documented defaults
- [x] 4.4 `mini.statusline`: a buffer with 2 errors and 3 warnings (no info/hints) shows an error
      segment and a warning segment, each with the corresponding `DiagnosticError`/`DiagnosticWarn`
      highlight applied (not a single flat `MiniStatuslineDevinfo` color for both)
- [x] 4.5 `mini.statusline`: a buffer with no diagnostics shows no diagnostics segment at all, and
      mode/git/diff/LSP/filename/fileinfo/search/location sections still render as before
- [x] 4.6 `mini.pick`: `<Leader>ff` opens the files picker; choosing an entry opens that file
- [x] 4.7 `mini.pick`: `<Leader>fg` opens live grep; typing updates matches interactively
- [x] 4.8 `mini.pick`: `<Leader>fG` prompts for a pattern once, then shows matches for it
- [x] 4.9 `mini.pick`: `<Leader>fb` opens the buffers picker listing open buffers
- [x] 4.10 `mini.pick`: `<Leader>fh` opens the help-tags picker
- [x] 4.11 `mini.pick`: after closing a picker, `<Leader>fr` resumes it with the previous query
- [x] 4.12 `mini.pick`: `<Leader>fc` prompts for a shell command and lists its output as pickable
      items
- [x] 4.13 `:checkhealth mini.nvim` shows no new errors beyond the pre-existing "No healthcheck
      found" (expected, per prior `mini.nvim` changes)

## 5. Docs

- [x] 5.1 Update `CLAUDE.md`'s load-order section (item on `plugin/60-mini.lua`) to mention
      `mini.indentscope`, `mini.statusline`, and `mini.pick` alongside the modules already listed
      there
