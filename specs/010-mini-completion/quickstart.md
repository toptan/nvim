# Quickstart: Validating mini.completion

Behaviour reference: [contracts/completion.md](contracts/completion.md).

## Prerequisites

- Neovim ≥ 0.12, `git`, `lua-language-server` and `clangd` on `PATH`.
- Scratch files: a `.lua` file, a `.cpp` file with `#include <string>` and a struct with fields
  `alpha` / `beta`, a `.txt` file containing `alphabet alphanumeric`.
- Use `nvim -n` (no swap file) when driving the editor from tmux.

## Scenarios

| # | Steps | Expected |
|---|-------|----------|
| 1 | Lua file: `o`, type `vim.ap` | Menu with `api` (Field) etc. without a key press (US1-1) |
| 2 | In 1: `<Tab>` | `api` highlighted, text still `vim.ap`; ` Info ` window with docs (US1-5, US2-1) |
| 3 | In 2: `<CR>` | Text becomes `vim.api`, no new line (US2-2) |
| 4 | Type `.nvim_buf_get_li`, accept, type `(` | ` Signature ` window with parameters |
| 5 | Menu open, nothing highlighted: `<CR>` | Menu closes, new line inserted (US2-3) |
| 6 | `.txt` file: `o`, type `alp` | Menu with `alphabet`, `alphanumeric` (clarification Q2) |
| 7 | C++: `std::stri` / `q->` / `p.` | `string`… / `alpha`, `beta` / `alpha`, `beta` (US1-2) |
| 8 | C++: `std::to_stri`, `<Tab>`, `<CR>` | `std::to_string(…)` with placeholder selected; exactly one Info window while highlighted (US1-6) |
| 9 | In 8: type `42`, `<Tab>` | Placeholder replaced; `<Tab>` jumps/exits snippet (US2-4) |
| 10 | Empty line: `<C-Space>` (or `<C-@>`) | Menu opens immediately (US2-5) |
| 11 | Normal mode `<Tab>` / `<S-Tab>` | Buffer switching unchanged |
| 12 | `grep -n "autocomplete\|TextChangedP\|matchfuzzypos\|LspDetach" lua/config/completion.lua` | No matches (US3-1, SC-003) |

## Startup and robustness

```sh
nvim --headless "+qa"                        # exit 0, no output (plugin installed)
for i in 1 2 3 4 5; do nvim --headless --startuptime /dev/stdout "+qa" | tail -1; done
                                             # each < 100 ms, ≈ current (~12 ms)
```

- Fresh install: move `stdpath("data")/site/pack/core/opt/mini.completion` away, start the
  editor, enter Insert mode → plugin installs without prompts, scenario 1 works (US4-1).
- Unavailable: temporarily change the URL to a non-existent repo, start, enter Insert mode →
  one WARN notice, no errors; `<Tab>` / `<CR>` still work; `<C-n>` gives built-in completion
  (US4-2). Revert and delete the bogus lockfile entry afterwards.
- `:checkhealth` shows no new errors; lua_ls reports no diagnostics in changed files.
