# Research: Auto-triggered LSP Completion with IDE-style Keys

All findings were verified against Neovim 0.12.6 with a headless prototype driven over RPC
(`--listen` / `--remote-send`), using lua_ls 3.x and clangd 23.1.6. The prototype lived in the
session scratchpad; nothing from it is committed.

## R1. Auto-trigger mechanism (FR-001, FR-005, clarification Q1)

- **Decision**: Neovim's built-in `'autocomplete'` option, set buffer-locally on `LspAttach`,
  with `'complete'` listing a function source that asks the language server, followed by the
  buffer sources.
- **Rationale**: `'autocomplete'` (new in 0.12, `:h ins-autocompletion`) opens the menu while
  typing word characters, refilters as you type, and uses a decaying time slice so slow sources
  never block typing (`'autocompletetimeout'`, with a longer budget for function sources such
  as LSP). The function source (`F` / `o` in `'complete'`) is designed for this; the
  prototype showed server items after `vim.ap` (lua_ls) and `std::str` (clangd) and narrowing
  on each further character. Requests are asynchronous: `vim.lsp.omnifunc` returns `-2` and
  later fills the menu with `complete()`, merging the items that other sources already
  produced.
- **Alternatives considered**:
  - `vim.lsp.completion.enable(…, { autotrigger = true })` with `triggerCharacters` extended
    to all identifier characters (`:h lsp-autocompletion`): robust for server items, but it
    only requests when the menu is closed, so it cannot be combined with buffer words shown by
    `'autocomplete'` (the menu is already open when the next character is typed). Rejected by
    clarification Q3 (buffer words wanted).
  - A completion plugin (blink.cmp, nvim-cmp, mini.completion): core covers the need
    (Principle I).

## R2. Sources, ordering and duplicates (FR-001a, clarification Q3)

- **Decision**: buffer-local `'complete'` = `F,.,w,b,u` with `'completefunc'` pointing at the
  module's source function (R3), and `vim.lsp.completion.enable(true, client_id, bufnr,
  { cmp = … })` for every attached client that supports completion. The comparator puts
  server items first, then orders each group by fuzzy score against the typed word
  (`matchfuzzypos()`, cached per word), then by `sortText` / word.
- **Rationale**: `'complete'` order alone is not kept: the LSP response is merged after the
  buffer words. `enable()` registers a per-buffer `cmp` that `vim.lsp.completion` applies to
  the merged list (`trigger()` in `$VIMRUNTIME/lua/vim/lsp/completion.lua`). Without the
  fuzzy tie-break the sort scrambled the server's ranking (`tbl_add_reverse_lookup` before
  `api` for `vim.ap`); with it, `api` came first. Server items have `dup = 1`, so when they
  sort first, a buffer word with the same text is dropped and the menu shows each word once.
  `t` (tags) is left out, matching "words from the open buffers"; tags stay available through
  `<C-x><C-]>`. `enable()` without `autotrigger` adds no autocommands beyond the
  `CompleteDone` handler that applies extra edits and snippets, and the documentation popup on
  `CompleteChanged`, both of which the default omnifunc path already uses (spec 006 R8).
- **Alternatives considered**: keeping `'complete'` stock plus `o` (adds tags, unloaded-buffer
  words are kept anyway); no comparator (buffer words first, duplicate entries).

## R3. Only word and trigger characters open the menu (US1-1, edge cases)

- **Decision**: the source function returns `-3` (cancel quietly) from its first call unless
  the character before the cursor is a word character; otherwise it delegates to
  `vim.lsp.omnifunc`. It is referenced as `v:lua.require'config.completion'.source`, so no
  global function is needed (verified). Trigger characters are handled separately (R7).
- **Rationale**: `'autocomplete'` also calls function sources on `InsertEnter`, after
  automatic indentation (`o` on an indented line) and after punctuation. With the omnifunc
  directly, clangd then returned 100 items for an empty word and a menu appeared on every new
  line. *(Implementation finding)*: lua_ls declares `" "`, `"\t"` and `"\n"` as trigger
  characters, so a guard that accepted any trigger character opened a menu after every space
  and on indented new lines; whitespace triggers are ignored.
- **Alternatives considered**: a minimum word length (rejected in clarification Q1);
  `'autocompletedelay'` (does not stop the empty-word call).

## R4. Moving without inserting (FR-003, FR-006, clarification Q2)

- **Decision**: insert-mode `<Tab>` / `<S-Tab>` expression mappings: with the menu visible
  they send `<Down>` / `<Up>`; else, when a snippet is active in that direction, they jump
  (`vim.snippet.jump`); else the key itself. `<C-n>` / `<C-p>` are not mapped.
- **Rationale**: `<Down>` / `<Up>` select "but don't insert" (`:h popupmenu-keys`, state 2).
  The prototype confirmed: after `<Tab>`, the line still showed only the typed text; typing
  `r` narrowed the list; `<Esc>` and `<C-e>` kept only the typed text. A `<C-n>` mapping is
  never reached while the menu is open: keys valid in CTRL-X mode are not mapped, and the
  prototype's `<C-n>` mapping still previewed the item. `'completeopt'` has no flag that stops
  `<C-n>` from inserting (`noinsert` only affects the initial state, verified). Hence the
  spec revision: `<C-n>` / `<C-p>` keep the stock preview. The snippet branch reproduces the
  default `<Tab>` / `<S-Tab>` mappings from `$VIMRUNTIME/lua/vim/_core/defaults.lua`, which a
  global insert-mode mapping replaces; select-mode defaults are untouched.
- **Alternatives considered**: `noinsert` in `'completeopt'` (does not affect `<C-n>`);
  `preinsert` (inserts more, not less).

## R5. Accepting with Enter (FR-007, FR-008)

- **Decision**: insert-mode `<CR>` expression mapping: menu visible and an item selected →
  `<C-y>`; menu visible and nothing selected → `<C-e><CR>`; otherwise `<CR>`.
- **Rationale**: `<C-y>` fires `CompleteDone`, so the existing handler applies extra edits and
  snippets. Verified: clangd `string_view` inserted `#include <string_view>`; `add` expanded to
  `add(int a, int b)` with `<Tab>` moving between the placeholders; lua `vim.api` accepted
  without a line break. With nothing selected, `apr<CR>` kept `apr` and opened a new line.
  `<CR>` is not a CTRL-X-mode key, so the mapping is reached while the menu is open.

## R6. Manual trigger `<C-Space>` / `<C-@>` (FR-010)

- **Decision**: one expression function mapped to both `<C-Space>` and `<C-@>`: nothing when
  the menu is visible or no attached client supports completion; `<C-n>` when a word is
  started before the cursor (combined menu: the `F` source passes the word-character guard);
  otherwise `vim.lsp.completion.get()` (server items only).
- **Rationale**: stock `<C-n>` runs the `'complete'` sources, including the server, but only
  when there is a word before the cursor; with nothing typed it never called the source
  (verified), so `get()` covers that case. Most terminals send `<C-@>` (NUL) for Ctrl+Space;
  mapping both covers GUIs and terminals. `get()` needs `enable()` for the buffer (R2), which
  is always the case when a capable client is attached.
- **Alternatives considered**: `<C-x><C-o>` (server only even with a word typed); `get()`
  always (no buffer words, against FR-001a).

## R7. Trigger characters (`.`, `->`, `::`)

- **Finding** (implementation): with `cindent`, typing `std:` dedents the line as if `std:`
  were a label and `::` re-indents it; a request sent during that answered `std::` with no
  items, at any typing speed (with `cinkeys-=:` it worked). The omnifunc also sends the
  request as "invoked", so clangd cannot tell a label's `:` from `::` and offered every global
  name after `case 1:`.
- **Decision**: a `TextChangedI` autocommand: when the text before the cursor ends with a
  non-whitespace trigger character, wait 25 ms (as `vim.lsp.completion`'s own autotrigger
  does), and if the buffer is unchanged and no menu is open, call `vim.lsp.completion.get()`
  with `triggerKind = TriggerCharacter` and the character. Verified: `std::` (slow and fast),
  `p.`, `q->` open the menu; `case 1:` does not. The earlier "accepted limitation" is void.
- **Alternatives considered**: removing `:` from `cinkeys` (changes indentation of labels and
  `case`/`public:`); triggering through the source function (always "invoked").

## R9. Incomplete server lists and menu order (implementation findings)

- **Incomplete lists**: `'autocomplete'` asks its sources once per menu and then only filters.
  clangd caps answers at 100 items and marks them incomplete, so `std::string_v` typed
  steadily showed `string_view_literals` but not `string_view`. **Decision**: a `TextChangedP`
  autocommand calls `vim.lsp.completion.get()` with `TriggerForIncompleteCompletions` after a
  word character; `vim.lsp.completion` sends nothing unless the last answer was incomplete.
  It runs only once server items are in the menu: earlier, it cancelled the first, still
  pending request and server items went missing when typing fast. Verified with both servers
  at 50–200 ms per key.
- **Order**: with `fuzzy` in `'completeopt'`, Neovim re-ranks the menu on every key by fuzzy
  score, mixing buffer words between server items. **Decision**: append `nosort` to the
  buffer-local `'completeopt'` in buffers with a server, so the comparator's order (R2) holds;
  the global value is unchanged.

## R8. Lifetime and scope

- **Decision**: a new module `lua/config/completion.lua`, required from `init.lua`. At load it
  creates the global insert-mode mappings and one `LspAttach`/`LspDetach` augroup
  (`config_completion`, `clear = true`). On `LspAttach` of a client that supports
  `textDocument/completion` it enables completion for that client and sets the buffer-local
  `'autocomplete'`, `'complete'`, `'completefunc'` and `'completeopt'` (R9). On `LspDetach`,
  when no other client with completion remains, it resets those four options to their global
  values, so a stopped server leaves a buffer with stock completion.
- **Rationale**: mappings must exist before any insert mode (cheap, no `require` of
  `vim.lsp`). Everything else happens only when a server attaches (Principle III). A module of
  its own keeps completion separate from server activation in `config.lsp` (Principle II).
  Buffers without a server keep stock completion (FR-002); the global mappings fall through to
  stock keys there because they act only when the menu is open, and `<C-Space>` checks for a
  client.
- **Startup**: the module only defines functions, five insert-mode mappings and one augroup
  with four autocommands, and does not load `vim.lsp`. Measured: 0.22 ms of an 8 ms headless
  startup.
