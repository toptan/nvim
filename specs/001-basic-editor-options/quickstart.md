# Quickstart: Validate Basic Editor Options

Run from the repository root (`~/.config/nvim`). Requires Neovim 0.12+.

## 1. Clean startup (FR-014, SC-002)

```sh
nvim --headless "+qa"; echo "exit=$?"
```

Expected: no output, `exit=0`.

## 2. Settings catalogue (SC-001)

Prints every value from [data-model.md](data-model.md):

```sh
nvim --headless -c 'lua
local o, g = vim.o, vim.g
for _, k in ipairs({ "expandtab", "tabstop", "shiftwidth", "softtabstop", "number",
  "relativenumber", "scrolloff", "cursorline", "colorcolumn", "signcolumn", "list",
  "listchars" }) do print(k, vim.inspect(o[k])) end
for _, k in ipairs({ "mapleader", "maplocalleader", "loaded_python3_provider",
  "loaded_node_provider", "loaded_ruby_provider", "loaded_perl_provider",
  "have_nerd_font", "colors_name" }) do print(k, vim.inspect(g[k])) end' -c q 2>&1
```

Expected: values match the data-model tables; `colors_name "catppuccin"`. Compare `listchars`
by its entries, not their order — Neovim prints them alphabetically
(`extends:›,nbsp:␣,precedes:‹,tab:» ,trail:·`).

## 3. Providers disabled (FR-013, SC-003)

```sh
nvim --headless -c 'checkhealth vim.provider' -c 'w! /tmp/health.txt' -c qa
grep -iE 'disabled|error|warn' /tmp/health.txt
```

Expected: Python 3, Node.js, Ruby and Perl each reported as disabled; no ERROR/WARNING lines.

## 4. Transparency survives reloads (FR-007, edge cases)

```sh
nvim --headless -c 'lua
local function bg(n) return vim.api.nvim_get_hl(0, { name = n, link = false }).bg end
print("start", bg("Normal"), bg("SignColumn"), bg("LineNr"), bg("EndOfBuffer"))
vim.o.background = vim.o.background == "dark" and "light" or "dark"
print("after bg switch", bg("Normal"), bg("SignColumn"))
vim.cmd.colorscheme("catppuccin")
print("after reload", bg("Normal"), bg("SignColumn"))' -c q 2>&1
```

Expected: every value printed is `nil` (no background).

## 5. Indentation overrides (FR-001, FR-002, FR-002a)

```sh
nvim --headless -c 'lua
for _, f in ipairs({ "/tmp/x.txt", "init.lua", "/tmp/Makefile" }) do
  vim.cmd.edit(f)
  print(f, vim.bo.expandtab, vim.bo.tabstop, vim.bo.shiftwidth, vim.bo.softtabstop)
end' -c 'qa!' 2>&1
```

Expected:

| File | expandtab | tabstop | shiftwidth | softtabstop |
|------|-----------|---------|------------|-------------|
| `/tmp/x.txt` (no editorconfig) | true | 4 | 4 | -1 |
| `init.lua` (repo `.editorconfig`) | true | 2 | 2 | -1 |
| `/tmp/Makefile` (ftplugin) | false | 4 | 0 | 0 |

## 6. Startup time (SC-004)

```sh
rm -f /tmp/st.log && nvim --headless --startuptime /tmp/st.log "+qa" \
  && grep 'NVIM STARTED' /tmp/st.log
```

Expected: final timestamp below 100 ms.

## 7. Visual check (User Story 2, SC-005)

Open a file containing a tab, trailing spaces, a non-breaking space and a line longer than the
window with `:set nowrap`. Confirm by eye: transparent background, highlighted cursor line,
marker at column 81, sign column present, symbols `»`, `·`, `␣`, `›`, `‹` rendered (no boxes).
Repeat after switching the terminal between light and dark mode.
