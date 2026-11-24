# Contract: Bash Language Server and Shell Tree-sitter

This contract extends `specs/006-clangd-language-server/contracts/keymaps-and-lsp.md` and the
tree-sitter contract `specs/012-treesitter-plugins/contracts/treesitter.md`. Everything there still holds unless
changed below.

## Key mappings (none added)

`<leader>lf` (`desc = "Format buffer"`) keeps its dispatch. For every language-server format,
an edit that leaves the text identical is undone, so the buffer keeps its `'modified'` state
and gains no undo step (research R3). For `sh`/`bash` buffers:

| Buffer | Action | Messages (WARN, at most one) |
|--------|--------|------------------------------|
| read-only / not modifiable | nothing | `Buffer is read-only` |
| `sh`, `bash` with bashls attached and `shfmt` on `PATH` | `vim.lsp.buf.format` → bashls → shfmt, indentation from `'shiftwidth'`/`'expandtab'` (`.editorconfig`, else the config's 4-space default) | none |
| same, `shfmt` missing, or server missing / not attached | nothing | `No language server can format this buffer` |

- `gq` keeps plain text formatting (the server has no range formatting).
- The tree-sitter text objects and jumps (`af`/`if`/`aa`/`ia`, `]f`/`[f`) apply to shell
  buffers; `ac`/`ic`/`]c`/`[c` are mapped but find nothing (no classes in shell).

## Server guarantees (`lsp/bashls.lua`)

- Starts only when the first `sh` or `bash` buffer appears, never at startup; never for `zsh`.
- Root: the git repository; otherwise single-file mode.
- No settings passed: ShellCheck diagnostics when `shellcheck` is on `PATH`; silent without it.
- If `bash-language-server` is not on `PATH`, nothing is shown while editing;
  `:checkhealth vim.lsp` reports it.
- Diagnostics use the global display settings and toggles from `config.diagnostics`.

## Tree-sitter guarantees

- The `bash` parser is part of the parser set installed on the first supported buffer.
- `sh` and `bash` buffers get tree-sitter highlighting, folding (opened unfolded) and
  indentation; missing build tools give the existing single warning.

## README

- Requirements: `bash-language-server`, `shellcheck`, `shfmt` as optional tools, each with
  what is lost without it.
- `<leader>lf` row mentions shell scripts (`.editorconfig`).
- New "Shell scripts" section; tree-sitter section lists shell among languages and among those
  with text objects.
