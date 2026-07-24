## Context

`plugin/60-mini.lua` already configures `mini.files` with a shared `toggle_files(path)` helper and
two keymaps, `-` (anchored on the current file) and `<Leader>ed` (anchored on `vim.fn.getcwd()`).
`plugin/20-keymaps.lua` defines `Config.leader_group_clues`, including the `e` "+Explore/Edit"
group, which until now only had the one `<Leader>ed` leaf.

This config's own entry points are, in load order: `init.lua`, `plugin/10-options.lua`,
`plugin/20-keymaps.lua`, `plugin/30-autocmds.lua`, `plugin/40-lsp.lua`, `plugin/50-plugins.lua`,
`plugin/60-mini.lua`.

## Goals / Non-Goals

**Goals**
- One keymap to explore the config directory itself (as opposed to the project cwd), reusing
  `mini.files` and its existing toggle recipe.
- One keymap per config file to jump straight into editing it, keyed by the first letter of the
  file's name (ignoring the numeric `NN-` prefix used purely for load ordering).

**Non-Goals**
- No new `mini.clue` triggers — `<Leader>` is already a configured trigger, so the new leaves show
  up in the existing popup automatically.
- No keymap for `after/lsp/*.lua` files or other non-`plugin/`-root files — scope is limited to the
  eight files enumerated in `CLAUDE.md`'s load-order list.

## Decisions

### 1. `<Leader>ec` lives in `plugin/60-mini.lua`, not `plugin/20-keymaps.lua`

Matches the existing precedent for `-`/`<Leader>ed`: keymaps that call `mini.files`' API directly
live alongside its `setup()` call, per `CLAUDE.md`'s note that `20-keymaps.lua` is for keymaps "not
owned by a specific plugin/LSP feature." `<Leader>ec` reuses the *same* `toggle_files()` helper
already defined for `-`/`<Leader>ed` — no new helper needed, just:

```lua
vim.keymap.set("n", "<Leader>ec", function()
  toggle_files(vim.fn.stdpath("config"))
end, { desc = "Explore Neovim config directory" })
```

### 2. The seven file-edit keymaps use `vim.fn.stdpath("config")`, not a hardcoded path

```lua
local function edit_config_file(relative_path)
  return function()
    vim.cmd.edit(vim.fn.stdpath("config") .. "/" .. relative_path)
  end
end
```

`stdpath("config")` resolves to wherever Neovim actually loaded its config from (normally
`~/.config/nvim`, but respects `$NVIM_APPNAME`/XDG overrides), so the keymaps keep working under an
aliased or relocated config instead of assuming a fixed path.

### 3. Leaf-key choice: first letter of the name after the numeric prefix

`10-options.lua` → `o`, `20-keymaps.lua` → `k`, `30-autocmds.lua` → `a`, `40-lsp.lua` → `l`,
`50-plugins.lua` → `p`, `60-mini.lua` → `m`, and `init.lua` → `i`. The numeric prefixes exist only
to force Neovim's lexical load order (per `CLAUDE.md`); they carry no meaning for a mnemonic
keybinding, so they're stripped before picking the letter. All seven letters are distinct and none
collide with the existing `<Leader>ed` or the new `<Leader>ec`.

**Alternative considered**: key off the literal filename's first character (`1`, `2`, `3`, `4`,
`5`, `6`, `i`). Rejected — digit keys aren't mnemonic and `<Leader>e1` reads as a file index, not a
recognizable shorthand for "options" or "keymaps".

## Risks / Trade-offs

- **Eight new leaves crowd the `<Leader>e` popup.** Accepted — `mini.clue` already renders
  multi-leaf groups (e.g. `<Leader>f` has seven, `<Leader>g` has four); this is consistent with
  existing group sizes in this config.
- **If a config file is ever renamed such that two files share a first letter** (e.g. adding a
  second `l`-prefixed file), a future change will need to pick a different letter for one of them.
  Not mitigated here — out of scope until it actually happens.

## Open Questions

None — letter scheme and group placement were specified directly by the user.
