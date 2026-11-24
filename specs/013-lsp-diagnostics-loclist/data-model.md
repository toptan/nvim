# Data Model: Diagnostics List in the Location List

## Diagnostic (input, from `vim.diagnostic.get()`)

| Field | Use |
|-------|-----|
| `bufnr` | file name (`fnamemodify(bufname, ":~:.")`) and quickfix `bufnr` |
| `lnum`, `col` (0-based) | quickfix `lnum`/`col` (+1); sort keys |
| `end_lnum`, `end_col` | quickfix `end_lnum`/`end_col` (+1) when present |
| `severity` (1–4) | sort key; label; colour group |
| `message` | entry text (newlines → spaces) |
| `namespace` | `is_enabled` filter only |

Filtered out: diagnostics for which `vim.diagnostic.is_enabled({ bufnr, ns_id })` is false.

## Sort order (FR-004)

1. `severity` ascending (1 Error, 2 Warn, 3 Info, 4 Hint)
2. file name (display form), byte order
3. `lnum`
4. `col`

## Severity mapping

| Severity | Label | Quickfix `type` | Highlight group |
|----------|-------|-----------------|-----------------|
| 1 ERROR | `error` | `E` | `DiagnosticError` |
| 2 WARN | `warning` | `W` | `DiagnosticWarn` |
| 3 INFO | `info` | `I` | `DiagnosticInfo` |
| 4 HINT | `hint` | `N` | `DiagnosticHint` |

## Display line

```text
{file}|{lnum} col {col} {label}| {message}
        ^ usual colours ^ ^label^   ^message^  ← severity colour
```

## List record (module table `lists[id]`, keyed by location list id)

| Field | Type | Meaning |
|-------|------|---------|
| `lines` | `string[]` | display line per entry (index = entry index) |
| `hl` | `{ group, label = {s, e}, msg = {s, e} }[]` | 0-based byte ranges per entry |

Lifecycle: created or overwritten when a key fills a list. It is never mutated after
that, and is read by `quickfixtextfunc` and the decoration provider. Entries for lists
that were later freed stay as small, dead records. Their number is bounded by key presses
in the session.

## Location list (per window, built-in)

| `what` key | Value |
|------------|-------|
| `title` | `Diagnostics` (buffer) / `Workspace diagnostics` |
| `items` | sorted quickfix items |
| `quickfixtextfunc` | module function returning `lists[id].lines[i]` |

State transitions of the list window: closed → (key) open + focused → (`<CR>`) open,
focus in file window → (key again) refreshed + focused → (`<Esc>`) closed, focus in file
window.
