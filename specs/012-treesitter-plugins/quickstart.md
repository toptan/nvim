# Quickstart: Validating Tree-sitter Support

## Prerequisites

- Neovim ≥ 0.12, `git`, `curl`, `tar`, a C compiler, `tree-sitter` CLI ≥ 0.26.1 (not npm).
- Sample files: a C file with two functions, a C++ file with a class, a Lua file, a Python
  file with a class and an `re.compile(r"...")`, a Markdown file with inline formatting and a
  fenced ` ```lua ` block, a `CMakeLists.txt`, a `.editorconfig`, a Vim script file, an
  assembly file (`.s`), and a JSON file (unsupported).

To test a fresh machine without touching the real setup, run Neovim with
`XDG_DATA_HOME`, `XDG_STATE_HOME` and `XDG_CACHE_HOME` pointed at an empty scratch directory.

## 1. Startup stays clean and lazy (FR-002, FR-011, SC-004, US1-5, US2-1)

1. `nvim --headless "+qa"` → exits with no output (on a fresh data dir, only vim.pack's
   install progress for the two plugins).
2. `nvim --startuptime /tmp/st.log +qa` → total under 100 ms; `config/treesitter.lua` costs
   a few ms at most.
3. On a fresh data dir, after the first start (which installs the plugins):
   `nvim --headless +'lua print(package.loaded["nvim-treesitter"])' +qa` prints `nil`.
4. `nvim` on an empty buffer, then
   `:lua print(package.loaded["nvim-treesitter"] ~= nil)` → `false`. No parser was built
   (parser directory still empty on a fresh data dir).

## 2. First supported file installs parsers (FR-004, FR-004a, SC-001, US2-5, US2-6)

On a fresh data dir: `nvim sample.c`.

- Progress lines `[nvim-treesitter/install/<lang>]: ...` appear while editing stays possible.
- After they stop: `:lua print(vim.treesitter.highlighter.active[0] ~= nil)` → `true`
  without reopening the file.
- `ls ~/.local/share/nvim/site/parser` (or the scratch equivalent) lists all 12 `.so` files.
- Opening a second supported file meanwhile does not start a second install.

## 3. Normal start with parsers present (US2-3)

Restart and open `sample.c` → no message at all; highlighting active immediately.

## 4. Update on plugin change (FR-005, SC-003, US2-2)

`:lua vim.pack.update({ "nvim-treesitter", "nvim-treesitter-textobjects" }, { force = true })`.
If either plugin changed: exactly one update run (progress lines only for parsers whose
revision changed; nothing if none did). For a forced check, roll a plugin back with
`vim.pack.update(..., { target = "lockfile" })` after editing the lockfile in a scratch setup.

## 5. Features per language (FR-006–FR-009, SC-002, SC-006, SC-007, US1)

For each sample file:

| Check | Command | Expected |
|-------|---------|----------|
| highlighting | `:Inspect` on a keyword | a `@...` tree-sitter capture |
| folding (languages with folds) | `:set foldmethod? foldlevel?`, then `zc` on a function header | `expr`, `99`; that function closes |
| indentation (languages with indents) | `:set indentexpr?`; `o` inside a function body | nvim-treesitter's expression; one level deeper than the header |
| injections | `:Inspect` in the fenced Lua block / in the Python regex | Lua / regex captures |
| unsupported | open the JSON file, `:set foldmethod? indentexpr?` | same values as before the feature |
| detach | in `sample.c`: `:set filetype=text`, then `:set foldmethod? foldexpr? foldlevel? indentexpr?` and `:map <buffer> af` | global values, empty `indentexpr`, no mapping |

Expected per-language query support is in research.md R8 (e.g. `asm` and `help` get
highlighting only).

## 6. Text objects and jumps (FR-010–FR-010b, SC-005, SC-008, US3)

In `sample.c` / `sample.cpp` / `sample.lua` / `sample.py`:

- `vaf`, `vif`, `vac`, `vic`, `vaa`, `via` select the expected ranges; `daf` deletes the whole
  function; `u` restores it.
- `]f`, `[f`, `2]f`, `]c`, `[c` move to function/class starts; `<C-o>` returns.
- `vac` outside any class and `]c` after the last class → nothing happens, no error.
- `:map <buffer> af` (and the others) shows the `desc` from the contract.
- `nvim -d a.py b.py`: `]c` / `2]c` move between diff changes; `:diffoff` then `]c` jumps
  to the next class.
- In the JSON file, `:map <buffer> ]c` shows nothing.

## 7. Failure handling (FR-012, edge cases)

- Hide `tree-sitter` from `PATH` and use a fresh data dir: opening `sample.c` shows one
  warning naming `tree-sitter`, no plugin error lines and no Lua traceback; opening a second
  supported file shows nothing more; editing continues with built-in highlighting.
- Remove the plugins' pack directory and start without network: start has no errors.

## 8. Checks before commit

- `:checkhealth nvim-treesitter` (after opening a supported file) and `:checkhealth vim.pack`
  show no new errors.
- `lua_ls` reports no diagnostics in `lua/config/treesitter.lua`.
