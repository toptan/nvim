# Research: CMake Language Server with Gersemi Formatting

All findings were checked on this machine on 2026-11-20 with Neovim 0.12.6, neocmakelsp
0.11.2 and gersemi 0.29.2, using headless `nvim --clean` prototypes against a small CMake
project.

## R1. Starting neocmakelsp

- **Decision**: `cmd = { "neocmakelsp", "stdio" }`, `filetypes = { "cmake" }`, in a new
  `lsp/neocmake.lua`. The server is enabled by `vim.lsp.enable("neocmake")` on the first
  `FileType cmake`, the same lazy pattern used for `lua_ls`.
- **Rationale**: neocmakelsp 0.11 takes subcommands (`stdio`, `tcp`, `format`, …). The old
  `--stdio` flag is gone. Neovim's built-in filetype detection already maps `CMakeLists.txt`
  and `*.cmake` to `cmake`. The name `neocmake` matches nvim-lspconfig's, so
  `:checkhealth vim.lsp` and `:lsp` show a familiar name.
- **Alternatives considered**: enabling at startup (loads `vim.lsp` on every launch, which
  goes against Principle III); nvim-lspconfig (a plugin for one small table, which goes
  against Principle I).

## R2. Project root

- **Decision**: `root_markers = { ".git", "CMakeLists.txt", }`.
- **Rationale**: In 0.12, markers are tried in priority order, so the repository root wins
  and go-to-definition can follow `include()` across the whole project. Outside a repository,
  the nearest directory with a `CMakeLists.txt` is used. With neither, `root_dir` is `nil`. The
  prototype confirmed that neocmakelsp then starts in single-file mode without errors, so it
  never scans the home directory (spec edge case).
- **Alternatives considered**: a custom `root_dir` that looks for the outermost
  `CMakeLists.txt` (more code for little gain, because `.git` covers almost all real
  projects); nvim-lspconfig's `{ ".git", "build", "cmake" }` (`build/` or `cmake/` folders in
  subdirectories can pick the wrong root).

## R3. Turning off neocmakelsp formatting (FR-004, clarification Q1)

- **Decision**: in `on_init`, set `documentFormattingProvider`,
  `documentRangeFormattingProvider` and `documentOnTypeFormattingProvider` to `false` on
  `client.server_capabilities`.
- **Rationale**: The prototype showed that neocmakelsp advertises
  `documentFormattingProvider = true` and has no range formatting. After the override,
  `client:supports_method("textDocument/formatting")` returns `false`, so `<leader>lf`'s LSP
  path and `vim.lsp.buf.format()` never pick it. `on_init` runs before `_set_defaults()`, so
  Neovim's attach defaults never set `formatexpr` to `v:lua.vim.lsp.formatexpr()`. `gq`
  therefore uses plain text formatting (`formatexpr` was confirmed empty after attach).
  neocmakelsp registers only `workspace/didChangeWatchedFiles` dynamically, never
  formatting, so a later dynamic registration cannot turn formatting back on.
- **Alternatives considered**: `init_options = { format = { enable = false } }` (only
  documented by the server, depends on its version, and the capability could still be
  advertised); filtering clients in `<leader>lf` (would leave `vim.lsp.buf.format()` able to
  use neocmakelsp).

## R4. Running gersemi on the buffer (FR-005, FR-006, clarification Q2)

- **Decision**: run `gersemi --stdin-filepath <buffer path> -` with the buffer text on stdin,
  using `vim.system(…):wait(5000)` with `cwd` set to the buffer's directory. Leave out
  `--stdin-filepath` for buffers with no name, so gersemi falls back to the config nearest
  the working directory. Pass no style options.
- **Rationale**: stdin formats the current, possibly unsaved content. `--stdin-filepath`
  makes gersemi use the `.gersemirc` nearest the file (in its directory or a parent) whatever
  the working directory is. This was confirmed: with `indent: 2` and `line_length: 40` in the
  project, output was indented by 2 when run from `/`, and plain defaults applied when the
  flag was left out. Running synchronously matches `<leader>lf` for Lua (one undo step, no
  race with typing). A gersemi run took about 80 ms.
- **Alternatives considered**: `gersemi -i <file>` (needs a saved file and reloads it, which
  loses undo granularity); `formatprg` (a fixed command, no `--stdin-filepath`, and `gq`
  would then use gersemi on selections, which goes against Q1); conform.nvim (a plugin,
  Principle I).

## R5. gersemi errors and warnings (FR-007)

- **Decision**: exit code 0 means take stdout and ignore stderr. Any other exit code means
  leave the buffer alone and show one WARN notice: `gersemi: <first non-empty stderr line>`.
  If `gersemi` is not executable, show `gersemi is not installed` and don't run anything.
  A timeout is reported as `gersemi timed out`.
- **Rationale**: With exit code 0, gersemi prints harmless warnings to stderr (for example
  "unknown command 'my_helper'" for functions defined in other files). A parse error gives
  exit code 123 and a message like `-: 2:2: unbalanced parentheses`. `-q` was rejected
  because it also hides that error message.
- **Alternatives considered**: `--no-warn-about-unknown-commands` (changes the project's
  configured behaviour and isn't needed once stderr is ignored on success).

## R6. Applying the result (FR-008)

- **Decision**: compare the old and new text with `vim.text.diff(…, { result_type =
  "indices" })` and apply each hunk with `nvim_buf_set_lines`, working from the bottom up.
  If nothing differs, touch nothing.
- **Rationale**: Changing only what differs keeps the cursor, marks and folds outside changed
  hunks, and a buffer that is already formatted is not marked modified. All edits happen in
  one mapping call, so they form a single undo step. gersemi always ends its output with a
  newline. The trailing empty element left after splitting is dropped so the line count
  matches the buffer (which already has `eol`).
- **Alternatives considered**: replacing every line at once (moves the cursor to the top,
  wipes marks, and marks the buffer modified even when nothing changed).

## R7. Health and missing tools (FR-011, FR-012)

- **Decision**: no extra code. If `neocmakelsp` is missing, `vim.lsp.enable` stays silent and
  `:checkhealth vim.lsp` reports the command as not executable, exactly as for `lua_ls`. If
  `gersemi` is missing, only `<leader>lf` in a CMake buffer reports it (spec edge case).
- **Rationale**: This matches feature 003's behaviour and Principle IV.

## R8. Diagnostic source label

- **Finding**: neocmakelsp syntax diagnostics have no `source` field. The bordered popup from
  feature 004 (`source = true`) then shows the message without a prefix. That is acceptable,
  and no change is planned.
