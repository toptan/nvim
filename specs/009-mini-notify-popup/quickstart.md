# Quickstart: Notifications via mini.notify

Validation scenarios for the behaviour in [contracts/notifications.md](contracts/notifications.md).

## Prerequisites

- Neovim 0.12+, `git`, network access for the first start.
- Repository checked out as the Neovim config directory.

## 1. Fresh install (US3, SC-004)

1. Remove `~/.local/share/nvim/site/pack/core/opt/mini.notify` (if present).
2. Start `nvim`. Expected: the plugin installs without a prompt; the editor is usable.
3. `:checkhealth vim.pack` lists `mini.notify` with no errors.

## 2. Popup (US1, SC-001, SC-002)

1. Press `<leader>td`. Expected: `Diagnostics: off` appears top right in a rounded popup titled
   ` Notifications `, prefixed with a time; cursor stays in the buffer.
2. In insert mode run `<C-o>:lua vim.notify("x")<CR>` and keep typing. No keys are lost.
3. Wait ~5 s: the notification disappears and the popup closes.
4. `:lua vim.notify("e", vim.log.levels.ERROR)` is red; `WARN` yellow; `DEBUG` shows nothing.

## 3. History (FR-009)

1. `:lua MiniNotify.show_history()` lists the notifications from steps above.

## 4. Custom code removed (US2, SC-003)

1. `grep -n "TIMEOUT_MS\|MAX_ENTRIES\|nvim_open_win" lua/config/notifications.lua` → no matches.
2. Only one popup appears for each notification.
3. README "Notifications" section describes the plugin and its history command.

## 5. Fault tolerance (FR-007, SC-005)

1. In an isolated `NVIM_APPNAME` copy of the config, point the plugin `src` at a non-existent
   repository and start Neovim in a terminal. Expected: the editor starts with no "Press ENTER"
   prompt; at most one install-failure notice; `:lua vim.notify("x")` shows on the command line
   (built-in behaviour).
2. Delete the scratch copy.

## 6. Regression checks (FR-010, SC-006)

```sh
nvim --headless "+qa"                       # no output, exit 0
nvim --headless --startuptime /tmp/st.log +qa && tail -1 /tmp/st.log   # < 100 ms
nvim --headless "+lua print(#vim.api.nvim_get_keymap('n'))" +qa        # unchanged count
```

- `:checkhealth` shows no new errors; lua_ls reports no diagnostics in the changed file.
