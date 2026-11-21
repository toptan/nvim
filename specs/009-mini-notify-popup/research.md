# Research: Notifications via mini.notify

All findings come from a throwaway prototype (isolated `XDG_*` dirs, `NVIM_APPNAME`) on
Neovim 0.12.6 with `mini.notify` at `95531373`, driven headless and in tmux.

## R1. Which repository to install

- **Decision**: the standalone repository `https://github.com/nvim-mini/mini.notify`.
- **Rationale**: the spec wants only the notification module; the standalone repo contains just
  `lua/mini/notify.lua`, docs and licence. Installed name: `mini.notify`.
- **Alternatives**: `nvim-mini/mini.nvim` (whole library, ~40 modules) — rejected, pulls in code
  that is never used.

## R2. How notifications are routed to the plugin

- **Decision**: call `require("mini.notify").setup()` with no arguments.
- **Rationale**: `setup()` itself sets `vim.notify = MiniNotify.make_notify()` (verified:
  `vim.notify` changes after `setup()`), so no extra wiring and no option overrides (FR-002).
  It also exports the `MiniNotify` global; that global is created by the plugin, not by this
  config, so Principle II ("no globals introduced by the config") is respected.
- **Alternatives**: `vim.notify = MiniNotify.make_notify({...})` with custom durations —
  rejected, the user asked for defaults.

## R3. Defaults that become user-visible behaviour

| Aspect | Default (verified) |
|--------|--------------------|
| Position | Top right (`anchor = "NE"`), below the tabline when shown |
| Border | Follows `'winborder'` (`rounded` in this config); `single` only if `'winborder'` is empty |
| Title | ` Notifications ` (same text as feature 008) |
| Content | Each line prefixed with `HH:MM:SS │ `; popup lists newest first, history oldest first |
| Duration | ERROR / WARN / INFO: 5000 ms each, independently |
| DEBUG / TRACE / OFF | Duration 0: not shown **and not recorded** in history |
| Colours | `DiagnosticError` / `DiagnosticWarn` / `DiagnosticInfo` |
| Size | Width ≤ 38.2% of the editor; wraps; height capped to the screen |
| Window | Not focusable, `winblend = 25`, `zindex = 999` |
| Extras | LSP progress messages shown (`lsp_progress.enable = true`, last one stays 1 s) |
| History | `MiniNotify.show_history()` opens a scratch buffer; nothing is written to `:messages` |
| Entry limit | None (all active notifications are shown) |

Differences from feature 008 (3 s, ≤ 3 entries, `:messages`, debug shown as info) are accepted
by the spec ("defaults are good enough").

## R4. Startup notifications, textlock, fast events, headless

- **Decision**: rely on the plugin; no extra code.
- **Rationale**: `make_notify()` returns a `vim.schedule_wrap`-ped function; `refresh()`
  defers itself inside fast events and textlock (via `SafeState`). In the prototype, a WARN
  issued from `init.lua` appeared in the popup once the TUI was drawn. Headless start/quit with
  a startup notification printed nothing and exited 0.

## R5. Installation with `vim.pack` and failure handling

- **Decision**:
  `pcall(vim.pack.add, { "https://github.com/nvim-mini/mini.notify" }, { confirm = false })`,
  then `pcall` around `require("mini.notify").setup()`.
- **Rationale**: `confirm = false` makes the first-start install need zero manual steps
  (SC-004, Principle IV). With an unreachable repository, `vim.pack.add` reports the git error
  as a message and does not abort startup; `require` then fails and is caught, so `setup()` never
  runs and `vim.notify` stays the built-in one (FR-007). On a fresh clone the first start
  (headless included) prints vim.pack's "Installing plugins" progress lines; later starts are
  silent.
- **Alternatives**: default `confirm = true` — rejected, adds a prompt on fresh installs.
  No `pcall` — rejected, a broken plugin checkout would raise at startup.
- **Open risk**: the prototype only checked the failure path headless, where the multi-line git
  error was printed but did not block. In the TUI a multi-line message at startup can raise a
  "Press ENTER" prompt, which would break Constitution IV's "single, non-blocking notice". T009
  checks this. Fallback if it blocks: call `vim.pack.add` with
  `{ confirm = false, load = true }` inside `pcall` while temporarily replacing `vim.notify`
  with a function that collects messages, then emit one
  `vim.notify("mini.notify: install failed (see :messages)", vim.log.levels.WARN)`, which is a
  single line and does not prompt.
- **Outcome (implementation, T009)**: in the TUI the error is raised by `vim.pack.add` and
  caught by `pcall`, so nothing blocks, but the failure was silent. The module now schedules one
  WARN line (`mini.notify unavailable: notifications use the command line`); scheduling keeps
  vim.pack's final progress message from overwriting it. No "Press ENTER" prompt. A failed
  clone can take ~10 s (GitHub auth round-trip) before the editor is usable; this only happens
  while the plugin is not installed.

## R6. Where the code lives and when it loads

- **Decision**: rewrite `lua/config/notifications.lua` as a short module that installs and
  sets up the plugin; keep its `require` in `init.lua` right after `config.options`.
- **Rationale**: Principle II allows a module per plugin; keeping the name and position keeps
  the existing guarantee that every later module's notifications reach the popup. Loading must be
  eager (notifications can come from any module at any time), which Principle III permits when
  justified. Measured cost: `require('vim.pack')` 0.7 ms + `require('mini.notify')` 0.4 ms;
  whole startup went from ~8.2 ms to ~10.4 ms with the real config (implementation, T011), far
  below the 100 ms budget.
- **Alternatives**: a new `lua/plugins/` directory — rejected, one plugin does not justify a new
  layout; lazy loading on first `vim.notify` — rejected, adds custom wrapper code the spec wants
  gone, for ~0.4 ms gain.

## R7. Tooling side effects

- `lsp/lua_ls.lua` already adds every `vim.pack` plugin to the library, so `MiniNotify` gets
  types automatically.
- `nvim-pack-lock.json` is created/updated by `vim.pack` and is already git-ignored.
- `:checkhealth vim.pack` should report the plugin as installed.
