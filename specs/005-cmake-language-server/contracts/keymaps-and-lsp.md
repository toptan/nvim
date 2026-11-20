# Contract: CMake Server and `<leader>lf` Dispatch

This contract extends `specs/003-lua-language-server/contracts/keymaps-and-lsp.md`. Everything
there still holds unless it is changed below.

## Key mappings (no new ones, FR-010)

`<leader>lf` (`desc = "Format buffer"`) now dispatches on the buffer's filetype:

| Buffer | Action | Messages (WARN, at most one) |
|--------|--------|------------------------------|
| read-only / not modifiable | nothing | `Buffer is read-only` |
| `filetype == "cmake"` | `require("config.gersemi").format(0)` | `gersemi is not installed`, `gersemi: <error>`, `gersemi timed out` |
| any other | LSP formatting, unchanged from 003 | `No language server can format this buffer` |

- In CMake buffers gersemi is never combined with, or replaced by, LSP formatting.
- No mapping is added on `LspAttach`.

## `config.gersemi` module API

| Function | Behaviour |
|----------|-----------|
| `format(bufnr)` | Formats the whole buffer with gersemi as described in data-model.md. Returns nothing and never raises. Shows at most one WARN notice. Loaded only on first use. |

## Server guarantees (`lsp/neocmake.lua`)

- Starts only when the first `cmake` buffer appears, never at startup.
- Root: the git repository, otherwise the nearest directory with a `CMakeLists.txt`,
  otherwise single-file mode.
- Never offers formatting. `vim.lsp.buf.format()` skips it, and `formatexpr` is not set, so
  `gq` uses plain text formatting.
- If `neocmakelsp` is not on `PATH`, nothing is shown while editing.
  `:checkhealth vim.lsp` reports it.
- Its diagnostics use the global display settings and toggles from `config.diagnostics`.
