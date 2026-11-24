# Data Model: Aligned Diagnostics List Entry

Everything else (diagnostic → quickfix item mapping, sort order, list record storage) is
unchanged from [013 data-model](../013-lsp-diagnostics-loclist/data-model.md).

## Display line layout

```text
<loc><pad_loc> <label><pad_label>| <message>
```

| Part | Value |
|------|-------|
| `loc` | `("%s|%d col %d"):format(file, lnum + 1, col + 1)` |
| `pad_loc` | `W - strdisplaywidth(loc)` spaces, where `W` = max `strdisplaywidth(loc)` over the list |
| `label` | `error`, `warning`, `info`, `hint` |
| `pad_label` | `LABEL_WIDTH - #label` spaces, `LABEL_WIDTH = 7` (`#"warning"`) |
| `message` | diagnostic message with newlines replaced by a space |

Example:

```text
lua/config/lsp.lua|3 col 1 error  | undefined global 'x'
init.lua|120 col 14        warning| unused local 'm'
```

## Highlight ranges (byte offsets, 0-based, end-exclusive)

With `p = #loc + #pad_loc + 1` (byte length up to the start of the label):

| Range | Start | End |
|-------|-------|-----|
| `label` | `p` | `p + #label` |
| `msg` | `p + LABEL_WIDTH + 2` | `#line` |

Padding bytes fall outside both ranges, so they are never coloured (FR-006). An empty
message gives an empty `msg` range, which is skipped, as today.

## Invariants

- For every two entries in one list, the screen column where `label` starts is the same,
  and so is the screen column where `message` starts.
- `W` is computed per list, so a single-entry list has no location padding (`pad_loc`
  is empty).
