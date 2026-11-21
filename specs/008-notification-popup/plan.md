# Implementation Plan: Notification Popup

**Branch**: `master` (no feature branch) | **Date**: 2026-11-21 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-notification-popup/spec.md`

## Summary

Replace `vim.notify` with a function from a new module, `config.notifications`. It shows each
notification in one non-focusable floating window in the top right corner, titled
` Notifications `, with the shared `'winborder'` border. The window holds at most three entries,
newest last, each coloured by level. Each entry has its own timer (`TIMEOUT_MS`, 3000 by
default) and the window closes with its last entry. Notifications are still recorded in
`:messages`. They are written there in pieces that fit the command line, each followed by a
clear, so they neither stay on the command line nor trigger "Press ENTER" (research R2). No
plugin is added.

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: built-in `nvim_open_win` / `nvim_win_set_config`, extmarks,
`vim.defer_fn`, `nvim_echo`. No external tools.

**Storage**: N/A (in-memory entries; history in Neovim's `:messages`)

**Testing**: manual TUI checks per [quickstart.md](quickstart.md) (tmux-driven where useful);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics on changed files

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: popup appears within one event-loop tick; no typing interruption

**Constraints**: startup < 100 ms; no messages at startup; 80-column Lua style from
`.editorconfig`; no globals; no Nerd Font glyphs

**Scale/Scope**: one new module (~150 lines), one line in `init.lua`, README section

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Overrides the documented `vim.notify` hook with a float, extmarks and timers; no nvim-notify / mini.notify; experimental `ui2` rejected (research R1) | ✅ |
| II. Modular Lua | New single-concern module `config.notifications`; `init.lua` gains one `require`; augroup `config_notifications` with `clear = true`; delay is a module constant, not a global | ✅ |
| III. Fast, Deferred Startup | Loading defines functions and an augroup only; buffer and window are created on the first notification (research R7) | ✅ |
| IV. Reproducible & Fault-Tolerant | No external tools; headless runs write history only; all work scheduled so fast-event/textlock calls cannot error (R3); popup drawing is wrapped in `pcall` | ✅ |
| V. Consistent Style | `.editorconfig` style; lua_ls-clean; no mappings added, so `desc` does not apply | ✅ |
| Workflow | Workflow change → Spec Kit flow; small focused commits | ✅ |

**Post-design re-check**: still passes. Replacing `vim.notify` changes how existing modules'
notices (`config.diagnostics`, `config.lsp`, `config.gersemi`) appear, without changing their
code. This is intended by the spec, not a violation.

## Project Structure

### Documentation (this feature)

```text
specs/008-notification-popup/
├── plan.md              # This file
├── research.md          # Phase 0: prototype findings and decisions
├── data-model.md        # Phase 1: entries, popup state, transitions
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── notifications.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # CHANGED: require("config.notifications") right after config.options
lua/config/
├── notifications.lua    # NEW: vim.notify replacement, popup, timers, history writes
├── colorscheme.lua      # unchanged (FloatBorder colour reused)
└── options.lua          # unchanged ('winborder' reused)
README.md                # CHANGED: "Notifications" section, TIMEOUT_MS
```

**Structure Decision**: Notification display is its own concern, so it gets one module in
`lua/config/`, like `config.diagnostics` and `config.completion`. It is loaded right after
options so that notices from every later module reach the popup.

## Implementation Notes

1. **`lua/config/notifications.lua`**, with constants per [data-model.md](data-model.md):
   - `history(entry)`: write the entry's lines in pieces of at most `max(v:echospace, 10)`
     characters, each with `nvim_echo(..., true, {})` followed by `nvim_echo({{""}}, false, {})`,
     using `ErrorMsg` / `WarningMsg` for those levels. In command-line mode, queue the write and
     flush it on the first key press after `CmdlineLeave` (research R2).
   - `render()`: compute width and height from the entries' text (research R4), then fill the
     buffer (entry lines plus `─` separators at that width), set extmarks, and open or update the
     window, keeping the last line visible. Close the window when there
     are no entries.
   - `add(entry)`: drop the oldest entry (stopping its timer) when three are shown, append the
     new one, start its `vim.defer_fn` timer, and render.
   - `vim.notify = function(msg, level, opts)`: normalise the message, ignore empty ones, and
     `vim.schedule` the history write plus either a queue (before `VimEnter`), `add` (after
     `VimEnter`, UI attached, called through `pcall`) or nothing more (no UI).
   - Autocommands per the data model: `VimEnter` (once), `VimResized`, and `CmdlineLeave`
     on demand.
2. **`init.lua`**: `require("config.notifications")` right after `require("config.options")`.
3. **README**: a "Notifications" section covering what is shown, where and for how long, how to
   change `TIMEOUT_MS`, and that `:messages` keeps the history.
4. *(Added during implementation, research R9)*: after opening, updating or closing the popup
   in command-line mode, call `:redraw`, since the screen is not redrawn there otherwise.
5. Verify every [quickstart](quickstart.md) scenario in a real TUI. Scenarios 6 and 11 also
   confirm the history-write mitigation.

## Complexity Tracking

No constitution violations; nothing to justify.
