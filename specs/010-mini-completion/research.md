# Research: Completion via mini.completion

All findings come from a throwaway prototype (isolated `XDG_*` dirs) on Neovim 0.12.6 with
`mini.completion` at `cdf8bdf`, lua_ls and clangd (Homebrew LLVM), driven headless and in tmux.

## R1. Which repository to install

- **Decision**: the standalone repository `https://github.com/nvim-mini/mini.completion`.
- **Rationale**: only the completion module is wanted (spec assumption); the standalone repo
  holds just `lua/mini/completion.lua` (~2,000 lines), docs and licence. Same pattern as
  `mini.notify` (009 R1).
- **Alternatives**: `nvim-mini/mini.nvim` (whole library) — rejected, pulls in unused modules.

## R2. Setup and defaults that become user-visible behaviour

- **Decision**: `require("mini.completion").setup()` with no arguments.
- **Rationale**: defaults already cover FR-001/FR-002 (verified in prototype):

| Aspect | Default (verified) |
|--------|--------------------|
| Trigger | On every keyword character, after 100 ms; immediately on a server trigger character (`.`, `->`, `::`, `:` …) |
| Sources | Two-stage: LSP items first; if none, fallback `<C-n>` (words from `'complete'` sources: buffers) |
| Buffers without a server | Fallback stage only: buffer words open automatically (matches clarification Q2 = A) |
| Incomplete server lists | Re-requested as the word grows (`TriggerForIncompleteCompletions`) — replaces feature 007's `TextChangedP` code |
| `std::` / `->` in C++ | Correct members after `::`, `->`, `.`; no cindent workaround needed |
| Info window | ` Info ` float beside the menu after 100 ms (`completionItem/resolve`), border from `'winborder'` (rounded) |
| Signature help | ` Signature ` float above the cursor while inside a call's arguments, after 50 ms |
| Filtering | Fuzzy, because `'completeopt'` contains `fuzzy` |
| Snippets | Items marked `S`; accepted with `<C-y>`, expanded by `vim.snippet.expand` (no snippet plugin) |
| Mappings | `<C-Space>` two-stage, `<A-Space>` fallback, `<C-f>` / `<C-b>` scroll info/signature |
| Enabled for | Every buffer (`completefunc` set on `BufEnter`); `vim.b.minicompletion_disable` turns off a buffer |

- **Alternatives**: `lsp_completion = { source_func = "omnifunc", auto_setup = false }` with an
  `LspAttach` hook — rejected, more code and no benefit for this config (no filetype omnifuncs
  in use).

## R3. Options the plugin touches, and which this config must change

`setup()` only sets `'completeopt'`, `'shortmess'` and `'complete'` if the user has not set
them. This config sets `'completeopt'` and `'shortmess'` in `config.options`, so the plugin
leaves them alone.

- **`'completeopt'` — Decision**: drop `popup` → `menuone,noselect,fuzzy`.
  **Rationale**: verified duplicate: for snippet items the plugin fills the item's `info`
  field, so the built-in `popup` preview opens beside the plugin's own Info window (stray
  `igned int val})` text next to ` Info `). Without `popup` only the plugin window shows. The
  remaining flags give FR-006 (nothing selected or inserted) and fuzzy narrowing.
- **`'shortmess'` — Decision**: append `c` in `config.options`.
  **Rationale**: the plugin's suggested value ("silent `<C-n>` fallback"); because this config
  already sets `'shortmess'` (`S`), the plugin skips adding it, so without it the fallback
  stage would echo "match 1 of N" / "Pattern not found" messages.
- **`'complete'`**: left at Neovim's default; the plugin removes `t` (tags) itself because
  `'complete'` is not set by this config.
- **Alternatives**: keep `popup` and disable the plugin's info window via a huge
  `delay.info` — rejected, loses resolved documentation and fights plugin defaults.

## R4. Key mappings (clarification Q1 = B)

- **Decision**:
  - `<Tab>` / `<S-Tab>`: unchanged expression mappings: menu open → `<Down>` / `<Up>`; active
    snippet → `vim.snippet.jump(±1)`; else the key itself.
  - `<CR>`: unchanged: item selected → `<C-y>`; menu open, nothing selected → `<C-e><CR>`;
    else `<CR>`.
  - `<C-Space>`: the plugin's own `force_twostep` mapping (default).
  - `<C-@>`: mapped by this config to `MiniCompletion.complete_twostage()`, because most
    terminals send Ctrl+Space as `<C-@>` and the plugin's `mappings` accepts one key per action.
- **Rationale**: verified in prototype: `<Down>` highlights without inserting and still fires
  the plugin's Info window (`CompleteChanged`); `<CR>` → `<C-y>` accepts and, for snippet
  items, the plugin's `CompleteDonePre` handler expands the snippet with the first placeholder
  selected; `<Tab>` then jumps. `<C-@>` on an empty line opens the menu.
- **Alternatives**: the plugin docs' `<C-n>` / `<C-p>` for `<Tab>` — rejected, inserts the item
  while moving (breaks FR-006 / User Story 2 scenario 1).

## R5. Loading: lazily on first `InsertEnter`

- **Decision**: a `once = true` `InsertEnter` autocommand (augroup `config_completion`) runs
  `vim.pack.add` (`confirm = false`) and `setup()` under `pcall`, then sets
  `'completefunc'` of the current buffer to `v:lua.MiniCompletion.completefunc_lsp` (its
  `BufEnter` already passed before the plugin's autocommand existed).
- **Rationale**: Principle III: completion is tied to Insert mode. Measured `--startuptime`
  on an empty buffer (5 runs): current config ~11.6 ms; eager plugin ~15.0 ms
  (`require('config.completion')` 1.9 ms vs 0.3 ms); lazy ~12.1 ms. Plugin `InsertCharPre`
  etc. autocommands are created inside the first `InsertEnter`, so the very first typed
  character already triggers completion (verified: `vim.ap` right after `o`).
- **Alternatives**: eager load (as `mini.notify`) — rejected, unlike notifications nothing
  needs completion before Insert mode; `vim.pack.add` with `load = false` plus `packadd` —
  same effect, more code.

## R6. Failure handling

- **Decision**: as 009 R5: `pcall` around `vim.pack.add` and around `require(...).setup()`; on
  failure one scheduled WARN `vim.notify` ("mini.completion unavailable: …"). `<C-@>` checks
  that the plugin loaded before calling it. `<Tab>` / `<S-Tab>` / `<CR>` do not depend on the
  plugin.
- **Rationale**: FR-009; built-in `<C-n>` / `<C-x><C-o>` remain usable. Notice appears on
  first Insert mode instead of at startup — still a single non-blocking notice.

## R7. LSP client capabilities

- **Decision**: do not pass `MiniCompletion.get_lsp_capabilities()` to `vim.lsp.config`.
- **Rationale**: servers start on `FileType`, before the plugin loads (R5); passing the
  capabilities would force loading it at startup. Neovim's default capabilities already
  advertise snippets and resolve of documentation: verified Info windows (lua_ls, clangd),
  snippet items and signature help work. Feature-level defaults are accepted (spec).
- **Alternatives**: copy the capability table into `lsp/*.lua` — rejected, duplicates plugin
  code (and would go stale).

## R8. Signature help interplay

- **Finding**: the plugin shows its ` Signature ` window automatically; the built-in
  `<C-s>` (Insert mode, manual) opens Neovim's larger signature float on top of it. Only on
  explicit request, so accepted; no automatic built-in signature help exists in this config, so
  there is never a second popup unless the user asks for one.

## R9. Code removed

All of `lua/config/completion.lua`'s custom logic (258 lines): fuzzy scoring and `compare`,
`completefunc` wrapper, `LspAttach` setup of `'autocomplete'` / `'complete'` /
`'completefunc'` / `nosort`, `TextChangedP` re-request, `TextChangedI` trigger-character
handling, `LspDetach` reset and the custom `<C-Space>` trigger. Kept: `<Tab>` / `<S-Tab>` /
`<CR>` mappings (Q1 = B).
