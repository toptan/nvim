# Data Model: Lua Language Server and Diagnostic Toggles

This feature stores no data. It adds one server configuration and session-only display
state, all held by Neovim core.

## Server configuration `lua_ls` (`lsp/lua_ls.lua`)

| Field | Value | Requirement |
|-------|-------|-------------|
| `cmd` | `{ "lua-language-server" }` | FR-001, R7 |
| `filetypes` | `{ "lua" }` | FR-001 |
| `root_markers` | `{ { ".luarc.json", ".luarc.jsonc" }, ".git" }` | FR-006, R4 |
| `settings.Lua` | `{}`, extended by `on_init` | R3 |
| `on_init` | Injects runtime, path and library unless the root has `.luarc.json(c)` | FR-002–FR-004 |

**Injected `Lua` settings** (only when the root has no `.luarc.json`/`.luarc.jsonc`):

| Key | Value |
|-----|-------|
| `runtime.version` | `"LuaJIT"` |
| `runtime.path` | `{ "lua/?.lua", "lua/?/init.lua" }` |
| `workspace.checkThirdParty` | `false` |
| `workspace.library` | `$VIMRUNTIME` + `path` of each `vim.pack.get()` entry |

**Lifecycle**: not loaded → (first `FileType lua`) enabled → started per root → `on_init`
evaluates the library once per server start. A server restart picks up plugin changes.

## Diagnostic display state (Neovim core, global, session only)

| Setting | Initial (FR-012) | Changed by | Source of truth |
|---------|------------------|------------|-----------------|
| enabled | on | `<leader>td` | `vim.diagnostic.is_enabled()` |
| virtual text | on | `<leader>tt` | `vim.diagnostic.config().virtual_text` |
| virtual lines | off | `<leader>tl` | `vim.diagnostic.config().virtual_lines` |

- The three settings are independent. Changing virtual text or lines while diagnostics are
  disabled is kept and applies on re-enable (FR-011).
- `config.diagnostics` holds one module-local flag, `did_setup` (boolean). It ensures the
  initial display is applied exactly once, on the first `FileType lua`, the first
  `DiagnosticChanged` or the first toggle, whichever comes first.

## Format request (`<leader>lf`)

| Buffer state | Outcome | Message |
|--------------|---------|---------|
| `readonly` or not `modifiable` | nothing changes | `Buffer is read-only` (WARN) |
| no client with `textDocument/formatting` | nothing changes | `No language server can format this buffer` (WARN) |
| formatting client attached | whole buffer formatted synchronously, one undo step | none |
