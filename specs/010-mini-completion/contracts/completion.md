# Contract: Completion (mini.completion)

Supersedes `specs/007-lsp-completion-autotrigger/` key and trigger behaviour.

## Automatic menu (Insert mode)

| Situation | Behaviour |
|-----------|-----------|
| Keyword character typed, then ~100 ms pause | Menu opens: server items; if none (or no server), words from open buffers |
| Server trigger character (`.`, `->`, `::` …) | Server asked at once with the trigger character; members shown |
| Menu open, typing continues | Fuzzy narrowing; server re-asked when its list was incomplete |
| Non-keyword character, menu closed | Nothing opens |
| Any buffer | Enabled (including buffers without a server); `vim.b.minicompletion_disable = true` turns a buffer off |

Nothing is selected or inserted until the user chooses (FR-006).

## Keys (Insert mode)

| Key | Menu open | Menu closed |
|-----|-----------|-------------|
| `<Tab>` | Next item, not inserted | Jump to next snippet placeholder if active, else `<Tab>` |
| `<S-Tab>` | Previous item, not inserted | Jump to previous placeholder if active, else `<S-Tab>` |
| `<CR>` | Item highlighted: accept (snippet expands). None: close menu + new line | New line |
| `<C-Space>` / `<C-@>` | Force completion (two-stage: server, then buffer words) | Same |
| `<A-Space>` | Force buffer-word completion (plugin default) | Same |
| `<C-f>` / `<C-b>` | Scroll Info / Signature window (plugin default) | Same, else built-in key |
| `<C-y>` / `<C-e>` / `<Up>` / `<Down>` / `<C-n>` / `<C-p>` | Built-in popup-menu keys | Built-in |

Every mapping defined by the config has a `desc`.

## Windows

| Window | When | Look |
|--------|------|------|
| Info | ~100 ms after an item is highlighted | Title ` Info `, `'winborder'` (rounded), ≤ 80×25 |
| Signature | ~50 ms after the cursor moves inside a call's arguments (server with signature help) | Title ` Signature `, `'winborder'`, active parameter highlighted |

Neither takes focus. The built-in `'completeopt'` `popup` preview is not used.

## Failure

If the plugin cannot be installed or loaded (first Insert mode): one WARN notification
"mini.completion unavailable: …"; `<Tab>` / `<S-Tab>` / `<CR>` still work; `<C-@>` does
nothing; built-in `<C-n>` / `<C-x><C-o>` completion remains.

## Configuration

- `lua/config/completion.lua`: installs the plugin with `vim.pack` and calls `setup()` with
  defaults on first `InsertEnter`; defines the four mappings above.
- `lua/config/options.lua`: `completeopt = menuone,noselect,fuzzy`; `shortmess += c`.
