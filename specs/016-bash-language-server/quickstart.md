# Quickstart: Validating Shell Script Support

## Prerequisites

- `bash-language-server`, `shellcheck` and `shfmt` on `PATH` (`brew install
  bash-language-server shellcheck shfmt`)
- Tree-sitter build tools as listed in the README
- A scratch project:

```sh
mkdir -p /tmp/shproj/lib && cd /tmp/shproj && git init -q
printf 'root = true\n[*.sh]\nindent_style = space\nindent_size = 2\n' > .editorconfig
printf 'greet() {\n  echo "hello $1"\n}\n' > lib/util.sh
printf '#!/usr/bin/env bash\nsource ./lib/util.sh\nmain() {\n        local name=$1\n    greet   "$name"\n}\nmain $1\n' > run.sh
printf '#!/bin/bash\necho hi\n' > noext
mkdir -p /tmp/shplain && printf 'if true; then\necho x\nfi\n' > /tmp/shplain/p.sh
```

## Scenarios

| # | Steps | Expected | Covers |
|---|-------|----------|--------|
| 1 | `nvim` on an empty buffer, `:lua print(#vim.lsp.get_clients())` | `0` | US1-7, SC-002 |
| 2 | `nvim /tmp/shproj/run.sh`, `:checkhealth vim.lsp` | `bashls` attached within 5 s, root `/tmp/shproj` | US1-1, FR-001, FR-003 |
| 3 | `:e /tmp/shproj/noext`, `:set ft?`, `:lua print(#vim.lsp.get_clients({ name = "bashls" }))` | `filetype=sh`; `1` (same client reused) | edge cases (file type, many scripts) |
| 4 | `nvim /tmp/x.zsh` (`:set ft=zsh`) | no `bashls` client | FR-002 |
| 5 | `K` on `echo`; `<C-]>` on `greet` | Bordered hover with `echo` docs; jumps to `lib/util.sh` | US1-3, US1-4 |
| 6 | `grn` on `name`, rename to `who` | Both occurrences renamed | US1-5 |
| 7 | Type `gre` in insert mode | `greet` offered in the completion menu | US1-2 |
| 8 | Look at line `main $1`; `<leader>tt`; `<leader>ld` | ShellCheck SC2086 diagnostic; toggled; listed | US1-6, FR-005 |
| 8a | On the `main $1` line: `gra` | ShellCheck quick fix offered; applying it quotes `"$1"` | FR-004 |
| 8b | `gO` | Location list shows `main` | FR-004 |
| 8c | `nvim /tmp/x.sh` (outside any repo), `:checkhealth vim.lsp` | `bashls` attached, no root | FR-003, edge case |
| 9 | `<leader>lf` in `run.sh` | Body indented with 2 spaces, `greet "$name"`; one `u` undoes it | US2-1, US2-2 |
| 10 | Save, `:!shfmt -d %` | No diff | SC-004 |
| 11 | `<leader>lf` again | Buffer not modified | US2-4 |
| 11a | `nvim /tmp/shplain/p.sh`, `<leader>lf` | `echo x` indented with 4 spaces | US2-5 |
| 12 | Make a directory with symlinks to only `nvim`, `node` and `bash-language-server`; run `PATH=<that dir>:/usr/bin:/bin nvim run.sh`, then `<leader>lf` | Single WARN `No language server can format this buffer`; no ShellCheck diagnostics; no errors | US2-3, FR-007, SC-003 |
| 12a | Add a `shfmt` symlink to scenario 12's directory (still no `shellcheck`); run `PATH=<that dir>:/usr/bin:/bin nvim run.sh`, then `<leader>lf` | No ShellCheck diagnostics, no error; buffer formatted | SC-003 |
| 12b | `:view run.sh`, `<leader>lf` | WARN `Buffer is read-only`, no change | edge case |
| 13 | Without `bash-language-server` on `PATH`: open `run.sh` | No error; `:checkhealth vim.lsp` reports it missing | FR-008, edge case |
| 14 | In `run.sh`: `:lua print(vim.treesitter.highlighter.active[0] ~= nil)`; `zc` in `main`; `vaf` | `true`; function folds; whole function selected | US3-1, US3-2 |
| 15 | `vac` / `]c` in `run.sh` | Nothing happens, no error | US3-2 |
| 16 | `nvim --headless "+qa"`; `nvim --startuptime /tmp/st.log +qa` | Exits cleanly; startup unchanged within noise | SC-002, SC-003 |
| 17 | lua_ls diagnostics on `lsp/bashls.lua`, `lua/config/lsp.lua`, `lua/config/treesitter.lua` | No errors or warnings | Principle V |
