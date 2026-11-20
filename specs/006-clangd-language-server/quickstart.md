# Quickstart: Validating clangd Support

## Prerequisites

- `clangd` and `clang-format` from the same LLVM installation on `PATH` (e.g.
  `brew install llvm`; `clangd --version` and `clang-format --version` report the same version)
- A scratch C++ project with its compilation database in a non-standard build directory:

```sh
mkdir -p /tmp/cpp/src /tmp/cpp/include /tmp/cpp/build-debug && cd /tmp/cpp && git init -q
printf '#pragma once\n/// Adds two ints.\nint add(int a, int b);\n' > include/util.h
printf '#include "util.h"\nint add(int a,int b){return a+b;}\n' > src/util.cpp
printf '#include "util.h"\nint main(){\n      return add(1,2);}\n' > src/main.cpp
printf 'BasedOnStyle: LLVM\nIndentWidth: 4\n' > .clang-format
printf '[{"directory":"/tmp/cpp","file":"/tmp/cpp/src/main.cpp","arguments":["clang++","-I/tmp/cpp/include","-c","src/main.cpp"]},{"directory":"/tmp/cpp","file":"/tmp/cpp/src/util.cpp","arguments":["clang++","-I/tmp/cpp/include","-c","src/util.cpp"]}]\n' > build-debug/compile_commands.json
```

## Scenarios

| # | Steps | Expected | Covers |
|---|-------|----------|--------|
| 1 | `nvim` on an empty buffer, then `:lua print(#vim.lsp.get_clients())` | `0` | US1-7 |
| 2 | `nvim /tmp/cpp/src/main.cpp`, then `:checkhealth vim.lsp` | `clangd` attached within 5 s, root `/tmp/cpp` | US1-1, FR-003 |
| 3 | Look at diagnostics in `main.cpp` | `util.h` not found (database in `build-debug/` is not searched) | edge case, Q3 |
| 4 | `printf 'CompileFlags:\n  CompilationDatabase: build-debug\n' > /tmp/cpp/.clangd`, then `:lsp restart` | 0 diagnostics | US1-6, SC-004, FR-004 |
| 5 | `K` on `add`; `<C-]>` on `add` | Bordered hover with "Adds two ints."; jumps to the definition in `util.cpp` (the declaration in `util.h` before the index is built) | US1-3, US1-4 |
| 6 | `grr` on `add` | Quickfix lists `main.cpp` and `util.cpp` uses/definition | FR-002 |
| 7 | Add `#include <vector>` above `main`, type `std::vec` then `<C-x><C-o>` | `vector` offered | US1-2 |
| 8 | Remove the `<vector>` include, type `std::vector<int> v;`, type `std::str`, `<C-x><C-o>`, select `string`, accept with `<C-y>` | Completion also inserts `#include <string>`; one `u` removes both | US1-2, Q2, FR-004b |
| 9 | Type `int x = "a";`, then `<leader>td`, `<leader>tt` | Diagnostic (source `clang`) shown; toggles hide and show it | US1-5 |
| 10 | Undo the error, `<leader>lf` | Buffer equals `clang-format --assume-filename=src/main.cpp < src/main.cpp` (4-space indent) | US2-1, US2-2, SC-002 |
| 11 | `:w`, then `<leader>lf` again | No change; `:set modified?` shows `nomodified` | US2-4, FR-007, SC-003 |
| 12 | After step 10, press `u` once | The original text is back | US2-5 |
| 13 | Mis-indent two lines, `Vjgq` on them; `:set formatexpr?` | Only those lines reformatted; `formatexpr=v:lua.vim.lsp.formatexpr()` | US2-7, FR-008a |
| 14 | `rm /tmp/cpp/.clang-format`, `<leader>lf` on a mis-indented buffer | clangd fallback style (LLVM, 2-space indent) | US2-3, FR-006 |
| 15 | Start nvim with clangd hidden from `PATH` (`PATH=$(dirname $(command -v nvim)):/usr/bin:/bin nvim src/main.cpp`, check `:echo executable("clangd")` is `0`) | No message; `:checkhealth vim.lsp` reports it missing; `<leader>lf` says `No language server can format this buffer` | FR-012, US2-6 |
| 16 | `:set ro`, then `<leader>lf` | `Buffer is read-only` | edge case |
| 17 | Open a config `.lua` file and `CMakeLists.txt` from feature 005 alongside, `<leader>lf` in each | lua_ls and gersemi as before; three clients running, each on its own filetypes | FR-009, edge case |
| 18 | `printf 'int main(){return 0;}\n' > /tmp/lone.c`, `nvim /tmp/lone.c`, then `:lua print(vim.lsp.get_clients({name="clangd"})[1].root_dir)` | Client attached; prints `nil` (single-file mode) | FR-003, edge case |
| 19 | With `main.cpp` open, `:!pkill clangd`, keep editing and save | Editor usable; at most one message about the exited client | edge case (server crash) |
| 20 | `nvim /tmp/cpp/include/util.h`, `:set ft?` | `filetype=cpp`; clangd attached | edge case (headers) |
| 21 | In a Lua file, `<C-x><C-o>` after `vim.` and accept with `<C-y>`; type in both a Lua and a C++ buffer | Completion works as before; nothing pops up while typing in either file type | FR-004b, FR-009 |
| 22 | In `main.cpp`, type `ad`, `<C-x><C-o>`, select `add`, accept with `<C-y>`, then `<Tab>` | `add(int a, int b)` with `a` selected as a placeholder, and `<Tab>` moves to `b`; leave insert mode, press `u` once, and the inserted call is gone | FR-004b |

## Repository checks

```sh
nvim --headless "+qa"                     # no output, exit 0 (also with clangd missing from PATH)
nvim --startuptime /tmp/st.log +qa && tail -1 /tmp/st.log   # < 100 ms
```
