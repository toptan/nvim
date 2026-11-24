# Research: One Diagnostics Module, Aligned List and Window Keys

## R1. Merging the modules without breaking augroups or startup

- **Decision**: Create the `config_diagnostics` augroup once at the top of
  `diagnostics.lua` with `clear = true`, and use it for both the `DiagnosticChanged` (once)
  autocmd and the `FileType qf` autocmd. Rename the namespace to `config_diagnostics`.
  Keep `M.setup()` and `return M`, because `lsp.lua` calls
  `require("config.diagnostics").setup()`. The list keys do not call `M.setup()`, as before.
- **Rationale**: If `nvim_create_augroup` were called twice with the same name and
  `clear = true`, the second call would delete the first group's autocmds. A single group
  keeps re-sourcing idempotent (Principle II). No top-level code touches `vim.diagnostic`,
  so startup is unchanged.
- **Alternatives considered**: Keeping two augroups (`config_diagnostics` and
  `config_diagnostic_list`) inside one file was rejected, because it keeps the old name
  alive for no reason. Making the list a sub-module (`config/diagnostics/list.lua`) was
  rejected because the user asked for a single file.

## R2. Is `quickfixtextfunc` output shown verbatim, padding included?

- **Decision**: Yes. Build fully padded lines in `build()`.
- **Rationale**: A headless check on 0.12.6 showed that the location list buffer lines are
  exactly the strings returned (`"a.lua|3 col 1    error  | x"`), and runs of spaces are
  kept.
- **Alternatives considered**: Virtual-text padding through the decoration provider was
  rejected. It is more complex, it would only be ephemeral, and it would make cursor
  columns misleading.

## R3. Measuring width for alignment

- **Decision**: Pad the location part by `max_width - vim.fn.strdisplaywidth(loc)` spaces,
  where `loc = ("%s|%d col %d"):format(file, lnum, col)` and `max_width` is the largest
  `strdisplaywidth` in this list. Pad labels by `7 - #label` (labels are ASCII; 7 =
  `#"warning"`). Highlight ranges remain byte offsets into the final line.
- **Rationale**: `strdisplaywidth("ä.lua") == 5` while `#"ä.lua" == 6`, so a byte count
  would misalign non-ASCII file names (spec edge case). The highlight APIs take byte
  columns, so the offsets must stay in bytes.
- **Alternatives considered**: A fixed location width was rejected because it either
  wastes space or truncates. Putting the severity first (Option C in the clarification)
  was rejected by the user.

## R4. Window keys: mapping form

- **Decision**: `vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })`,
  and the same for j/k/l ("lower", "upper", "right"). Put them in `lua/config/keymaps.lua`.
- **Rationale**: A string right-hand side is noremap by default, so it runs the built-in
  `<C-w>h` and not mini.clue's `<C-w>` trigger, and it still accepts a count (`3<C-l>`). At
  an edge the built-in command does nothing and raises no error. A headless check confirmed
  that `<C-l>` moves to the right split.
- **Alternatives considered**: A function calling `vim.cmd.wincmd("h")` was rejected
  because it loses the count unless `vim.v.count` is handled. Mapping Terminal and Insert
  modes as well was rejected in the clarification.

## R5. Buffer-local mappings that shadow the new keys

- **Decision**: Accept them. netrw maps `<C-l>` (refresh) and `<C-h>` locally in its
  buffers, and buffer-local mappings win there. No other configured plugin maps these keys.
- **Rationale**: netrw is the only built-in that does this, and it isn't part of the
  workflow in this config. Overriding plugin-local keys would go against Principle I's
  "leave core alone" spirit.
- **Alternatives considered**: A `FileType netrw` autocmd that re-maps the keys was
  deferred until it's actually needed.
