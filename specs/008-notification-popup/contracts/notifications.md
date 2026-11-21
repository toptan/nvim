# Contract: Notifications

## `vim.notify(msg, level, opts)` (replaced)

| Input | Behaviour |
|-------|-----------|
| `msg` | Shown in the popup and written to `:messages`; `\n` starts a new line in the same entry |
| `level` | ERROR → `DiagnosticError`, WARN → `DiagnosticWarn`, anything else or nil → `DiagnosticInfo` |
| `opts` | Ignored |
| return | nil, as stock |

- Callable from any context: fast events, textlock, insert mode, timers, before `VimEnter`.
- Never takes focus, changes mode, moves the cursor, or prompts for Enter.
- Nothing is echoed on the command line. `:messages` lists the text, with lines wider than the
  command line split across several history lines.
- `vim.notify_once` and `vim.deprecate` go through this function.

## Popup

| Property | Value |
|----------|-------|
| Position | Top right corner of the editor, below the tabline if one is shown |
| Border | `'winborder'` (rounded), `FloatBorder` colour, as other popups |
| Title | ` Notifications ` |
| Entries | ≤ 3, oldest first / newest last, separated by a `─` line |
| Lifetime | Each entry disappears `TIMEOUT_MS` (default 3000) after it was shown; the popup closes with its last entry |
| Size | Fits content; width ≤ 40% of the editor; long lines wrap |
| Interaction | None: not focusable, no mappings |

## Configuration

`TIMEOUT_MS` at the top of `lua/config/notifications.lua`. Edit it and restart Neovim.

## Unchanged

No key mapping, command or plugin is added. Other command-line messages (`:echo`, errors from
commands, prompts, `-- INSERT --`) behave as before. Exception: a message on the command line at
the moment a notification is recorded is cleared from the screen but stays in `:messages`.
