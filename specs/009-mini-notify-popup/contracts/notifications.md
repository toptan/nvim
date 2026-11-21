# Contract: Notifications (mini.notify)

Supersedes `specs/008-notification-popup/contracts/notifications.md`.

## `vim.notify(msg, level, opts)`

| Input | Behaviour |
|-------|-----------|
| `msg` | Shown in the plugin popup and recorded in the plugin history |
| `level` | ERROR / WARN / INFO (or nil): shown 5 s, coloured `DiagnosticError` / `DiagnosticWarn` / `DiagnosticInfo`. DEBUG / TRACE / OFF: ignored |
| `opts` | Ignored |

- Callable from any context (fast events, textlock, insert mode, before `VimEnter`).
- Never takes focus, changes mode, moves the cursor, or echoes on the command line.
- If the plugin could not be installed or loaded: the built-in `vim.notify` is used, and one
  WARN line says so at startup.

## Popup

| Property | Value |
|----------|-------|
| Position | Top right, below the tabline if shown |
| Border / title | `'winborder'` (rounded); ` Notifications ` |
| Content | `HH:MM:SS │ message`, newest first; no entry limit |
| Size | Width ≤ 38.2% of the editor, wraps, fits the screen |
| Extras | LSP progress messages |
| Interaction | None: not focusable, no mappings |

## History

- `:lua MiniNotify.show_history()` opens all past notifications (this session) in a buffer.
- Notifications are no longer written to `:messages`.

## Configuration

- No user options. The module `lua/config/notifications.lua` installs the plugin with
  `vim.pack` and calls `setup()` with defaults.
- Key mappings: none added or changed.
