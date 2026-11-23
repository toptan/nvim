# Contract: Tree-sitter Module, Key Mappings and Plugin Hooks

## Plugins (`vim.pack`)

| Name | Source | Justification comment |
|------|--------|-----------------------|
| `nvim-treesitter` | https://github.com/nvim-treesitter/nvim-treesitter | core has no parser installer/updater, bundled queries or tree-sitter indentation |
| `nvim-treesitter-textobjects` | https://github.com/nvim-treesitter/nvim-treesitter-textobjects | core has no syntax-aware text objects or function/class jumps |

- Added with `{ confirm = false, load = function() end }`. Default branch, no `version`.
- No `setup()` call for either plugin; defaults are used (`install_dir` =
  `stdpath("data")/site`, `lookahead = false`, `set_jumps = true`).

## Autocommands (augroup `config_treesitter`, `clear = true`)

| Event | Pattern | Action |
|-------|---------|--------|
| `PackChanged` | – | for `kind` `install`/`update` of either plugin: mark an update pending; run it at once only if the plugins are loaded and no install is running, otherwise after the first supported file's install; never loads the plugins |
| `FileType` | `*` | supported filetype → load plugins (once), start install (once), attach; previously attached buffer with an unsupported filetype → detach |

The `PackChanged` autocommand is created before `vim.pack.add` so that it also sees the first
install.

## Buffer-local key mappings (only in attached buffers with a `textobjects` query)

| Keys | Modes | Action | `desc` |
|------|-------|--------|--------|
| `af` / `if` | x, o | select `@function.outer` / `@function.inner` | `Around function` / `Inside function` |
| `ac` / `ic` | x, o | select `@class.outer` / `@class.inner` | `Around class` / `Inside class` |
| `aa` / `ia` | x, o | select `@parameter.outer` / `@parameter.inner` | `Around parameter` / `Inside parameter` |
| `]f` / `[f` | n, x, o | start of next / previous `@function.outer` | `Next function start` / `Previous function start` |
| `]c` / `[c` | n, x, o | diff window: built-in next/previous change; otherwise start of next / previous `@class.outer` | `Next class start (diff: next change)` / `Previous class start (diff: previous change)` |

- Counts work for all jumps; jumps are recorded in the jump list.
- A construct that does not exist (in the language or around the cursor) does nothing and
  shows no error.
- In all other buffers these keys keep their built-in meaning.

## Messages

- The config shows exactly one message of its own: a WARN, at most once per session, when
  build tools are missing (`Tree-sitter parsers not installed, missing: <tools>`); no install
  or update is attempted then.
- Parser install/update progress and errors are nvim-treesitter's own output (two lines per
  parser on success, an error line on failure), shown only while work actually happens.
- No message on a normal start, on opening files when all parsers exist, or in
  `nvim --headless "+qa"`.

## Module API (`config.treesitter`)

The module is required from `init.lua`. Everything happens through the autocommands above.
It returns one function, `jump(method, capture)`, which the `]c`/`[c` expression mappings
call through `<Cmd>` (an expression mapping cannot move the cursor itself). It never raises: plugin loading, `vim.treesitter.start`, query
lookups and install/update calls are wrapped in `pcall`.
