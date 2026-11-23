# Data Model: Tree-sitter Parsers and Syntax-Aware Text Objects

All state lives in the `config.treesitter` module (module locals) or in buffer variables.
Nothing is persisted by the config. Parsers, queries and the plugin lockfile are written by
the plugins under `stdpath("data")` and are not part of the repository.

## Supported language list (`LANGUAGES`)

Ordered list, the single source of truth (FR-003):
`asm, c, cmake, cpp, editorconfig, lua, markdown, markdown_inline, python, regex, vim, vimdoc`.

- Passed as-is to `install` and `update`.
- Validation: every name exists in nvim-treesitter's parser table (checked once by hand in
  quickstart; the plugin logs a warning for unknown names).

## Filetype map (`FILETYPES`)

| Filetype | Language |
|----------|----------|
| `asm` `c` `cmake` `cpp` `editorconfig` `lua` `markdown` `python` `vim` | same name |
| `help` | `vimdoc` |

- Keys are the `FileType` autocommand pattern. Any other filetype is "unsupported".
- `markdown_inline` and `regex` are absent on purpose (injection only).

## Module state

| Field | Type | Meaning |
|-------|------|---------|
| `loaded` | boolean | both plugins `:packadd`-ed in this session |
| `install` | `"idle" \| "running" \| "done"` | parser installation for this session |
| `update_pending` | boolean | a plugin change requested an update that has not run yet |
| `pending` | set of buffer numbers | supported buffers waiting for their parser |
| `tools_warned` | boolean | the missing-tools warning was shown this session |

### Install state transitions

```text
idle --(first supported FileType, tools present)--> running --(task callback)--> done
running --(install() raised, caught by pcall)--> done
idle --(first supported FileType, tools missing)--> done   (one WARN, no install)
```

- `running`: new supported buffers that fail to start tree-sitter join `pending`. No second
  install is started.
- On the callback (success or failure), every still-valid buffer in `pending` whose filetype is
  still supported is attached again. Buffers whose parser still fails stay on built-in
  behaviour. The plugin has already reported the failure.
- After re-attaching, the callback runs a pending update (see Update flow).
- `done` is never left during a session. A later session starts at `idle` again. That
  install is a silent no-op when all parsers exist.

### Update flow

```text
PackChanged(install|update, plugin ∈ {nvim-treesitter, nvim-treesitter-textobjects})
  → update_pending = true
  → if loaded and install ≠ running: vim.schedule(run_update)
first supported FileType: ensure_loaded → install_parsers → on completion (or at once
  when the install is skipped or already done), if update_pending: run_update
run_update: return unless update_pending → update_pending = false
  → (tools present) update(LANGUAGES), else one WARN
  (several scheduled calls from one batch of plugin changes run at most one update)
```

The `PackChanged` handler never loads the plugins itself (FR-002).

## Buffer attachment

Buffer variable `vim.b[buf].config_treesitter` = attached language name (or `nil`).

Attach(buf, lang) applies only what the language's queries support (see research R8):

| Feature | Condition | Settings |
|---------|-----------|----------|
| highlighting | parser loads | `vim.treesitter.start(buf, lang)` |
| folding | `folds` query exists | per window showing buf: `foldmethod=expr`, `foldexpr=v:lua.vim.treesitter.foldexpr()`, `foldlevel=99` (window-local to the buffer) |
| indentation | `indents` query exists and `loaded` | `indentexpr=v:lua.require'nvim-treesitter'.indentexpr()` |
| text objects, jumps | `textobjects` query exists and `loaded` | buffer-local mappings from the contract |

- Attach is idempotent. A second `FileType` for the same buffer re-applies the same settings.
- Detach (filetype changed to unsupported): delete this module's buffer-local mappings,
  `vim.treesitter.stop(buf)`, reset `foldmethod`, `foldexpr` and `foldlevel` to their global
  values (`vim.go.*`) via `vim.wo[win][0]` in every window showing the buffer, reset
  `indentexpr` to `vim.go.indentexpr` only if it still holds the tree-sitter expression (a
  new indent script may already have replaced it), and clear `config_treesitter`.
