## Context

`plugin/60-mini.lua` currently configures `mini.completion`, `mini.pairs`, `mini.bracketed`,
`mini.ai`, `mini.surround`, `mini.bufremove`, `mini.notify`, `mini.trailspace`, `mini.input`,
`mini.cursorword`, `mini.files`, and `mini.clue`. `plugin/20-keymaps.lua` defines
`Config.leader_group_clues`, including an `f` "+Find" group that currently has no leaf keymaps.
`vim.o.laststatus` is at Neovim's own default (`2`, window-local statusline) — this config never
sets it.

`lua/retro/init.lua` (the shared colorscheme module) already defines `MiniIndentscopeSymbol`, the
full `MiniStatusline*` set (`MiniStatuslineDevinfo`, `MiniStatuslineFileinfo`,
`MiniStatuslineFilename`, `MiniStatuslineInactive`, `MiniStatuslineMode{Command,Insert,Normal,
Other,Replace,Visual}`), and the full `MiniPick*` set (border, icons, header, match highlighting,
normal/preview/prompt groups) — all written ahead of any of these three modules actually being
configured, same pattern as `MiniCursorword`/`MiniFiles*` before them. `DiagnosticError`,
`DiagnosticWarn`, `DiagnosticInfo`, and `DiagnosticHint` are also already defined (used today for
the sign column and virtual text via `plugin/40-lsp.lua`'s diagnostic config). No `MiniIcons*`
module is installed (only its highlight groups are pre-defined in the colorscheme, unused); neither
`mini.icons` nor `nvim-web-devicons` is a dependency of this config.

Relevant default configs and behaviors (for reference; full listings are in each module's source
under `mini.nvim`'s own `lua/mini/*.lua`):

```lua
-- mini.indentscope
draw = {
  delay = 100,
  animation = function(s, n) return 20 end,  -- constant 20ms/step - still an animation
  predicate = function(scope) return not scope.body.is_incomplete end,
  priority = 2,
},
mappings = {
  object_scope = 'ii', object_scope_with_border = 'ai',  -- textobjects
  goto_top = '[i', goto_bottom = ']i',                    -- motions
},
options = { border = 'both', indent_at_cursor = true, n_lines = 10000, try_as_border = false },
symbol = '╎',
```
The default `[i`/`]i` motions are picked up automatically by `mini.clue`'s existing `[`/`]`
triggers (already configured generically for `mini.bracketed`'s groups) — no new `mini.clue`
trigger needed.

```lua
-- mini.statusline
content = { active = nil, inactive = nil },  -- nil means "use module's own default function"
use_icons = true,
```
The module's own documentation (`:h mini.statusline-example-content`) gives the exact default
`content.active` function verbatim — this is the base every custom `content.active` is expected to
start from:
```lua
function()
  local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
  local git           = MiniStatusline.section_git({ trunc_width = 40 })
  local diff          = MiniStatusline.section_diff({ trunc_width = 75 })
  local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 75 })
  local lsp           = MiniStatusline.section_lsp({ trunc_width = 75 })
  local filename      = MiniStatusline.section_filename({ trunc_width = 140 })
  local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
  local location      = MiniStatusline.section_location({ trunc_width = 75 })
  local search        = MiniStatusline.section_searchcount({ trunc_width = 75 })

  return MiniStatusline.combine_groups({
    { hl = mode_hl,                  strings = { mode } },
    { hl = 'MiniStatuslineDevinfo',  strings = { git, diff, diagnostics, lsp } },
    '%<',
    { hl = 'MiniStatuslineFilename', strings = { filename } },
    '%=',
    { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
    { hl = mode_hl,                  strings = { search, location } },
  })
end
```
`MiniStatusline.section_diagnostics()` builds one string covering all severities (e.g. `" E2 W3"`),
which `combine_groups()` then wraps in a *single* `MiniStatuslineDevinfo` highlight alongside git/
diff/LSP — there is no per-severity coloring available from that section function or the default
content function. `combine_groups(groups)` accepts an array where each entry is either a literal
string (inserted as-is, e.g. `'%<'`/`'%='` markers) or a `{ hl = <group>, strings = {...} }` table
that gets wrapped as `%#<group># <joined strings> %#<group>#`. This is the mechanism used to give
diagnostics per-severity coloring: build one `{ hl = ..., strings = {...} }` entry per non-zero
severity level, using the same `DiagnosticError`/`DiagnosticWarn`/`DiagnosticInfo`/`DiagnosticHint`
groups already used elsewhere, and splice them into the same `groups` array in place of the single
`diagnostics` entry.

```lua
-- mini.pick
mappings = { -- extensive in-picker keys: choose/mark/scroll/move/etc.
  choose = '<CR>', choose_in_split = '<C-s>', ..., stop = '<Esc>', ... },
options = { content_from_bottom = false, use_cache = false },
window = { config = nil, prompt_caret = '▏', prompt_prefix = '> ' },
```
These are buffer-local mappings active only inside an open picker window — no conflict with any
mapping elsewhere in this config; kept at their defaults (no non-goal violation). `mini.pick` also
auto-creates a `:Pick` user command on `setup()` (`:Pick files tool='git'`, `:Pick grep
pattern='foo'`, etc.) regardless of what keymaps are added.

`mini.pick.builtin` has exactly seven pickers (no `mini.extra` module involved — that would add
many more, e.g. `diagnostic`/`git_*`/`marks`/`oldfiles`, but was not requested): `files`, `grep`,
`grep_live`, `help`, `buffers`, `cli`, `resume`. None has a default global keymap; each is a plain
Lua function (`MiniPick.builtin.files(local_opts, opts)`, etc.) the user is expected to map
themselves. `files`/`grep` prefer `fd`/`rg`/`git` (in that order for `files`; `rg` then `git` for
`grep`) and fall back to a slow pure-Lua/`vim.fs.dir()` implementation if none is present;
`grep_live` has *no* fallback — it throws an error if neither `rg` nor `git` is executable ("for
performance reasons", per its own doc comment). This system has `rg` and `git` on `PATH` (no `fd`),
so `files` uses `git`, and `grep`/`grep_live` use `rg`.

## Goals / Non-Goals

**Goals**
- `mini.indentscope`: only override `draw.animation` to `gen_animation.none()`; everything else
  default.
- `mini.statusline`: custom `content.active` giving diagnostics counts per-severity coloring
  matching `DiagnosticError`/`Warn`/`Info`/`Hint`; every other section identical to the module's
  own default content function, in the same order.
- `mini.pick`: `setup()` with no options; seven new keymaps (`<Leader>ff`/`fg`/`fG`/`fb`/`fh`/`fr`/
  `fc`) under the existing `<Leader>f` "+Find" group, one per builtin picker.

**Non-Goals**
- No `mini.extra` module (and none of its extra pickers) — out of scope; not requested.
- No `mini.icons` or `nvim-web-devicons` dependency added — `mini.statusline`'s and `mini.pick`'s
  icon-related sections (`section_fileinfo()`, file-entry icons) gracefully degrade to text-only
  without either, per their own documented fallback behavior.
- No customization of `mini.indentscope`'s `symbol`, `border`, `n_lines`, `indent_at_cursor`, or
  `try_as_border` options, or its default `ii`/`ai`/`[i`/`]i` mappings.
- No customization of `mini.statusline`'s `use_icons`, `section_mode`/`section_git`/`section_diff`/
  `section_lsp`/`section_filename`/`section_fileinfo`/`section_location`/`section_searchcount`
  output or truncation widths — only the diagnostics section's coloring changes.
- No `inactive` content customization for `mini.statusline` — stays the module's default
  (`%#MiniStatuslineInactive#%F%=`).
- No customization of `mini.pick`'s in-picker `mappings`, `window`, or `options` — defaults only.
- No new `mini.clue` triggers for `<Leader>f` sub-keys beyond what's already covered by the
  existing `<Leader>` trigger (the whole `<Leader>f...` group already gets a clue popup from the
  existing `{ mode = "n"/"x", keys = "<Leader>" }` triggers and `Config.leader_group_clues`'s `f`
  entry — no new trigger key is introduced here since `f` was already listed as a leader group).
- No `vim.o.laststatus` change — left at Neovim's existing default.

## Decisions

### 1. `mini.indentscope`: disable animation only

```lua
require("mini.indentscope").setup({
  draw = {
    animation = require("mini.indentscope").gen_animation.none(),
  },
})
```
Matches the user's explicit ask (no animation) via the module's own documented mechanism
(`gen_animation.none()`, referenced directly in the default config's own comments) while leaving
every other option — including the default `ii`/`ai`/`[i`/`]i` mappings — untouched.

### 2. `mini.statusline`: custom `content.active`, diagnostics colored by severity

```lua
local function diagnostics_by_severity(trunc_width)
  local ministatusline = require("mini.statusline")
  if ministatusline.is_truncated(trunc_width) or not vim.diagnostic.is_enabled({ bufnr = 0 }) then
    return {}
  end

  local count = vim.diagnostic.count(0)
  local levels = {
    { name = "ERROR", sign = "E", hl = "DiagnosticError" },
    { name = "WARN", sign = "W", hl = "DiagnosticWarn" },
    { name = "INFO", sign = "I", hl = "DiagnosticInfo" },
    { name = "HINT", sign = "H", hl = "DiagnosticHint" },
  }

  local groups = {}
  for _, level in ipairs(levels) do
    local n = count[vim.diagnostic.severity[level.name]] or 0
    if n > 0 then
      table.insert(groups, { hl = level.hl, strings = { level.sign .. n } })
    end
  end
  return groups
end

require("mini.statusline").setup({
  content = {
    active = function()
      local ministatusline = require("mini.statusline")
      local mode, mode_hl = ministatusline.section_mode({ trunc_width = 120 })
      local git = ministatusline.section_git({ trunc_width = 40 })
      local diff = ministatusline.section_diff({ trunc_width = 75 })
      local lsp = ministatusline.section_lsp({ trunc_width = 75 })
      local filename = ministatusline.section_filename({ trunc_width = 140 })
      local fileinfo = ministatusline.section_fileinfo({ trunc_width = 120 })
      local location = ministatusline.section_location({ trunc_width = 75 })
      local search = ministatusline.section_searchcount({ trunc_width = 75 })

      local groups = {
        { hl = mode_hl, strings = { mode } },
        { hl = "MiniStatuslineDevinfo", strings = { git, diff } },
      }
      vim.list_extend(groups, diagnostics_by_severity(75))
      table.insert(groups, { hl = "MiniStatuslineDevinfo", strings = { lsp } })
      table.insert(groups, "%<")
      table.insert(groups, { hl = "MiniStatuslineFilename", strings = { filename } })
      table.insert(groups, "%=")
      table.insert(groups, { hl = "MiniStatuslineFileinfo", strings = { fileinfo } })
      table.insert(groups, { hl = mode_hl, strings = { search, location } })

      return ministatusline.combine_groups(groups)
    end,
  },
})
```
This reuses every section function and truncation width from the module's own documented default
content function unchanged, splitting only the single `diagnostics` string into per-severity
`combine_groups()` entries — so layout, spacing, and truncation behavior stay identical to the
default; only the diagnostics segment gains per-level color.

**Alternative considered**: keep `MiniStatusline.section_diagnostics()`'s single string but inject
raw `%#DiagnosticError#`/etc. highlight-switch codes directly inside that one string. Rejected —
`combine_groups()` already exists specifically to produce correctly-formatted multi-highlight
segments (padding, missing-section handling); manually splicing `%#...#` codes into a plain string
would duplicate what `combine_groups()` does, more fragile and against the module's own documented
pattern.

**Alternative considered**: use `MiniStatusline.section_diagnostics({ signs = {...} })`'s `signs`
argument to customize sign characters, then separately colorize. Rejected — `signs` only lets you
override the letter shown per level (e.g. `E`/`W`/`I`/`H` themselves), it doesn't affect
`combine_groups()`'s single-highlight wrapping of the whole returned string; per-severity color
requires building the segments directly, as above.

### 3. `mini.pick`: `setup()` with no options, seven keymaps under `<Leader>f`

```lua
require("mini.pick").setup()

vim.keymap.set("n", "<Leader>ff", function()
  require("mini.pick").builtin.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<Leader>fg", function()
  require("mini.pick").builtin.grep_live()
end, { desc = "Live grep" })

vim.keymap.set("n", "<Leader>fG", function()
  require("mini.pick").builtin.grep()
end, { desc = "Grep (pattern)" })

vim.keymap.set("n", "<Leader>fb", function()
  require("mini.pick").builtin.buffers()
end, { desc = "Find buffers" })

vim.keymap.set("n", "<Leader>fh", function()
  require("mini.pick").builtin.help()
end, { desc = "Find help tags" })

vim.keymap.set("n", "<Leader>fr", function()
  require("mini.pick").builtin.resume()
end, { desc = "Resume last picker" })

vim.keymap.set("n", "<Leader>fc", function()
  -- `builtin.cli()` takes `command` as an argv table, not an interactive prompt;
  -- prompt for one via `vim.ui.input()` (mini.input) and split it into argv ourselves.
  vim.ui.input({ prompt = "CLI command: " }, function(input)
    if input == nil or input == "" then
      return
    end
    require("mini.pick").builtin.cli({ command = vim.split(input, "%s+") })
  end)
end, { desc = "Pick from CLI output" })
```
Placed in `plugin/60-mini.lua` rather than `plugin/20-keymaps.lua`: per `CLAUDE.md`,
`20-keymaps.lua` holds keymaps "not owned by a specific plugin/LSP feature"; these are owned by
`mini.pick` specifically, matching the same placement precedent as `mini.bufremove`'s,
`mini.notify`'s, `mini.trailspace`'s, and `mini.files`' keymaps.

**Discovered during implementation**: `MiniPick.builtin.cli(local_opts, opts)` takes
`local_opts.command` as an argv table (e.g. `{ "ls", "-la" }`) supplied by the caller — it has no
built-in interactive prompt of its own. Calling it bare (`cli()`, `command` defaulting to `{}`)
silently starts a picker with zero items instead of erroring, which is why the original plain
`require("mini.pick").builtin.cli()` produced no visible picker at all in manual testing (verified:
pressing `<Leader>fc` did nothing observable). This contradicted the proposal's assumption that
`cli` itself would prompt for a command. Fixed by wrapping the call in `vim.ui.input()` (already
`mini.input`, per this same change) to collect a command string first, then splitting it into argv
with `vim.split(input, "%s+")` before calling `builtin.cli({ command = ... })` — re-verified this
now correctly prompts, runs the typed command, and shows its output as pickable items.

**Known limitation of the `vim.split(input, "%s+")` argv split**: it has no quoting/escaping
support, so a command needing an argument with an embedded space (e.g. a path like `rg foo "my
dir"`) can't be expressed correctly. Accepted as a reasonable simplification for this
already-supplementary picker — matches `CLAUDE.md`'s guidance against solving hypothetical needs
up front; a full shell-lexer split can be added later if it's ever actually needed.

**Alternative considered**: different letters/grouping (e.g. `buffers` under `<Leader>b`). Rejected
per explicit user approval of the all-under-`<Leader>f` scheme — every one of these seven pickers
is fundamentally a "find/search" action, matching this config's own group description
("+Find"), and keeping them together avoids splitting one plugin's functionality across groups.

## Risks / Trade-offs

- **`mini.pick.builtin.grep_live` has no fallback and throws an error if neither `rg` nor `git` is
  executable.** This system has both, so `<Leader>fg` works; if either binary were ever removed
  from `PATH`, that keymap would start erroring instead of degrading gracefully (unlike `files`/
  `grep`, which fall back to a slower pure-Lua implementation). Accepted — matches upstream's own
  documented trade-off ("for performance reasons"), not something this config works around.
- **No `mini.icons`/`nvim-web-devicons` dependency.** `mini.statusline`'s `section_fileinfo()` and
  `mini.pick`'s file-entry icons (`MiniPickIconFile`/`MiniPickIconDirectory`, already themed in the
  colorscheme) will show no icon glyph, text-only, until/unless `mini.icons` is added in a future
  change. Accepted as out of scope here.
- **Custom `content.active` duplicates a few lines of `mini.statusline`'s own default function**
  (the section-function calls and truncation widths). If a future `mini.nvim` update changes the
  default content function's structure (new section, reordered groups), this config's copy won't
  pick that up automatically and would need a manual re-sync. Accepted — the alternative (trying to
  wrap/patch the default function to inject one different section) would be more fragile than a
  plain, readable copy with one deliberate difference.

## Open Questions

None — the statusline diagnostics-coloring approach and the `mini.pick` keymap scheme were
reviewed and approved before writing this design.
