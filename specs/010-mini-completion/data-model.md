# Data Model: Completion via mini.completion

No persistent data. The "entities" are configuration values and runtime states.

## Plugin spec

| Field | Value |
|-------|-------|
| Source | `https://github.com/nvim-mini/mini.completion` |
| Installed name | `mini.completion` |
| Version | default branch (latest), pinned only by the machine-local `nvim-pack-lock.json` |
| `vim.pack.add` opts | `{ confirm = false }` |
| Setup | `require("mini.completion").setup()` — no options (defaults, research R2) |
| Loaded | first `InsertEnter` (augroup `config_completion`, `once = true`) |

## Editor options (`config.options`)

| Option | Before | After | Why |
|--------|--------|-------|-----|
| `'completeopt'` | `menuone,noselect,popup,fuzzy` | `menuone,noselect,fuzzy` | `popup` duplicates the plugin's Info window (R3) |
| `'shortmess'` | `+= S` | `+= S`, `+= c` | Silent fallback completion (R3) |

Buffer-local `'autocomplete'`, `'complete'`, `'completefunc'`, `'completeopt'` overrides from
feature 007 are removed; the plugin sets `'completefunc'` on `BufEnter`.

## Completion item (menu entry)

| Field | Source |
|-------|--------|
| `word` / `abbr` | server label (or buffer word in fallback) |
| `kind` | readable LSP kind (`Function`, `Field`, …) |
| `menu` | label details; `S` marks a snippet |
| `info` | snippet body for snippet items (shown in the plugin's Info window) |
| `user_data.lsp` | client id / item id used for resolve and snippet insertion |

## Runtime states

```text
Not loaded ──first InsertEnter──▶ Loading ──ok──▶ Active
                                     └──error──▶ Unavailable (one WARN notice;
                                                  built-in completion only)

Active, per keystroke in Insert mode:
  idle ──keyword char + 100 ms / trigger char──▶ LSP stage ──items──▶ menu (LSP)
                                                    └──no items──▶ fallback stage ──▶ menu (buffer words)
  menu ──<Tab>/<S-Tab>──▶ item highlighted (Info window after 100 ms)
  menu ──<CR> with item──▶ accepted (snippet expanded) ──▶ idle
  menu ──<CR> no item / <C-e>──▶ idle
```
