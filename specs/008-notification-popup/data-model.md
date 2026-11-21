# Data Model: Notification Popup

All state is local to `lua/config/notifications.lua`; nothing is global (Principle II).

## Constants

| Name | Value | Meaning |
|------|-------|---------|
| `TIMEOUT_MS` | `3000` | Dismissal delay per notification (FR-006); the single configuration value |
| `MAX_ENTRIES` | `3` | Most notifications shown at once (FR-004) |
| `TITLE` | `" Notifications "` | Border title (FR-002) |
| `MAX_WIDTH_RATIO` | `0.4` | Popup width cap as a share of `'columns'` |

## Entry (Notification)

| Field | Type | Notes |
|-------|------|-------|
| `lines` | `string[]` | `msg` split on `\n`; trailing empty lines dropped |
| `hl` | `string` | `DiagnosticError` / `DiagnosticWarn` / `DiagnosticInfo` from `level` (research R5) |
| `timer` | `uv_timer_t?` | From `vim.defer_fn`; nil while queued before `VimEnter` |

Validation:

- An empty message (after trimming trailing newlines) creates no entry and opens no popup. It is
  not written to history either.
- A non-string `msg` is converted with `tostring`, as `nvim_echo` would otherwise fail.

## Popup state

| Field | Type | Notes |
|-------|------|-------|
| `entries` | `Entry[]` | Arrival order, oldest first, length ≤ `MAX_ENTRIES` |
| `buf` | `integer?` | Reused scratch buffer, created on first display |
| `win` | `integer?` | Valid only while `#entries > 0` and a UI is attached |
| `ns` | `integer` | Extmark namespace for level colours and separators |
| `pending` | `Entry[]` | Queued before `VimEnter` |

## State transitions

```text
            notify(msg)                    notify(msg), #entries == 3
 [Closed] ─────────────▶ [Open, n=1] ─▶ … [Open, n=3] ───────────────▶ drop oldest
    ▲                        │                │         (stop its timer), append, n=3
    │   timer of last entry  │  timer of an   │
    └────────────────────────┘  entry fires ──┘ remove it, n-1; if n==0 → close window
```

- Every change re-renders the buffer: entry lines, a separator between entries and extmarks.
  It then resizes and repositions the window (`nvim_win_set_config`).
- A timer firing for an entry that was already dropped does nothing (the identity check fails).
- `VimResized` while the popup is open triggers a re-layout only.

## Autocommands (augroup `config_notifications`, `clear = true`)

| Event | Purpose |
|-------|---------|
| `VimEnter` (once) | Show queued startup notifications |
| `VimResized` | Re-anchor the open popup to the top right corner |
| `CmdlineLeave` (once, on demand) | Register a one-shot `vim.on_key` listener (namespace `ns`) that schedules the flush of history writes held back in command-line mode, then removes itself (research R2) |
