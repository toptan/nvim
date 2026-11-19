# Neovim daily driver config

## Requirements

- Neovim 0.12 or newer (uses the built-in `catppuccin` colour scheme)
- [`lua-language-server`](https://github.com/LuaLS/lua-language-server) on `PATH`
  (`brew install lua-language-server`). Optional: without it Lua editing works as usual
  without language features, and `:checkhealth vim.lsp` reports it as missing.

## Key mappings

Normal mode only; the leader key is Space.

| Key | Action |
|-----|--------|
| `<Esc>` | Clear search highlights and the match counter |
| `<Tab>` / `<S-Tab>` | Next / previous file buffer (open order, wraps; skips help, quickfix and terminal buffers) |
| `n` `N` `*` `#` `g*` `g#` | Native search jumps, plus a `[current/total]` counter right-aligned on the match's line |
| `<leader>td` | Toggle all diagnostics (every buffer) |
| `<leader>tt` | Toggle diagnostic virtual text at the end of the line (on by default) |
| `<leader>tl` | Toggle diagnostic virtual lines below the code (off by default) |
| `<leader>lf` | Format the buffer with its language server (follows `.editorconfig`) |

The counter stays until highlights are cleared, the buffer is edited, or another buffer
is shown. In terminals `<Tab>` and `<C-i>` are the same key, so jump-forward (`<C-i>`) is
not available; `<C-o>` (jump back) still works.

## Lua language server

`lua_ls` starts when the first Lua file is opened. In this config, and in any Lua project
without its own `.luarc.json`, it knows the Neovim runtime (`vim.*`) and every plugin
installed with `vim.pack`; restart it with `:lsp restart` after adding a plugin. Projects
with their own `.luarc.json` keep their settings.
