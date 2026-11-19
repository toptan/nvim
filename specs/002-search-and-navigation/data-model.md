# Data Model: Search, Yank Feedback and Buffer Navigation

This feature has no stored data. It adds three runtime entities and a few settings.

## Settings (added to `config.options`)

| Option | Value | Requirement |
|--------|-------|-------------|
| `incsearch` | `false` | FR-001 |
| `ignorecase` | `true` | FR-002 |
| `smartcase` | `true` | FR-002 |
| `hlsearch` | `true` (default, not set) | FR-003 |
| `numberwidth` | `6` | FR-014 |
| `shortmess` | append `"S"` | research R7 |

## Search position label (`config.search`)

One label at most, held in module-local state:

| Field | Type | Meaning |
|-------|------|---------|
| `buf` | buffer handle or `nil` | Buffer holding the label |
| `id` | extmark id or `nil` | Extmark in namespace `config_search_count` |

**Label text** (`Search position label.Label text`), derived from `searchcount()`:

| `searchcount` result | Label |
|----------------------|-------|
| `exact_match == 0` or `total == 0` | none |
| `incomplete == 0` | `[current/total]` |
| `incomplete == 2` (over 999) | `[current/>999]`, or `[>999/>999]` if `current > 999` |
| `incomplete == 1` (timed out) | `[?/?]` |

**States and transitions**

```text
          search jump (n N * # g* g# / ?) and cursor on a match
 Hidden ───────────────────────────────────────────────────────▶ Shown(buf, line)
   ▲                                                              │  │
   │   Esc · :noh (v:hlsearch=0) · TextChanged/TextChangedI(buf)  │  │ search jump:
   └──────────────── · BufLeave(buf) · jump lands off a match ────┘  │ replace (one label)
                                                                     ▼
                                                           Shown(new buf, new line)
```

Ordinary cursor motions don't change the state.

**Highlight group**: `SearchCountLabel` → links to `Comment` (`default = true`). It is
re-created on `ColorScheme` so it survives scheme reloads.

## Buffer cycle candidates (`config.keymaps`)

- Candidate set: `{ b | buflisted(b) and buftype(b) == "" }`, sorted by buffer number.
- Next target: the first candidate with number > current, else the first candidate (wrap).
  Previous: the mirror image.
- No-op when the candidate set is empty, or it holds only the current buffer.

## Yank highlight (`config.autocmds`)

- Trigger: `TextYankPost`. Effect: `vim.hl.on_yank()` with defaults (`IncSearch`, 150 ms).
  It only applies to yank operators.

## Augroups (Principle II)

| Augroup | Module | Events |
|---------|--------|--------|
| `config_search_count` | `config.search` | `CmdlineLeave`, `TextChanged`, `TextChangedI`, `BufLeave`, `ColorScheme` |
| `config_yank_highlight` | `config.autocmds` | `TextYankPost` |
