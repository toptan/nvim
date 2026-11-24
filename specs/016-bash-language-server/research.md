# Research: Bash Language Server

All findings verified on 2026-11-24 with Neovim 0.12.6, bash-language-server 5.8.1
(Homebrew), shfmt 3.14.1 and ShellCheck (Homebrew), using a scratch git project and
`nvim --clean --headless`. Server behaviour was read from the installed sources
(`src/server.ts`, `src/config.ts`, `src/shfmt/index.ts`).

## R1: Server definition

- **Decision**: `lsp/bashls.lua` with `cmd = { "bash-language-server", "start" }`,
  `filetypes = { "bash", "sh" }`, `root_markers = { ".git" }`, no `settings`.
- **Rationale**: Matches the existing server files (`neocmake.lua`, `clangd.lua`) and the
  name nvim-lspconfig uses. With a git root the server's background analysis (default: at most
  500 files matching `**/*@(.sh|.inc|.bash|.command)`, ignoring `node_modules`/`.git`) lets
  go-to-definition follow `source`d files. With no marker found, `root_dir` is nil and the
  server works on the single file (verified: attaches to `/tmp/x.sh`).
- **Alternatives**: nvim-lspconfig (rejected, Principle I); extra root markers such as
  `.bashrc` or the file's directory (rejected: a home directory or `/tmp` would be analysed).

## R2: File types

- **Decision**: map both `sh` and `bash` to `bashls`; `zsh` not mapped.
- **Rationale**: Neovim 0.12 detects `.sh`, `~/.bashrc`, and extension-less files with a
  `#!/bin/bash` or `#!/usr/bin/env bash` shebang as `sh` (verified). `bash` is a valid file
  type (set by modelines or explicitly) and the server accepts it. The server does not parse
  zsh.

## R3: Formatting and `.editorconfig`

- **Decision**: keep the server's `documentFormattingProvider`; `<leader>lf` uses its existing
  LSP path. No `settings.bashIde.shfmt` options.
- **Rationale**: The server pipes the buffer through `shfmt --filename=<path> -i=<n>` where
  `<n>` is the client's `tabSize` when `insertSpaces`, otherwise 0 (tabs). Neovim derives these
  from `'shiftwidth'`/`'expandtab'`, which its built-in editorconfig support sets from
  `.editorconfig`. shfmt-specific `.editorconfig` keys (`switch_case_indent`,
  `binary_next_line`, …) are also read by the server. Verified: with
  `[*.sh] indent_size = 2`, a mis-indented script was re-indented with 2 spaces and spacing
  normalised; the result matches `shfmt` run from the command line in the same directory,
  which reads the same `.editorconfig`. The edit replaces the whole buffer in one
  `TextEdit`, so it is a single undo step.
- **Already formatted buffer** (found during implementation): the server sends that
  whole-buffer `TextEdit` even when the text is unchanged, so Neovim marks the buffer
  modified and adds an empty undo step, which breaks US2-4. clangd and lua_ls send no edits
  in that case. **Decision**: the shared `<leader>lf` in `config.lsp` compares the lines
  before and after formatting; if they are identical and formatting created a new undo step,
  it runs `:undo` (keeping the view), which restores `'modified'` and removes the step. The
  undo-sequence check keeps an edit that shares the undo block untouched.
- **No `.editorconfig`**: the server always passes `-i=<n>` from the editor, so shfmt's own
  default (tabs) never applies; with this config's global `expandtab`/`shiftwidth=4` the
  result is 4 spaces. Matching command-line shfmt therefore requires `.editorconfig`
  indentation settings (SC-004).
- **Range formatting**: the server does not advertise `documentRangeFormattingProvider`, so
  Neovim leaves `'formatexpr'` empty and `gq` keeps plain text formatting (verified).

## R4: shfmt missing

- **Decision**: in `on_init`, when `vim.fn.executable("shfmt") == 0`, set
  `client.server_capabilities.documentFormattingProvider = false`.
- **Rationale**: The server advertises formatting unconditionally; when shfmt cannot be
  spawned it returns no edits, so `<leader>lf` silently does nothing (verified with shfmt
  removed from `PATH`). Turning the capability off makes the existing `<leader>lf` code show
  its single "No language server can format this buffer" notice (FR-007), the same pattern
  `neocmake.lua` uses. The server and Neovim share the environment, so `executable()` sees the
  same `PATH` the server uses for its default `shfmt.path = "shfmt"`.
- **Alternative**: a shell-specific branch in `config.lsp` (rejected: spreads server knowledge
  into the dispatcher).

## R5: ShellCheck

- **Decision**: no configuration; rely on the server default `shellcheckPath = "shellcheck"`.
- **Rationale**: When ShellCheck is on `PATH` its findings arrive as diagnostics with source
  `shellcheck` (verified: SC2086 on an unquoted `$1`), and they use the global display and
  toggles from `config.diagnostics`. Without it the server publishes no lint diagnostics and
  shows no message (verified: no notification, zero diagnostics).

## R6: Missing server

- **Decision**: nothing extra.
- **Rationale**: As for the other servers, `vim.lsp.enable()` with a missing executable
  raises no error while editing; `:checkhealth vim.lsp` reports it.

## R7: Tree-sitter parser for shell

- **Decision**: add `"bash"` to `LANGUAGES` and `sh = "bash"`, `bash = "bash"` to `FILETYPES`
  in `lua/config/treesitter.lua`.
- **Rationale**: nvim-treesitter ships `bash` highlights, folds, indents, injections and
  locals queries; nvim-treesitter-textobjects ships `bash/textobjects.scm` (functions,
  parameters; no classes). The module's `attach()` passes the language to
  `vim.treesitter.start(buf, lang)` and checks `has_query` per feature, so mapping `sh` to the
  `bash` parser needs no `vim.treesitter.language.register()` call and folding, indentation
  and text objects are enabled automatically. `ac`/`ic`/`]c`/`[c` do nothing in shell
  scripts, as documented for languages without classes. Install, missing-tool warning and
  update behaviour are inherited unchanged.
- **Alternative**: rely on nvim-treesitter's own `sh → bash` registration (rejected: it exists
  only after the plugin loads, and the module's table is the single source of truth).

## R8: Startup cost

- **Decision**: no change to the lazy activation.
- **Rationale**: The `config_lsp` `FileType` autocommand pattern comes from the `servers`
  table; adding two keys adds no startup work. The tree-sitter plugins still load on the first
  supported buffer only.
