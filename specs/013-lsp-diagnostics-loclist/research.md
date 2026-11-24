# Research: Diagnostics List in the Location List

All findings were checked on Neovim 0.12.6 with lua_ls installed at `/usr/bin`, using
headless scripts against a scratch project with deliberate errors.

## R1. Filling the location list

- **Decision**: Collect diagnostics with `vim.diagnostic.get(bufnr)` (buffer) or
  `vim.diagnostic.get()` (workspace). Drop those whose namespace/buffer is disabled
  (`vim.diagnostic.is_enabled({ bufnr, ns_id })`). Sort them ourselves and turn them into
  quickfix items. Call `vim.fn.setloclist(win, {}, action, what)` on the target window,
  then `:lopen` from it.
- **Rationale**: `vim.diagnostic.setloclist()` only covers the window's own buffer, sorts by
  buffer number (not severity or file name), and gives no control over entry text. Building
  the items ourselves meets FR-001 to FR-004 with core functions only. `vim.diagnostic.get()`
  returns stored diagnostics even when display is turned off, so the explicit
  `is_enabled` filter is what gives the "treated as no diagnostics" edge case.
- **Action**: `"r"` (replace) when the window's current list is one of ours, so pressing
  the key again refreshes it in place and keeps its id. Otherwise `" "`, which pushes a
  new list so an unrelated list stays reachable with `:lolder`.
- **Order of calls**: when the list window is already open, `setloclist()` re-renders it
  at once and calls `quickfixtextfunc` for the new items. The list record must therefore
  exist under the list's id *before* items are set. A new list is first created empty
  (`" "` with only `title`), its id is read, the record is stored, and only then are the
  items and `quickfixtextfunc` set with `"r"` and that `id`. A reused list already has
  its id. (Headless, `:lopen` happened to re-render the list anyway, so blank entries did
  not appear even with the reverse order; the order above does not rely on that.)
- **Alternatives**: `vim.diagnostic.setloclist()` + `toqflist()` (wrong order, no colour
  hook); the quickfix list (rejected by the spec).

## R2. Project-wide diagnostics (`<Leader>lD`)

- **Finding**: lua_ls does **not** advertise `workspace/diagnostic` (pull);
  `diagnosticProvider` is `nil`. It pushes diagnostics for unopened project files by
  itself. In the scratch project, a file that was never opened had its error reported
  0.7 s after the first file was opened. Its buffer is created unloaded and unlisted.
  clangd has no project-wide diagnostics. The editor's request is
  `vim.lsp.buf.workspace_diagnostics({ client_id })`, which returns immediately and has no
  completion callback.
- **Decision**: On `<Leader>lD`, call `vim.lsp.buf.workspace_diagnostics({ client_id })`
  for each client attached to the target buffer that `supports_method("workspace/diagnostic")`.
  Then `vim.wait(2000, cond, 50)`, where `cond` is true once none of those clients has an
  entry in `client.requests` with `method == "workspace/diagnostic"` and
  `type == "pending"`. With no such clients there is no wait. Then list everything
  `vim.diagnostic.get()` holds.
- **Rationale**: `client.requests` is a documented public field. `vim.wait` keeps
  processing events, so responses are handled and `<C-c>` still interrupts. Meets
  FR-002/FR-002a with no private API. For today's servers the wait is skipped, and lua_ls
  results for unopened files are already in the store.
- **Spec follow-up**: the Assumptions line "lua_ls supports this" is corrected to say
  lua_ls reports whole-project diagnostics on its own, and the explicit request reaches
  only servers that support pull diagnostics.
- **Alternatives**: our own `workspace/diagnostic` request (results would bypass the
  diagnostic store unless private `handle_diagnostics` were used); `LspRequest` autocmd
  counting (more moving parts than polling `client.requests`).

## R3. Entry text and severity colours

- **Decision**: Pre-compute each entry's display line when building the list:
  `{file}|{lnum} col {col} {label}| {message}`. Here `file` is
  `fnamemodify(bufname, ":~:.")`, `label` is one of `error`, `warning`, `info`, `hint`, and
  the message has newlines replaced by spaces. Store the lines and the byte ranges of the
  label and message in a module table keyed by list id. A per-list `quickfixtextfunc`
  (a Lua function passed in `what`, which `vim.fn` turns into a Funcref) returns these
  lines. A decoration provider (`nvim_set_decoration_provider`) adds ephemeral extmarks on
  visible rows of quickfix-type buffers whose window's location list id is in the table:
  `DiagnosticError`, `DiagnosticWarn`, `DiagnosticInfo` or `DiagnosticHint` over the label
  and the message. `on_win` looks the record up once per window redraw and keeps it for
  that window's `on_line` calls.
- **Verified**: the prototype rendered the custom text in the location list window.
  `screenattr()` showed the label cells with a different attribute per severity, and the
  file name with the plain list attribute, all headless.
- **Rationale**: The decoration provider re-runs on every redraw. Colours therefore follow
  `:colorscheme` changes (the groups are named, not copied), survive `:lclose`/`:lopen`
  and `:lolder`/`:lnewer`, and need no clean-up. Lists not in the table (e.g.
  `:lvimgrep`) are untouched, which meets the FR-003a edge case. The `|…|` layout keeps
  the built-in `qf` syntax for file name and line/column.
- **Laziness**: The provider is registered on the first key press, not at startup
  (Principle III).
- **Alternatives**: persistent extmarks set after `:lopen` (lost when the buffer is
  re-rendered); `matchaddpos` (window-local and must be refreshed by hand); `syntax match`
  on label words (cannot colour the message by its row's severity).

## R4. `<Esc>` and `<CR>` in the location list

- **Decision**: A `FileType qf` autocmd (augroup `config_diagnostic_list`) sets a
  buffer-local Normal-mode `<Esc>` when `vim.fn.win_gettype() == "loclist"`. It reads
  `getloclist(0, { filewinid = 0 }).filewinid`, runs `:lclose`, and focuses that window if
  it is still valid. `<CR>` is not remapped: the built-in `<CR>` in a location list already
  jumps to the entry in the file window, moves focus there and keeps the list open
  (FR-008).
- **Rationale**: The buffer-local map shadows the global `<Esc>` (search highlight) only
  in location list windows (FR-011). Quickfix windows (`win_gettype() == "quickfix"`) are
  untouched. `filewinid` is the documented way to find the owning window, and was checked
  in the prototype (`filewinid` = the window `:lopen` was run from). The autocmd costs
  nothing at startup and is needed there, so lists opened with `:lopen` also get `<Esc>`.
- **Alternatives**: `wincmd p` after closing (the previous window is not always the owner).

## R5. Target window

- **Decision**: If the current window is a location list window, the target is its
  `filewinid`. Otherwise it is the current window. The target's buffer is used for
  `<Leader>ld`, and the list is set on and opened from the target.
- **Rationale**: Covers the edge case "pressing `<Leader>ld` inside the list window". It
  also keeps one list window per file window (`:lopen` reuses an open one, FR-009).

## R6. Module placement and loading

- **Decision**: New module `lua/config/diagnostic_list.lua`, required from `init.lua` after
  `config.diagnostics`. At startup it only defines the two keymaps and the `FileType qf`
  autocmd. `vim.diagnostic`, `vim.lsp` and the decoration provider are touched on first
  key press only.
- **Rationale**: One concern per module (Principle II). Startup work is negligible
  (Principle III). `config.diagnostics` stays focused on display style and toggles.
