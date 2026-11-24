# Contract: Diagnostics Module and Window Keys

## Module `lua/config/diagnostics.lua`

Required from `init.lua` (before `config.lsp`). It exports `M.setup()`, which `lsp.lua`
uses (unchanged). It now also contains everything formerly in
`lua/config/diagnostic_list.lua`, which is deleted, along with its `require`.

### Global key mappings (Normal mode), all unchanged

| Keys | `desc` |
|------|--------|
| `<leader>td` | `Toggle diagnostics` |
| `<leader>tt` | `Toggle diagnostic virtual text` |
| `<leader>tl` | `Toggle diagnostic virtual lines` |
| `<leader>ld` | `Buffer diagnostics` |
| `<leader>lD` | `Workspace diagnostics` |

Behaviour is as in the [013 contract](../../013-lsp-diagnostics-loclist/contracts/diagnostic-list.md),
except that display lines follow the aligned layout in [data-model.md](../data-model.md).

### Autocommands (single augroup `config_diagnostics`, `clear = true`)

| Event | Pattern | Options | Action |
|-------|---------|---------|--------|
| `DiagnosticChanged` | * | `once = true` | `M.setup()` |
| `FileType` | `qf` | | location list windows only: buffer-local `<Esc>` (`Close location list`) |

### Decoration provider (namespace `config_diagnostics`)

Unchanged: it is registered on first list use and colours only the `label` and `msg`
ranges of list records.

## Module `lua/config/keymaps.lua`: window keys (Normal mode only)

| Keys | Right-hand side | `desc` |
|------|-----------------|--------|
| `<C-h>` | `<C-w>h` | `Go to left window` |
| `<C-j>` | `<C-w>j` | `Go to lower window` |
| `<C-k>` | `<C-w>k` | `Go to upper window` |
| `<C-l>` | `<C-w>l` | `Go to right window` |

They are noremap, accept a count, and do nothing at an edge. `<C-w>h/j/k/l` are unchanged.
Insert, Visual, Command-line and Terminal modes are untouched.

## Guarantees

- `grep -rn diagnostic_list init.lua lua README.md` finds nothing. Historical specs under
  `specs/013-*` are left as they are.
- Nothing from `vim.diagnostic` or `vim.lsp` is loaded at startup; `nvim --headless "+qa"`
  is clean.
