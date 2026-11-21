# Data Model: Notifications via mini.notify

The configuration holds no notification state of its own any more; all state lives inside the
plugin. This file records what the config relies on.

## Plugin spec (vim.pack)

| Field | Value |
|-------|-------|
| `src` | `https://github.com/nvim-mini/mini.notify` |
| `name` | `mini.notify` (derived from `src`) |
| `version` | default branch (not pinned; lockfile is machine-local and git-ignored) |
| Install dir | `stdpath("data")/site/pack/core/opt/mini.notify` |

## Notification (owned by the plugin)

Fields per `MiniNotify-specification`: `msg`, `level`, `hl_group`, `ts_add`, `ts_update`,
`ts_remove`, `data` (`source = "vim.notify"`).

Level handling from `vim.notify` with defaults:

| Level | Shown for | Highlight | In history |
|-------|-----------|-----------|------------|
| ERROR | 5000 ms | `DiagnosticError` | yes |
| WARN | 5000 ms | `DiagnosticWarn` | yes |
| INFO / nil | 5000 ms | `DiagnosticInfo` | yes |
| DEBUG / TRACE / OFF | not shown | — | no |

## States

```text
vim.notify(msg, level)
  └─ (scheduled) ─► active ── 5 s ──► removed (kept in history)
popup: hidden ◄──► shown   (shown while ≥ 1 active notification)
```

## Module states (config.notifications)

```text
load ─► vim.pack.add ok? ─no─► built-in vim.notify + one WARN line
                 │yes
                 ▼
        require + setup ok? ─no─► built-in vim.notify + one WARN line
                 │yes
                 ▼
        vim.notify = mini.notify
```
