# Contract: Insert-mode Completion Keys and Automatic Menu

This contract supersedes the completion parts of
`specs/006-clangd-language-server/contracts/keymaps-and-lsp.md` ("Completion stays on request
… No auto-trigger and no mappings"). Everything else there still holds.

## Key mappings (insert mode only, global)

| Key | Menu visible, item selected | Menu visible, nothing selected | Menu closed |
|-----|-----------------------------|--------------------------------|-------------|
| `<Tab>` | next item, no insert (`<Down>`) | first item, no insert | snippet active → jump forward; else `<Tab>` |
| `<S-Tab>` | previous item, no insert (`<Up>`) | last item, no insert | snippet active → jump back; else `<S-Tab>` |
| `<CR>` | accept (`<C-y>`: extra edits, snippet) | close menu, line break | `<CR>` |
| `<C-Space>`, `<C-@>` | nothing | nothing | no completion client → nothing; word before cursor → combined menu; else server-only menu |

| Key | `desc` |
|-----|--------|
| `<Tab>` | `Next completion item, snippet jump or Tab` |
| `<S-Tab>` | `Previous completion item, snippet jump or S-Tab` |
| `<CR>` | `Accept selected completion item or new line` |
| `<C-Space>` / `<C-@>` | `Trigger completion` |

- Select-mode `<Tab>` / `<S-Tab>` (snippet jumps) keep Neovim's defaults.
- Normal-mode `<Tab>` / `<S-Tab>` (buffer switching, `config.keymaps`) are unchanged.
- Not mapped, stock behaviour: `<C-n>`, `<C-p>`, `<Up>`, `<Down>`, `<C-y>`, `<C-e>`,
  `<C-x><C-o>`, `<Esc>`. `<C-n>` / `<C-p>` preview the item in the buffer as stock.
- The stock `<C-@>` (insert previous text and stop insert) is replaced.

## Automatic menu (buffers with a completion-capable client)

- Opens after typing a word character or a server trigger character; not on entering insert
  mode, a new line, or whitespace.
- Lists server items first, then words from loaded/listed buffers, each group by fuzzy match
  quality; a buffer word equal to a server item is not repeated.
- Nothing is selected when it opens; narrowing uses the existing fuzzy matching.
- Never blocks typing; no message is shown when a server is slow, fails or stops.
- Buffers without such a client, including after the last one stops: no automatic menu,
  stock completion.

## Messages

None. No key in this contract produces a message in any state.
