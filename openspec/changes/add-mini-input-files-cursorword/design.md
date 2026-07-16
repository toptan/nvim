## Context

`plugin/60-mini.lua` currently configures `mini.completion`, `mini.pairs`, `mini.bracketed`,
`mini.ai`, `mini.surround`, `mini.bufremove`, `mini.notify`, `mini.trailspace`, and `mini.clue`.
`plugin/20-keymaps.lua` defines `Config.leader_group_clues`, including an `e` "+Explore/Edit"
group that currently has no leaf keymaps under it.

`lua/retro/init.lua` (the shared colorscheme module) already defines highlight groups for
`MiniCursorword`/`MiniCursorwordCurrent` (underline style) and the full `MiniFiles*` set
(`MiniFilesBorder`, `MiniFilesBorderModified`, `MiniFilesCursorLine`, `MiniFilesDirectory`,
`MiniFilesFile`, `MiniFilesNormal`, `MiniFilesTitle`, `MiniFilesTitleFocused`) — written ahead of
either module actually being configured. No `MiniInput*` groups exist, but `mini.input` renders its
prompt using ordinary buffer/statusline highlighting, not module-specific groups, so none are
needed.

Relevant default configs (for reference; full listings are in each module's source under
`mini.nvim`'s own `lua/mini/*.lua`):

```lua
-- mini.input
scope = 'editor'  -- only config knob; controls where the prompt is drawn
-- setup() itself runs `vim.ui.input = MiniInput.ui_input` — no separate wiring call needed
```

```lua
-- mini.cursorword
delay = 100  -- ms between cursor stopping and highlight appearing
-- No mappings; purely automatic highlighting via CursorMoved/CursorHold.
```

```lua
-- mini.files
mappings = {
  close = 'q', go_in = 'l', go_in_plus = 'L', go_out = 'h', go_out_plus = 'H',
  mark_goto = "'", mark_set = 'm', reset = '<BS>', reveal_cwd = '@', show_help = 'g?',
  synchronize = '=', trim_left = '<', trim_right = '>',
}
-- These are buffer-local mappings created only inside the explorer buffer; there is no default
-- *global* keymap to open/toggle the explorer at all — that's left entirely to the user.
options = { permanent_delete = true, use_as_default_explorer = true, lsp_timeout = 1000 }
windows = { max_number = math.huge, preview = false, width_focus = 50, width_nofocus = 15, width_preview = 25 }
```

`mini.files`' own documentation (`:h mini.files-example-mappings`, "Toggle explorer" section)
gives the canonical toggle recipe directly:
```lua
local minifiles_toggle = function(...)
  if not MiniFiles.close() then MiniFiles.open(...) end
end
```
`MiniFiles.close()` returns `true` if it closed something, `false` if the user declined to confirm
closing over pending unsaved file-system actions, or `nil` if there was nothing open to close.
`MiniFiles.open(path, use_latest, opts)` anchors on `path`'s parent directory (focusing `path`
itself) if `path` is a file, or opens `path` directly if it's a directory; `path` defaults to
`vim.fn.getcwd()`.

## Goals / Non-Goals

**Goals**
- `mini.input`: zero custom configuration — `setup()` alone wires `vim.ui.input`.
- `mini.cursorword`: zero custom configuration — upstream default 100ms delay.
- `mini.files`: zero custom configuration for the module itself; two new global keymaps using the
  module's own documented toggle recipe:
  - `-`: toggle, anchored on the current buffer's file (`vim.api.nvim_buf_get_name(0)`).
  - `<Leader>ed`: toggle, anchored on the current working directory (`vim.fn.getcwd()`).

**Non-Goals**
- No custom `mini.input` `handlers` or non-default `scope`.
- No custom `mini.cursorword` `delay` override.
- No `mini.files` `content`/`windows`/`options` overrides (preview stays off, permanent delete
  stays on, `use_as_default_explorer` stays on — see Risks).
- No explicit disabling of netrw (`g:loaded_netrw`/`g:loaded_netrwPlugin`) — `use_as_default_explorer
  = true` is sufficient for `mini.files` to take over directory-buffer editing without it.
- No additional `mini.clue` triggers for `-` or `<Leader>e` — consistent with the minimal,
  explicitly-curated trigger set established in prior changes (only `<Leader>`, `g`, `z`, marks,
  registers, windows, and `mini.bracketed`'s `[`/`]` are configured as triggers).

## Decisions

### 1. `mini.input` and `mini.cursorword`: `setup()` with no arguments

```lua
require("mini.input").setup()
require("mini.cursorword").setup()
```
Matches the user's ask directly (`mini.input` for the `vim.ui.input()` implementation) and
`mini.nvim`'s own "just call setup()" usage for default behavior — the same pattern already used
for `mini.pairs`, `mini.bracketed`, and `mini.surround` in this config.

### 2. `mini.files`: `setup()` with no arguments, plus two toggle keymaps

```lua
require("mini.files").setup()

local function toggle_files(path)
  if not require("mini.files").close() then
    require("mini.files").open(path)
  end
end

vim.keymap.set("n", "-", function()
  toggle_files(vim.api.nvim_buf_get_name(0))
end, { desc = "Toggle file explorer (current file)" })

vim.keymap.set("n", "<Leader>ed", function()
  toggle_files(vim.fn.getcwd())
end, { desc = "Explore directory (cwd)" })
```
Placed in `plugin/60-mini.lua` rather than `plugin/20-keymaps.lua`: per `CLAUDE.md`,
`20-keymaps.lua` holds keymaps "not owned by a specific plugin/LSP feature"; these are owned by
`mini.files` specifically (they call its API directly), matching how `mini.bufremove`'s,
`mini.notify`'s, and `mini.trailspace`'s keymaps already live alongside their modules' `setup()`
calls in `60-mini.lua` rather than in `20-keymaps.lua`.

**Alternative considered**: give `-` and `<Leader>ed` the same anchor (both current-file, or both
cwd). Rejected per explicit user approval of the two-distinct-anchors design — `-` as a quick
reveal-current-file toggle (oil.nvim-style convention) and `<Leader>ed` as a project-root toggle
are complementary rather than redundant.

**Alternative considered**: make `<Leader>ed` a plain (non-toggle) `MiniFiles.open(vim.fn.getcwd())`
call instead of sharing the toggle recipe. Rejected — using the same `toggle_files()` helper for
both keymaps is simpler and keeps behavior consistent (either key closes the explorer if it's
already open, rather than only one of them being able to close it).

## Risks / Trade-offs

- **`-` shadows Neovim's built-in `-` ("move to first non-blank character of previous line")**.
  Accepted — this is a niche built-in rarely reached for since `k` (or `k^`) covers the same need,
  and repurposing `-` for file-explorer toggling is a well-established convention (oil.nvim and
  others use it the same way).
- **`mini.files`' default `permanent_delete = true` means deleting a file/directory inside the
  explorer is not recoverable via any trash or undo mechanism mini.files provides.** Accepted as
  the upstream default; no local override added. Standard OS/filesystem recovery (or version
  control) remains the only safety net.
- **`use_as_default_explorer = true` means any `:edit <directory>` (or a directory argument passed
  to `nvim`) now opens `mini.files` instead of netrw**, a global behavior change beyond just the
  two new keymaps. Accepted as the intended purpose of adding the module — netrw was never
  configured or styled in this config to begin with.
- **The documented toggle recipe's edge case**: if `MiniFiles.close()` returns `false` (user
  declined to confirm closing over pending unsaved file-system actions inside the explorer) and
  the same toggle key is pressed again immediately, `toggle_files()` will call `open()` and
  re-display the explorer rather than leaving it closed as the user might expect from a "cancel".
  This is inherent to `mini.files`' own documented recipe (see Context), not something specific to
  this config; not mitigated.

## Open Questions

None — the two `mini.files` keymaps and their anchor semantics were reviewed and approved before
writing this design.
