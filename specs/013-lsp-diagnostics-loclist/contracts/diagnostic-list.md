# Contract: Diagnostic List Module and Key Mappings

Module: `lua/config/diagnostic_list.lua`, required from `init.lua` after
`config.diagnostics`. It exports nothing (`return` is not needed by other modules).

## Global key mappings (Normal mode)

| Keys | Action | `desc` |
|------|--------|--------|
| `<leader>ld` | fill the target window's location list with the target buffer's diagnostics, open and focus it | `Buffer diagnostics` |
| `<leader>lD` | request project-wide diagnostics from capable servers (wait ≤ 2 s), fill the target window's location list with all diagnostics, open and focus it | `Workspace diagnostics` |

Target window: the current window, or the owning file window when pressed inside a
location list window.

No diagnostics in scope → no list change, no window change, one
`vim.notify(..., INFO)`: `No diagnostics` / `No workspace diagnostics`.

## Buffer-local key mappings (location list windows only)

| Keys | Mode | Action | `desc` |
|------|------|--------|--------|
| `<Esc>` | n | `:lclose`, then focus the list's `filewinid` if valid | `Close location list` |

`<CR>` is the built-in location list behaviour (jump, focus file window, list stays open);
it is not remapped. Quickfix windows get no mappings.

## Autocommands (augroup `config_diagnostic_list`, `clear = true`)

| Event | Pattern | Action |
|-------|---------|--------|
| `FileType` | `qf` | if `win_gettype() == "loclist"`: set the buffer-local `<Esc>` |

## Decoration provider (namespace `config_diagnostic_list`)

Registered once, on the first key press. `on_win` accepts only windows whose buffer has
`buftype == "quickfix"` and whose location list id has a list record. `on_line` adds
ephemeral extmarks over the label and message ranges with the entry's `Diagnostic*`
group (see [data-model.md](../data-model.md)).

## Location list properties

| Property | Value |
|----------|-------|
| `title` | `Diagnostics` / `Workspace diagnostics` |
| action | reuse the current list if it is one of ours; else create an empty one with `" "` first. Items are then always set with `"r"` and the list `id`, after the list record is stored |
| `quickfixtextfunc` | per list; returns pre-computed display lines |

## Guarantees

- Nothing from `vim.diagnostic` or `vim.lsp` is loaded at startup.
- No errors are raised for: no LSP client, diagnostics disabled, deleted files, a target
  window closed meanwhile.
- The global `<Esc>` (search highlight) and quickfix windows are unaffected.
