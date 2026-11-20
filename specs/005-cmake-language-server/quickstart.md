# Quickstart: Validating CMake Support

## Prerequisites

- `neocmakelsp` (≥ 0.11, takes the `stdio` subcommand) and `gersemi` on `PATH`
- A scratch CMake project:

```sh
mkdir -p /tmp/cmk/cmake && cd /tmp/cmk && git init -q
printf 'function(my_helper t)\nmessage(STATUS ${t})\nendfunction()\n' > cmake/helpers.cmake
printf 'cmake_minimum_required(VERSION 3.20)\nproject(demo)\ninclude(cmake/helpers.cmake)\nADD_EXECUTABLE(demo   main.cpp)\nmy_helper(demo)\n' > CMakeLists.txt
```

## Scenarios

| # | Steps | Expected | Covers |
|---|-------|----------|--------|
| 1 | `nvim` on an empty buffer, then `:lua print(#vim.lsp.get_clients())` | `0` | US1-6 |
| 2 | `nvim /tmp/cmk/CMakeLists.txt`, then `:checkhealth vim.lsp` | `neocmake` attached within 5 s, root `/tmp/cmk` | US1-1, FR-003 |
| 3 | `K` on `add_executable`; `<C-]>` on `my_helper` | Bordered hover docs; jumps into `cmake/helpers.cmake` | US1-3, US1-4 |
| 4 | Type `add_` then `<C-x><C-o>` | CMake commands offered | US1-2 |
| 5 | Add a line `if(A`, then `<leader>td`, `<leader>tt` | Diagnostic shown; toggles hide and show it | US1-5 |
| 6 | `:set formatexpr?` and `:lua print(vim.lsp.get_clients({name="neocmake"})[1]:supports_method("textDocument/formatting"))` | `formatexpr=` (empty) and `false` | FR-004 |
| 7 | Remove the bad line, then `<leader>lf` | Buffer matches `gersemi --stdin-filepath CMakeLists.txt - < CMakeLists.txt` | US2-1, SC-002 |
| 8 | `:w`, then `<leader>lf` again | No change; `:set modified?` still shows `nomodified` | US2-4, FR-008, SC-004 |
| 9 | After step 7, press `u` once | The original text is back | US2-5 |
| 10 | Add `.gersemirc` with `indent: 2`, then `<leader>lf` | 2-space indentation | US2-2, FR-006 |
| 11 | Add `if(A`, then `<leader>lf` | One `gersemi: …unbalanced parentheses` notice; buffer unchanged | US2-6 |
| 12 | Start nvim with `PATH` lacking gersemi's directory, e.g. `PATH=$(dirname $(command -v nvim)):/usr/bin:/bin nvim CMakeLists.txt` (check `:echo executable("gersemi")` is `0`), then `<leader>lf` | `gersemi is not installed`; buffer unchanged | US2-7 |
| 13 | Start with neocmakelsp hidden from `PATH`, open the file | No message; `:checkhealth vim.lsp` reports it missing | FR-012 |
| 14 | `:set ro`, then `<leader>lf` | `Buffer is read-only` | edge case |
| 15 | Open a config `.lua` file, then `<leader>lf` | Formatted by lua_ls as before; both servers running | FR-009 |
| 16 | `vipgq` on a long comment line in CMakeLists.txt | Plain text wrap at `textwidth`; no LSP request | Q1 |
| 17 | `printf 'project(x)\n' > /tmp/lone.cmake` (outside any repo or CMake project), `nvim /tmp/lone.cmake`, then `:lua print(vim.lsp.get_clients({name="neocmake"})[1].root_dir)` | Client attached; prints `nil` (single-file mode, no home scan) | FR-003, edge case |
| 18 | With `CMakeLists.txt` open and `neocmake` attached, run `:!pkill neocmakelsp`, then keep editing and save | Editor stays usable; at most one message about the exited client; no repeated errors | edge case (server crash) |
| 19 | `:enew`, `:set ft=cmake`, type `ADD_EXECUTABLE(x   a.cpp)`, `<leader>lf` | Becomes `add_executable(x a.cpp)`; no error | FR-005, edge case (unnamed buffer) |

## Repository checks

```sh
nvim --headless "+qa"                     # no output, exit 0 (also with tools missing from PATH)
nvim --startuptime /tmp/st.log +qa && tail -1 /tmp/st.log   # < 100 ms
```
