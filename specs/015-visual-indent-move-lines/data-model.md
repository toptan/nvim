# Data Model: Sticky Visual Indent and Line Moving

Nothing is stored. The only state is the editor's own state while one key press is being
handled.

## Line range (transient)

| Field | Source | Rule |
|-------|--------|------|
| `top` | Normal: `line(".")`; Visual: `min(line("v"), line("."))` | 1 ≤ top ≤ bottom |
| `bottom` | Normal: `top`; Visual: `max(line("v"), line("."))` | bottom ≤ `line("$")` |
| `count` | `vim.v.count1` | ≥ 1 |
| `mode` | `v`, `V`, `<C-v>` or normal | Visual mode is restored after the action |

## Move target

- Down: `target = min(line("$"), bottom + count)`; no-op when `bottom == line("$")`.
- Up: `target = max(0, top - count - 1)`; no-op when `top == 1`.
- `:{top},{bottom}move {target}` puts the range after line `target` (0 = top of buffer).

## State transitions

```text
Visual(mode, range) --<M-j>/<M-k>/∆/˚--> Visual(mode, moved range)   [or unchanged at edge]
Visual(mode, range) -->/<-------------> Visual(mode, same range, shifted)
Normal(line)        --<M-j>/<M-k>/∆/˚--> Normal(cursor on moved line)
```
