# Research: Notification Popup

Prototypes were run on Neovim 0.12.6 in a real terminal UI (tmux, 100×12) with `nvim --clean`.

## R1: Native mechanism vs. plugin

- **Decision**: Replace `vim.notify` with a function from a new module. Neovim documents
  `vim.notify` as the hook to override for a custom provider ("This function can be overridden by
  plugins…"). `vim.notify_once` and `vim.deprecate` call `vim.notify`, so they are covered too.
- **Rationale**: Constitution Principle I. It needs only a floating window, extmarks and timers,
  which are all built in.
- **Alternatives considered**:
  - *nvim-notify / mini.notify / snacks.notifier*: these plugins do what the spec asks, but core
    Neovim is enough, so Principle I rules them out.
  - *Built-in `ui2` (`require('vim._core.ui2')`)*: marked experimental in 0.12. Its message
    window has a single timeout, sits at the bottom, has no title and no entry limit, and it
    replaces the whole command-line UI. It does not meet FR-001–FR-004.

## R2: Keeping notifications in `:messages` without a command-line echo or "Press ENTER" (FR-009, FR-007)

Findings from the prototype:

| Attempt | Result |
|---------|--------|
| `nvim_echo({{msg}}, true)` then `nvim_echo({{""}}, false)`, single short line | Message in history, command line ends up empty, no prompt ✅ |
| Same, message containing `\n` | "Press ENTER" prompt ❌ |
| Same, single line wider than the command line | "Press ENTER" prompt ❌ |
| One write+clear per line, each piece at most `v:echospace` cells | History has every line, no prompt, normal and insert mode; `-- INSERT --` stays ✅ |
| Same, called from a `vim.defer_fn` timer | Same as above ✅ |

- **Decision**: Write each line of the notification to the history, split into pieces of at most
  `max(v:echospace, 10)` characters. Each piece is written with `nvim_echo(…, true, {})` and is
  followed immediately by `nvim_echo({{""}}, false, {})`. Error and warning pieces use the
  `ErrorMsg` / `WarningMsg` groups in history, as the stock `vim.notify` does.
- **Rationale**: This is the only built-in way found to add an entry to `:messages` without
  leaving it on the command line or blocking for Enter. `:silent echomsg` does not add to history.
- **Consequence**: A very long notification shows up in `:messages` as several consecutive
  lines. The text is complete, just wrapped.
- **Risk**: A notification that arrives while the user is typing a `:` command could disturb the
  command-line display. Mitigation: when `vim.fn.mode()` starts with `c`, hold the history write
  and flush it on the next key press after leaving the command line. `CmdlineLeave` registers a
  one-shot `vim.on_key` callback that schedules the flush, so the command's own output stays
  readable until the user acts. The popup is shown immediately either way. Quickstart scenario 11
  checks this.
- **Side effect (accepted, spec Assumptions)**: the clear also removes from the screen any other
  message shown at that moment, such as `"file" written`. The message stays in `:messages`.
- **Completion menu**: quickstart scenario 18 checks that the echo-and-clear does not close an
  open insert-mode completion menu. If it does, hold the write until `CompleteDone`, as for the
  command line.

## R3: Execution context

- **Decision**: Do all of the module's work (history write and popup update) inside
  `vim.schedule`.
- **Rationale**: `vim.notify` can be called from libuv callbacks (fast events) and under
  textlock, for example from expression mappings or completion. Opening a window or echoing is
  not allowed there. Scheduling costs one event-loop tick, which is not visible.

## R4: Popup window

- **Decision**: Use one scratch buffer (`buftype=nofile`, `bufhidden=hide`) that is created on
  first use and reused. The window is opened with `nvim_open_win(buf, false, …)` and these
  options:
  - placement: `relative="editor"`, `anchor="NE"`, `col=vim.o.columns`, and `row` set to 1 when
    a tabline is visible, otherwise 0
  - focus: `focusable=false`, `noautocmd=true`, `style="minimal"`, `zindex=250` (above the
    completion menu and other floats)
  - frame: `border` set to the global `'winborder'`, or `"rounded"` if that is empty, plus
    `title=" Notifications "`
  - window option `wrap=true`

  `nvim_win_set_config` updates the window when entries change. The window is closed when the
  last entry goes.
- **Width**: the longest display line of the entries' text (separators excluded) plus 1 for
  padding, at least the title width (15) and at
  most `floor(0.4 * columns)`. It is also capped by `columns - 2` for the border.
- **Height**: the sum of wrapped line counts (`ceil(strdisplaywidth / width)`, minimum 1 per
  line) plus separator lines. It is capped by the available rows (`lines - row - 2 - cmdheight`).
  If content is clipped, it is clipped at the top. The window shows the end of the buffer
  (cursor on the last line, `topline` adjusted), so the newest entry, shown last (FR-004), stays
  visible.
- **Border colour**: the shared `FloatBorder` / `FloatTitle` groups already set in
  `config.colorscheme` (spec 004). Nothing new.
- **Alternatives considered**: one window per notification, stacked (needs more bookkeeping and
  is not "one popup" as specified), and `title_pos="center"` (other popups use the default left
  position, so it is kept for consistency).

## R5: Entry separation and level colours (US2-1, FR-008)

- **Decision**: Separate entries with a full-width `─` line highlighted with `FloatBorder`.
  Colour each entry's text with an extmark (`hl_group` over the entry's lines) as follows:
  - ERROR → `DiagnosticError`
  - WARN → `DiagnosticWarn`
  - INFO, DEBUG, TRACE and nil → `DiagnosticInfo`

  These are the severity colours used elsewhere in the editor.
- **Alternatives considered**: blank-line separators (weaker visually) and ASCII level prefixes
  such as `[E]` (adds noise when colour already shows the level).

## R6: Lifetime (FR-005, FR-006)

- **Decision**: Each entry gets its own `vim.defer_fn(remove, TIMEOUT_MS)` timer, started when
  the entry is first shown. When an entry is removed early because a fourth one arrived, its
  timer is stopped and closed. `TIMEOUT_MS = 3000` is a module-local constant at the top of
  `lua/config/notifications.lua`, documented in the README. It is the single configuration value.
- **Rationale**: The spec says the delay is changed by editing the configuration. A module
  constant follows Principle II (no new global) and keeps the value in one obvious place.
- **Alternative rejected**: `vim.g.notification_timeout`. It would allow runtime changes nobody
  asked for, and it adds a global.

## R7: Startup and headless

- **Decision**: Require the module in `init.lua` right after `config.options`, so notifications
  issued by later modules are captured. Every notification is written to history at once.
  Whether it is queued depends only on `VimEnter` not having fired yet
  (`vim.v.vim_did_enter == 0`), because a UI may not be attached while `init.lua` runs. A
  once-only `VimEnter` autocommand in augroup `config_notifications` shows the queued entries if a
  UI is attached (`#vim.api.nvim_list_uis() > 0`), with their lifetimes starting then. Otherwise
  it discards them. After `VimEnter`, entries are shown only when a UI is attached.
- **Startup cost**: Loading the module only defines functions and one augroup. No window or
  buffer is created until the first notification.

## R9: Redraw in command-line mode (found during implementation)

- **Finding**: While a `:` command is being typed, Neovim does not redraw the screen by itself.
  A popup opened or closed by a timer stayed invisible, or stayed on screen, until the command
  line was left.
- **Decision**: After opening, updating or closing the popup, call `:redraw` when
  `vim.fn.mode()` starts with `c`. A plain `:redraw` is enough and keeps the typed command line
  intact (verified in a TUI); `:redraw!` is not needed.
- **Completion menu (R2)**: Quickstart scenario 18 passed. The history write does not close or
  change an open insert-mode completion menu, so no `CompleteDone` hold was added.
- **Level colours (R5)**: In this configuration catppuccin leaves the `Diagnostic*` groups at
  Neovim's defaults (`#ff0000`, `#ffa500`, `#add8e6`). The popup uses the same groups as
  diagnostics, so it matches them as FR-008 requires, even though they are not catppuccin's
  palette.

## R8: Resize

- **Decision**: A `VimResized` autocommand in the same augroup recomputes the size and position
  while the popup is open, keeping it in the top right corner (edge case).
