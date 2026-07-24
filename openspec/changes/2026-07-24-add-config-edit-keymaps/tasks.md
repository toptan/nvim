## 1. Add config-directory explorer keymap

- [x] 1.1 In `plugin/60-mini.lua`, add `<Leader>ec` keymap: `toggle_files(vim.fn.stdpath("config"))`
      (reuses the existing `toggle_files()` helper, placed right after `<Leader>ed`)

## 2. Add config-file quick-edit keymaps

- [x] 2.1 In `plugin/20-keymaps.lua`, add an `edit_config_file(relative_path)` helper returning a
      closure that calls `vim.cmd.edit(vim.fn.stdpath("config") .. "/" .. relative_path)`
- [x] 2.2 Add `<Leader>ei` → `init.lua`
- [x] 2.3 Add `<Leader>eo` → `plugin/10-options.lua`
- [x] 2.4 Add `<Leader>ek` → `plugin/20-keymaps.lua`
- [x] 2.5 Add `<Leader>ea` → `plugin/30-autocmds.lua`
- [x] 2.6 Add `<Leader>el` → `plugin/40-lsp.lua`
- [x] 2.7 Add `<Leader>ep` → `plugin/50-plugins.lua`
- [x] 2.8 Add `<Leader>em` → `plugin/60-mini.lua`

## 3. Manual verification

Not run in this PR's authoring environment (no local `nvim`/Neovim runtime available there) —
left for the reviewer to check locally before merging.

- [ ] 3.1 `nvim --headless -c 'qa'` reports no startup errors after all eight new keymaps are added
- [ ] 3.2 Pressing `<Leader>ec` with the explorer closed opens `mini.files` rooted at
      `vim.fn.stdpath("config")`; pressing it again closes it
- [ ] 3.3 Pressing each of `<Leader>ei`/`eo`/`ek`/`ea`/`el`/`ep`/`em` opens the corresponding file
      in the current window
- [ ] 3.4 The `<Leader>` popup (`mini.clue`) shows all eight `e`-group leaves with their `desc`
      text, under the existing "+Explore/Edit" label

## 4. Docs

- [x] 4.1 Update `CLAUDE.md`'s load-order section: mention the new quick-edit keymaps under the
      `plugin/20-keymaps.lua` bullet, and the new `<Leader>ec` toggle under the `plugin/60-mini.lua`
      bullet
