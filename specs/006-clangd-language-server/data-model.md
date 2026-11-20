# Data Model: clangd Language Server with Built-in Formatting

This feature stores no data. Below are the runtime structures the modules depend on.

## Filetype → server map (`lua/config/lsp.lua`)

| Filetype | Server config (`lsp/<name>.lua`) |
|----------|----------------------------------|
| `lua` | `lua_ls` |
| `cmake` | `neocmake` |
| `c`, `cpp`, `objc`, `objcpp`, `cuda` | `clangd` (NEW) |

- Several filetypes may map to the same server; the existing `enabled` set is keyed by server
  name, so `vim.lsp.enable("clangd")` still runs at most once per session, on the first
  `FileType` event of any of the five filetypes.
- `config.diagnostics.setup()` runs on that event, as before. It is idempotent.

## clangd server config (`lsp/clangd.lua`)

| Field | Value |
|-------|-------|
| `cmd` | `{ "clangd" }` (no flags; FR-004, FR-004a, FR-006) |
| `filetypes` | `{ "c", "cpp", "objc", "objcpp", "cuda" }` |
| `root_markers` | `{ { ".clangd", "compile_commands.json", "compile_flags.txt" }, ".git" }` (first group equal priority; no match means single-file mode) |
| `on_init` | none — all server capabilities, including formatting, are kept |

Rule: after attach, `supports_method("textDocument/formatting")` and
`supports_method("textDocument/rangeFormatting")` are `true`, and the buffer's `formatexpr`
is `v:lua.vim.lsp.formatexpr()`.

## `<leader>lf` dispatch (unchanged code, new reach)

```text
<leader>lf ─┬─ read-only ──────────────► "Buffer is read-only"
            ├─ filetype == cmake ──────► gersemi (feature 005)
            ├─ formatting client ──────► vim.lsp.buf.format (lua_ls, clangd)
            └─ none ───────────────────► "No language server can format this buffer"
```
