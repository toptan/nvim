# Quickstart: Validating the Notification Popup

## Prerequisites

Start `nvim` in a terminal at least 100 columns wide. Notifications are triggered with the
existing toggle `<leader>td` or with `:lua vim.notify(...)` as shown. Use a stopwatch, or
`:lua` with `vim.defer_fn`, for the timing checks.

## Scenarios

| # | Steps | Expected | Covers |
|---|-------|----------|--------|
| 1 | `<leader>td` | Popup in the top right corner, rounded border in the title colour, title ` Notifications `, text `Diagnostics: off`; cursor stays in the buffer | US1-1, US1-2, FR-001–003 |
| 2 | Wait | The entry and popup vanish about 3 s after appearing | US3-1, SC-003 |
| 3 | `:lua vim.notify("e", vim.log.levels.ERROR) vim.notify("w", vim.log.levels.WARN) vim.notify("i")` | Three entries in order e, w, i, separated by `─` lines, coloured error / warning / info | US1-4, US2-1, FR-008 |
| 4 | `:lua for i = 1, 4 do vim.notify("n" .. i) end` | Only n2, n3, n4 shown | US2-2, FR-004, SC-002 |
| 5 | `:lua vim.notify("a") vim.defer_fn(function() vim.notify("b") end, 1500)` | `a` leaves at about 3 s while `b` stays and the popup shrinks; the popup closes at about 4.5 s | US2-4, US2-5, US3-2, FR-005 |
| 6 | `i`, type continuously, and from a second mapping or a timer call `vim.notify("x")` | Typing is uninterrupted, still in insert mode, `-- INSERT --` kept | US1-3, FR-007, SC-004 |
| 7 | `:lua vim.notify(string.rep("long ", 60) .. "\nsecond line")` | Text wraps inside the popup, width ≤ 40% of the editor, nothing outside the border; no "Press ENTER" | FR-010, edge cases |
| 8 | `:messages` | Every notification from steps 1–7 is listed; long ones span several lines | FR-009, SC-005 |
| 9 | `:lua vim.notify("")` | No popup | edge case |
| 10 | Trigger a notification, then resize the terminal | Popup stays in the top right corner | edge case |
| 11 | Type `:` and some text, then wait for a timer `vim.notify` (`:lua vim.defer_fn(function() vim.notify("t") end, 2000)` first) | Popup appears; command line text is intact; after executing the command its output stays visible until the next key press; `t` is then in `:messages` | research R2 |
| 12 | `:tabnew` (tabline visible), trigger a notification | Popup below the tabline | R4 |
| 13 | Set `TIMEOUT_MS = 5000`, restart, repeat 2 | Entry stays about 5 s; restore 3000 afterwards | US3-3, FR-006 |
| 14 | `nvim --headless "+qa"` | Exits with no output | FR-011, SC-006 |
| 15 | `nvim --startuptime /tmp/st.log +qa` | Total < 100 ms | FR-011, SC-006 |
| 16 | `:checkhealth`, and lua_ls diagnostics on `lua/config/notifications.lua` | No new errors | Constitution |
| 17 | `:map` count before/after | Unchanged | FR-011 |
| 18 | In a Lua buffer: `:lua vim.defer_fn(function() vim.notify("c") end, 2000)`, then `i`, type `vim.` so the completion menu opens, and wait | Popup appears; the completion menu stays open, unchanged; `<Tab>` still moves through it | FR-007, edge cases |
