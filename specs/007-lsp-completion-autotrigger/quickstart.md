# Quickstart: Validating Auto-triggered Completion

## Prerequisites

- `lua-language-server` and `clangd` on `PATH` (see README).
- A scratch C++ project with a compilation database:

```sh
mkdir -p /tmp/cmp && cd /tmp/cmp && git init -q
printf 'int add(int a, int b) { return a + b; }\nint main() {\n  \n}\n' > m.cpp
printf '[{"directory":"/tmp/cmp","file":"/tmp/cmp/m.cpp","arguments":["clang++","-std=c++20","-c","m.cpp"]}]\n' > compile_commands.json
printf 'local apple_pie = 1\nlocal apricot = 2\n' > /tmp/cmp/x.lua
```

Open files with `nvim`, wait until `:lsp` (or `:checkhealth vim.lsp`) shows the server
attached, then follow the steps in insert mode. Typing each key separately at normal speed is
assumed.

## Scenarios

| # | File / steps | Expected | Covers |
|---|--------------|----------|--------|
| 1 | `x.lua`: `G`, `o` | No menu on the new line | US1, R3 |
| 2 | type `vim.` | Menu opens, nothing highlighted, server items (`api`, `fn`, …) | US1-1, US1-2 |
| 3 | type `ap` | List narrows; `api` is the first item | US1-3, FR-001a |
| 4 | `<Tab>` `<Tab>` `<S-Tab>` | Highlight: first, second, first; line still `vim.ap` | US2-1, US2-2, FR-003 |
| 5 | `<CR>` | `vim.api` inserted, no new line, menu closed | US2-3, SC-002 |
| 6 | new line, type `ap` | Menu: server items (`apricot`, `apple_pie` from lua_ls) first, no duplicate buffer words | US1-6, FR-001a |
| 7 | `<Tab>`, then `<Esc>` | Line is `ap` | US4-5, SC-006 |
| 8 | `o`, type `apr`, `<CR>` | Line `apr` kept, new line opened | US2-4, FR-008 |
| 9 | with the menu closed: `<Tab>`, `<CR>` | Indent inserted; new line | US2-5, FR-009 |
| 10 | type `vim.ap`, `<C-e>`, then `<C-Space>` | Menu reopens filtered to `ap`, nothing highlighted | US3-1 |
| 11 | type `vim.`, `<C-e>`, then `<C-Space>` | Server items for `vim.` | FR-010 |
| 12 | type `x`, `<C-e>`, `<C-n>` `<C-n>` `<C-y>` / `<C-e>` / `<C-x><C-o>` | Stock behaviour (`<C-n>` previews; `<C-e>` restores; omni menu opens) | US4, FR-011 |
| 13 | `m.cpp`: line 3, `A`, type `std::string_v`, `<Tab>`, `<CR>` | `std::string_view` and `#include <string_view>` at the top; one `u` removes both | US2-3, spec 006 FR-004b |
| 14 | new line, type `add`, `<Tab>`, `<CR>`, then `1`, `<Tab>`, `2` | `add(1, 2)` | US2-6 |
| 15 | new line, type `add(`, then with the menu open inside a placeholder press `<Tab>` | Highlight moves in the menu, cursor stays | US2-6 |
| 16 | `nvim /tmp/cmp/README` (no server), type `ap`, `<C-Space>` | No menu, nothing inserted, no message | US1-5, US3-2, FR-002 |
| 17 | normal mode `<Tab>` | Next buffer (unchanged) | FR-012 |
| 18 | in a terminal emulator: `<C-Space>` after a word | Same as #10 (terminal sends `<C-@>`) | edge case |
| 19 | `:verbose imap <Tab>` etc. for the four keys | Each mapping has the contract's `desc` | FR-012 |
| 20 | `qq` + `ovim.ap<Tab><CR><Esc>q`, then `@q` | Recording works as typed; the replay adds `vim.ap` with a Tab and a new line (keys replay before the server answers), no error | edge case (macro) |
| 21 | `m.cpp` and `x.lua`: type a 30-character line (e.g. `int value = add(counter, other);`) as fast as you can | Every character appears immediately; no visible pause | SC-004, FR-005 |
| 22 | `m.cpp`: type `std::` and press `<Esc>` at once, before the menu appears | No menu appears afterwards in normal mode or on re-entering insert mode elsewhere | FR-005 (stale results) |
| 23 | `m.cpp`: `:lsp stop clangd`, then in insert mode type `ad` several times | No message; no automatic menu (stock completion, `<C-n>` offers `add`); `:setlocal autocomplete?` shows it off | edge cases (server stops) |
| 24 | `x.lua`: type `ap`, `<C-n>` (item previewed), `<Esc>`; then `oap`, `<C-n>`, `<C-e>` | First line keeps the previewed item; second line is `ap` | US4-5, FR-003 |

## Automated checks

```sh
nvim --headless "+qa"                     # no output, exit code 0 (FR-013)
nvim --startuptime /tmp/st.log +qa && tail -1 /tmp/st.log   # < 100 ms (SC-005)
nvim --headless -c "checkhealth vim.lsp" -c "w! /tmp/h.txt" -c qa   # no new ERROR lines
```

Lua files changed by this feature must have no lua_ls diagnostics errors or warnings.
