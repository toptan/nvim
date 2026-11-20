# Neovim daily driver config

## Requirements

- Neovim 0.12 or newer (uses the built-in `catppuccin` colour scheme)
- [`lua-language-server`](https://github.com/LuaLS/lua-language-server) on `PATH`
  (`brew install lua-language-server`). Optional: without it Lua editing works as usual
  without language features, and `:checkhealth vim.lsp` reports it as missing.
- [`neocmakelsp`](https://github.com/neocmakelsp/neocmakelsp) 0.11 or newer on `PATH`
  (`brew install neocmakelsp` or `cargo install neocmakelsp`). Optional, like
  `lua-language-server`: without it CMake files get no language features and
  `:checkhealth vim.lsp` reports it as missing.
- [`gersemi`](https://github.com/BlankSpruce/gersemi) on `PATH` (`pipx install gersemi`).
  Optional: only `<leader>lf` in a CMake file needs it, and says so when it is missing.

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
| `<leader>lf` | Format the buffer with its language server (follows `.editorconfig`), or with gersemi for CMake |

The counter stays until highlights are cleared, the buffer is edited, or another buffer
is shown. In terminals `<Tab>` and `<C-i>` are the same key, so jump-forward (`<C-i>`) is
not available; `<C-o>` (jump back) still works.

## Popups

Floating windows (diagnostics via `<C-w>d`, hover, signature help) have a rounded border in
the colour scheme's title colour. The diagnostic popup is titled and names the source of
each entry.

## Lua language server

`lua_ls` starts when the first Lua file is opened. In this config, and in any Lua project
without its own `.luarc.json`, it knows the Neovim runtime (`vim.*`) and every plugin
installed with `vim.pack`; restart it with `:lsp restart` after adding a plugin. Projects
with their own `.luarc.json` keep their settings.

## CMake

`neocmakelsp` starts when the first CMake file (`CMakeLists.txt`, `*.cmake`) is opened. Its
root is the git repository, otherwise the nearest directory with a `CMakeLists.txt`;
otherwise it works on the single file. Its formatter is switched off: `<leader>lf` formats
CMake with gersemi, using the project's `.gersemirc` (next to the file or in a parent
directory) or gersemi's defaults, and `gq` does plain text formatting. Restart the server
with `:lsp restart` after changing the CMake build.
