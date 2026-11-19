# Contract: Diagnostic Toggles, Formatting and the Lua Server

What the user, and later features, can rely on once this feature is in place.

## Normal-mode key mappings (exactly four new ones, FR-016)

| Key | Effect | Message | `desc` |
|-----|--------|---------|--------|
| `<leader>td` | Toggle all diagnostics, globally | `Diagnostics: on` / `Diagnostics: off` | `Toggle diagnostics` |
| `<leader>tt` | Toggle diagnostic virtual text (end of line), globally | `Diagnostic virtual text: on/off` (+ ` (diagnostics are off)` while disabled) | `Toggle diagnostic virtual text` |
| `<leader>tl` | Toggle diagnostic virtual lines, globally | `Diagnostic virtual lines: on/off` (+ ` (diagnostics are off)` while disabled) | `Toggle diagnostic virtual lines` |
| `<leader>lf` | Format the whole buffer via the language server | Only on failure: `Buffer is read-only` / `No language server can format this buffer` | `Format buffer` |

- All four mappings are global, not buffer-local, and exist from startup. Their callbacks load
  `vim.diagnostic`/`vim.lsp` on first use.
- No mapping is added on `LspAttach`. Neovim's built-in LSP defaults (`K`, `grn`, `gra`,
  `grr`, `gri`, `gO`, `<C-s>`, …) are untouched.
- Messages go through `vim.notify`: INFO for toggles, WARN for format failures. Each action
  shows at most one message.
- Later features MUST NOT remap these four keys without amending this contract. A feature
  that adds another diagnostics source gets the same toggles for free, because they are
  global.

## `config.diagnostics` module API

| Function | Behaviour |
|----------|-----------|
| `setup()` | Apply the initial display (virtual text on, virtual lines off) once per session. Later calls do nothing. Never errors. Called on the first `FileType lua`, the first `DiagnosticChanged` and every toggle. |

## Server guarantees (`lsp/lua_ls.lua`)

- The server starts only when the first `lua` buffer appears. It never starts at startup with
  an empty or non-Lua buffer.
- Under a root without `.luarc.json`/`.luarc.jsonc`:
  - the `vim` global and its API resolve, with types and docs
  - `require("config.*")` resolves within this config
  - `require("<plugin>")` resolves for every plugin installed through `vim.pack`
- Under a root with `.luarc.json`/`.luarc.jsonc`, that file alone governs the server.
- If `lua-language-server` is not on `PATH`, nothing is shown while editing.
  `:checkhealth vim.lsp` reports it as not executable.
- Formatting follows the repository `.editorconfig` `[*.lua]` section.
