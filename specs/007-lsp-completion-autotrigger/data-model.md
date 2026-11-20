# Data Model: Auto-triggered LSP Completion with IDE-style Keys

This feature stores no data. Below is the runtime state `lua/config/completion.lua` owns.

## Buffer-local options (set on `LspAttach`, reset on last `LspDetach`)

| Option | Value while a completion-capable client is attached | Without one |
|--------|-------------------------------------------------------|-------------|
| `'autocomplete'` | `true` | global value (off) |
| `'complete'` | `F,.,w,b,u` | global value (`.,w,b,u,t`) |
| `'completefunc'` | `v:lua.require'config.completion'.source` | global value (empty) |
| `'completeopt'` | global value + `nosort` (research R9) | global value |

- "Completion-capable" means `client:supports_method("textDocument/completion", bufnr)`.
- Set once per buffer; attaching a second client does not change them again.
- Reset when the detaching client is the last completion-capable client of the buffer.

## Per-client completion registration

`vim.lsp.completion.enable(true, client_id, bufnr, { cmp = compare })` for every
completion-capable client on attach (no `autotrigger`). Neovim keeps one handle per buffer;
the first `enable()` stores `cmp`. Neovim's own `LspDetach` handler removes the client.

## Global options (unchanged, from `config.options`)

`'completeopt'` = `menuone,noselect,popup,fuzzy` (buffers with a server add `nosort`
locally). `'autocompletedelay'` and
`'autocompletetimeout'` stay at their defaults (0 and 80).

## Comparator `compare(a, b)` (FR-001a)

Input: two complete-items. Ordering keys, in turn:

1. Server item (`user_data.nvim.lsp` present) before buffer word.
2. Higher fuzzy score of `word` against the word before the cursor (`matchfuzzypos()`); an
   empty word scores every item equally. Scores are cached per word; the cache is dropped when
   the word before the cursor changes.
3. `user_data.nvim.lsp.completion_item.sortText` (server items), then `word`, ascending.

Server items carry a private `_fuzzy_score` from Neovim; it is deliberately not used (private
field, and buffer words lack it), so both groups are scored the same way.

Must be a strict weak order (Lua's `table.sort` errors on an inconsistent comparator).

## Source function `source(findstart, base)` (R3)

| Call | Condition | Result |
|------|-----------|--------|
| `findstart = 1` | character before cursor is a word character (`\k`) | `vim.lsp.omnifunc(1, base)` |
| `findstart = 1` | otherwise (start of line, after space or punctuation, on `InsertEnter`) | `-3` |
| `findstart = 0` | — | `vim.lsp.omnifunc(0, base)` |

## Autocommands (augroup `config_completion`)

| Event | Condition | Action |
|-------|-----------|--------|
| `LspAttach` | client supports completion | enable + buffer-local options above |
| `TextChangedI` | buffer has `'autocomplete'`; text before cursor ends with a non-whitespace trigger character | after 25 ms, if buffer unchanged, still insert mode and no menu: `vim.lsp.completion.get()` with `TriggerCharacter` and that character (research R7) |
| `TextChangedP` | buffer has `'autocomplete'`; word character before cursor; menu holds server items | `vim.lsp.completion.get()` with `TriggerForIncompleteCompletions` (research R9) |
| `LspDetach` | no other completion-capable client left | reset the buffer-local options |

Trigger characters are whatever the server declares, usually single characters (clangd: `.`,
`>`, `:`, …). Whitespace triggers (lua_ls: space, tab, new line) are ignored. Because the
request names the character, the server decides whether `>` or `:` alone means anything
(clangd: only as part of `->` / `::`); an empty answer shows no menu.

## Key handling state

None stored; every mapping decides from `pumvisible()`, `complete_info({ "selected" })`,
`vim.snippet.active()` and the text before the cursor at the time of the key press.
