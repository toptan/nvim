# Data Model: CMake Language Server with Gersemi Formatting

This feature stores no data. Below are the runtime structures the modules depend on.

## Filetype → server map (`lua/config/lsp.lua`)

| Filetype | Server config (`lsp/<name>.lua`) |
|----------|----------------------------------|
| `lua` | `lua_ls` |
| `cmake` | `neocmake` |

- Each server is enabled at most once per session, on the first `FileType` event for its
  filetype. An enabled server is never enabled again (`vim.lsp.enable` also attaches the
  buffer that triggered it).
- `config.diagnostics.setup()` runs on the first such event. It is idempotent.

## neocmake server config (`lsp/neocmake.lua`)

| Field | Value |
|-------|-------|
| `cmd` | `{ "neocmakelsp", "stdio" }` |
| `filetypes` | `{ "cmake" }` |
| `root_markers` | `{ ".git", "CMakeLists.txt" }` (priority order; no match means single-file mode) |
| `on_init` | Sets the document, range and on-type formatting providers to `false` |

Rule: after `on_init`, `supports_method("textDocument/formatting")` and
`supports_method("textDocument/rangeFormatting")` are `false` for this client.

## Gersemi format request (`lua/config/gersemi.lua`)

| Item | Source |
|------|--------|
| Input text | All buffer lines joined with `\n`, plus a trailing `\n` |
| `--stdin-filepath` | The buffer's absolute file name; left out when the buffer has no name |
| Working directory | The buffer's directory, or `getcwd()` when the buffer has no name |
| Timeout | 5000 ms |

**Outcome states**

```text
          ┌─ not executable ─────────► NotInstalled  (WARN, buffer untouched)
request ──┼─ exit ≠ 0 ───────────────► Failed        (WARN with stderr line, untouched)
          ├─ timeout ────────────────► TimedOut      (WARN, untouched)
          └─ exit 0 ─┬─ same text ───► Unchanged     (silent, not modified)
                     └─ differs ─────► Applied       (silent, one undo step)
```
