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
- [`clangd`](https://clangd.llvm.org) on `PATH` (`brew install llvm`, or the Xcode command
  line tools). Optional, like `lua-language-server`: without it C and C++ files get no
  language features, `<leader>lf` says no language server can format them, and
  `:checkhealth vim.lsp` reports it as missing.
- `git` on `PATH`: Neovim's built-in plugin manager (`vim.pack`) uses it to install plugins
  on the first start, without a prompt.
- For tree-sitter parsers: the
  [`tree-sitter`](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md)
  CLI 0.26.1 or newer (`brew install tree-sitter-cli`, not the npm package), a C compiler,
  `curl` and `tar`. Without them the editor works as before, and opening the first
  supported file shows one warning naming what is missing.

### Plugins

Installed automatically by `vim.pack`; everything else is built into Neovim.

- [`mini.notify`](https://github.com/nvim-mini/mini.notify): Neovim has no notification
  popup. Without network on the first start the install fails with a notice, and
  notifications appear on the command line as in stock Neovim until the next start.
- [`mini.completion`](https://github.com/nvim-mini/mini.completion): Neovim's built-in
  automatic completion cannot merge language server and buffer suggestions without a lot of
  custom code. Installed the first time you enter insert mode; without network the install
  fails with a notice, and Neovim's manual completion keys (`<C-n>`, `<C-x><C-o>`) remain.
- [`mini.clue`](https://github.com/nvim-mini/mini.clue): Neovim cannot show which keys may
  follow a partially typed key sequence. Without network on the first start the install
  fails with a notice, and keys work as in stock Neovim, without clues.
- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter): Neovim has no
  parser installer or updater, ships few parsers and queries, and has no tree-sitter
  indentation. See [Tree-sitter](#tree-sitter).
- [`nvim-treesitter-textobjects`](https://github.com/nvim-treesitter/nvim-treesitter-textobjects):
  Neovim has no syntax-aware text objects or function/class jumps.

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
| `<leader>lf` | Format the buffer with its language server (Lua follows `.editorconfig`, C and C++ follow `.clang-format`), or with gersemi for CMake |
| `<leader>ld` | List the buffer's diagnostics in the location list (see [Diagnostics list](#diagnostics-list)) |
| `<leader>lD` | List the workspace's diagnostics in the location list |

Tree-sitter text objects and jumps (only in buffers whose language has them, see
[Tree-sitter](#tree-sitter)):

| Key | Modes | Action |
|-----|-------|--------|
| `af` / `if` | visual, operator-pending | Around / inside function |
| `ac` / `ic` | visual, operator-pending | Around / inside class |
| `aa` / `ia` | visual, operator-pending | Around / inside parameter |
| `]f` / `[f` | normal, visual, operator-pending | Start of next / previous function (count, jump list) |
| `]c` / `[c` | normal, visual, operator-pending | Start of next / previous class; in diff mode the built-in next / previous change |

The counter stays until highlights are cleared, the buffer is edited, or another buffer
is shown. In terminals `<Tab>` and `<C-i>` are the same key, so jump-forward (`<C-i>`) is
not available; `<C-o>` (jump back) still works.

## Key clues

[`mini.clue`](https://github.com/nvim-mini/mini.clue) shows the keys that may follow, with
the triggers and clues of its config quick start. After you press a trigger key and pause for
a second, a window in the bottom right corner lists every key that can come next and what it
does, including your own mappings with their descriptions. Typing a sequence quickly never
shows the window, and every sequence does exactly what it does without the plugin.

| Trigger | Modes | Lists |
|---------|-------|-------|
| `<leader>` | Normal, Visual | Your leader mappings; groups `l` Language and `t` Toggle |
| `[` / `]` | Normal | Bracket motions (`]d`, `[q` …) |
| `g` | Normal, Visual | `g` commands, including language server ones (`gr…`) |
| `z` | Normal, Visual | Fold, scroll and spelling commands |
| `'` / `` ` `` | Normal, Visual | Marks and where they are |
| `"` | Normal, Visual | Registers and their contents |
| `<C-w>` | Normal | Window commands |
| `<C-x>` | Insert | Built-in completion modes |
| `<C-r>` | Insert, Command-line | Registers and their contents |

In the window, a listed key runs its command or opens the next level, `<BS>` goes back one
key, `<Esc>` cancels, and `<C-d>` / `<C-u>` scroll a long list. Clues are off while a macro
is being recorded. The leader groups exist in Visual mode too, but have no mappings there yet,
so `<leader>l` in Visual mode just runs as plain keys.

## Completion

Completion is provided by [`mini.completion`](https://github.com/nvim-mini/mini.completion)
with its default settings, loaded the first time you enter insert mode. In every buffer a
completion menu opens by itself shortly after you pause while typing a word, and at once after
a language server's trigger character such as `.`, `->` or `::`. It lists the server's
suggestions; when the server has none, or the buffer has no server, it lists matching words
from open buffers instead. The menu narrows as you type. Nothing is selected or inserted until
you choose; snippet items are marked `S` and expand with jumpable placeholders.

A window titled "Info" shows the documentation of the highlighted item, and inside a
function call's arguments a window titled "Signature" shows its parameters.

| Key (insert mode) | Action |
|-----|--------|
| `<Tab>` / `<S-Tab>` | Menu open: next / previous item, without inserting it. Otherwise: jump between snippet placeholders, or a plain Tab |
| `<CR>` | Menu open with an item selected: accept it. Otherwise: new line |
| `<C-Space>` | Open the menu (`<C-@>` too, which is what most terminals send) |
| `<A-Space>` | Open the menu with words from open buffers only |
| `<C-f>` / `<C-b>` | Scroll the Info or Signature window |

Neovim's own keys still work: `<C-y>` accepts, `<C-e>` closes the menu and restores what you
typed, `<Up>` / `<Down>` move like `<Tab>` / `<S-Tab>`. `<C-n>` / `<C-p>` move as well but,
as always in Neovim, put the item into the text while you move. `<C-@>` no longer inserts
the previously typed text.

## Diagnostics list

`<leader>ld` lists the current buffer's diagnostics and `<leader>lD` every diagnostic the
editor holds for any file, in the location list of the current window. The list opens
below the window and takes the cursor. Entries are ordered by severity (errors, warnings,
info, hints), then by file, line and column. Each entry's severity and message are shown
in that severity's diagnostic colour; file name and line/column keep the list's usual
colours. Diagnostics turned off with `<leader>td` are not listed, and when there is
nothing to list a notification says so instead of opening an empty list.

In any location list window, `<CR>` jumps to the entry and moves the cursor to the file
(the list stays open, so `<C-w>j` goes back to it) and `<Esc>` closes the list and returns
to the file. Quickfix windows keep the usual `<Esc>`. Pressing either key again refreshes
the list in the same window; an unrelated location list (for example from `:lvimgrep`)
stays reachable with `:lolder`. The list is a snapshot and does not update by itself.

`<leader>lD` first asks the buffer's language servers that support it to check the whole
project, waiting at most 2 seconds. Neither configured server needs this: `lua_ls`
reports problems in unopened files of its workspace on its own shortly after the first
Lua file is opened, and `clangd` only reports files that are open.

## Popups

Floating windows (diagnostics via `<C-w>d`, hover, signature help, and the completion Info
and Signature windows) have a rounded border in the colour scheme's title colour. The diagnostic popup is titled and names the source of
each entry.

## Notifications

Notifications (for example `Diagnostics: off` from `<leader>td`, or anything sent with
`vim.notify`) are shown by [`mini.notify`](https://github.com/nvim-mini/mini.notify) with its
default settings: a popup titled "Notifications" in the top right corner, with the same
border as other popups. It never takes focus. Each notification is prefixed with its time, coloured by level
(error, warning, info), and listed newest first.

Each notification disappears 5 seconds after it appeared, and the popup closes with the last
one. Debug and trace notifications are ignored. Language server progress (for example while
`lua_ls` loads a workspace) is shown there too.

Notifications are not kept in `:messages`. To see this session's notifications, run
`:lua MiniNotify.show_history()`.

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

## C and C++

`clangd` starts when the first C, C++, Objective-C or CUDA file (sources and headers) is
opened. Its root is the nearest directory with a `.clangd`, `compile_commands.json` or
`compile_flags.txt`, otherwise the git repository; otherwise it works on the single file.

clangd finds `compile_commands.json` next to the file, in a parent directory, or in a
`build/` directory at any of those levels. For another build directory, either add a
`.clangd` file to the project root:

```yaml
CompileFlags:
  CompilationDatabase: build-debug
```

or link the database into the root (`ln -s build-debug/compile_commands.json .`). Without a
database clangd uses default flags, so project headers may be reported as missing.

`<leader>lf` formats the whole buffer and `gq` the selected lines, both through clangd with the
project's `.clang-format` (next to the file or in a parent directory) or clangd's fallback
style. In completion, accepting an item (`<CR>` or `<C-y>`) also inserts a missing
`#include` and expands function argument placeholders; with the menu closed, `<Tab>` /
`<S-Tab>` jump between them.

clangd keeps its index in `.cache/clangd/` next to the compilation database, usually inside an
ignored build directory; with a database linked into the project root, ignore `.cache/` there.
Restart the server with `:lsp restart` after regenerating the database.

## Tree-sitter

[`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) (parsers, queries,
indentation) and
[`nvim-treesitter-textobjects`](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)
are installed by `vim.pack` on the first start, but loaded only when the first file of a
supported language is opened. Languages: asm, C, C++, CMake, EditorConfig, Lua, Markdown
(with inline Markdown), Python, Vim script and Neovim help; regular expressions are
highlighted where these languages embed them.

- **Parsers** for these languages are installed in the background when the first supported
  file is opened; that file switches to tree-sitter by itself once its parser is ready.
  Whenever `vim.pack` installs or updates either plugin, the parsers are updated once (at
  the latest when the next supported file is opened).
- **Features**: tree-sitter highlighting everywhere; folding (files open unfolded) except
  for asm and help; indentation except for asm, EditorConfig, Vim script and help, which
  keep Neovim's own. Other languages are unchanged.
- **Text objects and jumps** (see [Key mappings](#key-mappings)) exist in C, C++, CMake,
  Lua, Markdown (class = section), Python and Vim script; where a language has no such
  construct the key does nothing.
- `:TSInstall`, `:TSUpdate` and `:checkhealth nvim-treesitter` are available only after a
  supported file has been opened in the session.
