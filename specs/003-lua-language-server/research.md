# Research: Lua Language Server and Diagnostic Toggles

All findings verified on 2026-11-19 against Neovim 0.12.6 and lua-language-server 3.19.2
(Homebrew). Each behaviour was checked headless in a scratch copy of this config with a
prototype `lsp/lua_ls.lua`.

## R1 — How the server is configured (FR-001, Principle I)

- **Decision**: A native config file `lsp/lua_ls.lua` at the repository root returns a
  `vim.lsp.Config` table: `cmd = { "lua-language-server" }`, `filetypes = { "lua" }`,
  `root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" }`, `settings = { Lua = {} }`.
  `vim.lsp.enable("lua_ls")` activates it.
- **Rationale**: Neovim 0.11+ automatically merges `lsp/<name>.lua` files from the runtimepath
  into `vim.lsp.config`. Neovim 0.12.6 ships no `lsp/` configs of its own, so nothing has to be
  overridden. The nested root markers give `.luarc.*` priority over `.git`.
- **Alternatives considered**: `nvim-lspconfig` was rejected because core provides the
  mechanism and only one server is needed (Principle I). Inline `vim.lsp.config("lua_ls", …)`
  in a Lua module would work too, but the `lsp/` file is the documented native location and
  keeps the server definition out of the module that wires keys.

## R2 — Deferred start (FR-001, Principle III, SC-005)

- **Decision**: `config.lsp` creates a `FileType` autocommand for pattern `lua` with
  `once = true` in augroup `config_lsp` (`clear = true`). Its callback applies the initial
  diagnostic display (R5) and calls `vim.lsp.enable("lua_ls")`.
- **Rationale**: Measured headless startup (3 runs each):
  - baseline: 8.0–8.6 ms
  - eager `vim.lsp.enable` + `vim.diagnostic.config`: 12.8–13.3 ms (`require("vim.lsp")`
    ≈ 3.7 ms, `vim.diagnostic` ≈ 1.1 ms)
  - deferred via `FileType`: 7.7–7.9 ms (baseline)

  `vim.lsp.enable` runs `doautoall nvim.lsp.enable FileType` when `did_filetype()` is set, so
  the buffer that triggered the autocommand still gets attached. This was verified for
  `nvim init.lua`, and for `:edit` after startup.
- **Alternatives considered**: An eager `vim.lsp.enable` was rejected because it costs ~4.5 ms
  of startup for something tied to a filetype (Principle III). `ftplugin/lua.lua` was rejected
  because it runs for every Lua buffer and spreads LSP wiring outside `lua/config/`.

## R3 — Neovim runtime, own modules and plugins (FR-002, FR-003, FR-003a, FR-004)

- **Decision**: An `on_init(client)` hook:
  1. If the client's first workspace folder contains `.luarc.json` or `.luarc.jsonc`, return
     without changes. The project's own settings win (clarification).
  2. Otherwise, build
     `library = { vim.env.VIMRUNTIME, <path of every plugin from vim.pack.get(nil, { info = false })> }`
     (with `vim.pack.get` wrapped in `pcall`) and deep-merge into `client.config.settings.Lua`:
     `runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } }`,
     `workspace = { checkThirdParty = false, library = library }`.
  3. Send `workspace/didChangeConfiguration` with the merged settings.
- **Rationale**:
  - `$VIMRUNTIME` contains the `vim.*` API sources and `_meta` type files, including
    `lua/uv/_meta.lua` for `vim.uv`. It is found at run time, so no paths are hard-coded
    (FR-004).
  - Library roots combined with `runtime.path` `lua/?.lua` let `require("x")` resolve inside
    every library. The workspace root (the config directory, via `.git`) resolves
    `require("config.*")`.
  - `vim.pack.get()` lists every plugin installed through the config with its `path`. It is
    evaluated on each server start, so plugins added or removed later are picked up after a
    restart (FR-003a). With no plugins installed it returns an empty list (verified).
  - Implementation note: `vim.pack.get()` creates the plugin directory
    (`stdpath("data")/site/pack/core/opt`) when it is missing, which makes `:checkhealth`
    warn "Lockfile is absent, plugin directory is present". The call is therefore skipped
    when that directory does not exist, because without it there are no plugins.
  - Verified: 0 diagnostics across `init.lua` and `lua/config/*.lua`. Hover on
    `vim.api.nvim_create_autocmd` shows its signature. Definition of
    `require("config.keymaps")` opens `lua/config/keymaps.lua`. A real undefined global is
    still reported. In a project with `.luarc.json`, `vim` is reported as undefined, so
    nothing was injected there.
- **Alternatives considered**:
  - A committed `.luarc.json` was rejected: it needs the machine-specific `$VIMRUNTIME` path
    (FR-004), and it would mark the config itself as "a project with its own settings".
  - `nvim_get_runtime_file("", true)` as the library was rejected: it includes the config
    directory itself, so the workspace would be treated as a library and lose diagnostics, and
    it only sees plugins that are currently loaded.
  - `lazydev.nvim` was rejected because core suffices (Principle I).

## R4 — Limiting workspace scans (FR-006)

- **Decision**: Rely on root markers. Do not set `root_dir` to the current working directory,
  and do not add `$HOME` or `stdpath` directories to the library beyond R3.
- **Rationale**: A Lua file under no marker gets `root_dir = nil`, so lua_ls runs in
  single-file mode and scans no directory (verified). For the config, the root is the config
  directory (its `.git`).
- **Note**: In single-file mode lua_ls 3.19.2 published no diagnostics for a loose file, with
  or without the R3 settings. This is the server's own behaviour, and loose files are outside
  this feature's acceptance scenarios.

## R5 — Diagnostic display and toggles (FR-007–FR-012)

- **Decision**:
  - Initial display (FR-012):
    `vim.diagnostic.config({ virtual_text = true, virtual_lines = false })`. Neovim 0.12
    defaults both to `false`, so the setting is required. It is applied by a
    `config.diagnostics.setup()` that is idempotent. `setup()` is called from the deferred
    LSP hook (R2), from a one-time `DiagnosticChanged` autocommand in `config.diagnostics`
    (augroup `config_diagnostics`, for any other diagnostic source such as a future linter),
    and at the start of every toggle. `vim.diagnostic` is therefore never loaded at startup.
  - Ordering note: in 0.12.6, `vim.diagnostic.set()` calls `M.show()` first and fires
    `DiagnosticChanged` afterwards. `vim.diagnostic.config()` then re-renders synchronously
    in the same event-loop tick, before any redraw, so the default display is never visible
    on screen. This satisfies FR-012's "before the first diagnostic appears on screen".
  - `<leader>td`: `vim.diagnostic.enable(not vim.diagnostic.is_enabled())`. This is global
    when no filter is given.
  - `<leader>tt` / `<leader>tl`: flip `virtual_text` / `virtual_lines` with
    `vim.diagnostic.config({ … = not current })`. The two are independent (clarification).
  - Messages: `vim.notify(…, vim.log.levels.INFO)`, e.g. `Diagnostics: off`,
    `Diagnostic virtual text: on`. When diagnostics are disabled, the message for
    `tt`/`tl` adds `(diagnostics are off)` (US2 #4).
- **Rationale**: `vim.diagnostic.enable(false)` is separate from `vim.diagnostic.config`, so
  changes to the display while disabled are kept and apply on re-enable (FR-011). Verified:
  disable, set `virtual_text = false`, enable → `virtual_text` stays `false`. No module state
  is needed beyond a `did_setup` flag.
- **Alternatives considered**: Saving and restoring a config snapshot on `td` was rejected
  because core already separates enablement from display. Per-buffer toggles were rejected
  because the spec requires global ones.

## R6 — Formatting (FR-005, FR-013–FR-015)

- **Decision**: `<leader>lf` (normal mode, global mapping) works as follows:
  1. If the buffer is `readonly` or not `modifiable`, notify `Buffer is read-only` (WARN) and
     stop.
  2. If `vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting" })` is empty,
     notify `No language server can format this buffer` (WARN) and stop.
  3. Otherwise call
     `vim.lsp.buf.format({ bufnr = 0, async = false, timeout_ms = 3000 })`.
- **Rationale**:
  - lua_ls's built-in formatter (EmmyLuaCodeStyle) reads the workspace `.editorconfig`. Its
    `[*.lua]` keys (`quote_style`, `call_arg_parentheses`, `trailing_table_separator`, …) are
    applied. Verified: `{a=1,b='x'}` became `{ a = 1, b = "x", }`, `print 'hi'` became
    `print("hi")`, and 4-space indent became 2-space.
  - A synchronous request can't race with edits typed during formatting.
  - Edits are applied as one change, so a single `u` restores the original (verified).
  - The explicit client check replaces core's generic "[LSP] Format request failed" message
    with a clearer one (FR-014).
  - The mapping is global, so non-LSP buffers also get the message. This settles the open
    point from clarification.
- **Implementation note (2026-11-19)**: With the original `.editorconfig`, formatting the
  committed config changed 6 of 8 files. `align_call_args = true` aligned closure bodies
  under call arguments (~17 columns) and pushed lines past 80 columns, and
  `auto_collapse_lines = true` joined deliberately split tables. Both were set to `false`
  (agreed with the user). After that, every committed Lua file is format-stable (SC-004).
- **Alternatives considered**: `conform.nvim`/StyLua were rejected because the spec asks for
  formatting via the language server and core suffices. An `LspAttach` buffer-local mapping
  was rejected: in other buffers it would silently do nothing, so the FR-014 message would
  never show.

## R7 — Missing server (FR-018, FR-018a)

- **Decision**: No extra code.
- **Rationale**: In 0.12.6, `can_start()` validates that `cmd[1]` is executable. If it isn't,
  the error goes to the LSP log file only (`log.error`) and nothing is shown.
  `:checkhealth vim.lsp` reports `'lua-language-server' is not executable. Configuration will
  not be used.` This is exactly FR-018a.
- **Alternatives considered**: A custom `vim.fn.executable` guard with a notice was rejected
  by clarification.
