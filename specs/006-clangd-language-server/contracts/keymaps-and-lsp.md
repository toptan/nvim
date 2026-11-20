# Contract: clangd Server and Formatting

This contract extends `specs/005-cmake-language-server/contracts/keymaps-and-lsp.md` (and
through it 003). Everything there still holds unless it is changed below.

## Key mappings (no new ones, FR-010)

`<leader>lf` (`desc = "Format buffer"`) is unchanged. For C-family buffers it takes the
existing "any other" row:

| Buffer | Action | Messages (WARN, at most one) |
|--------|--------|------------------------------|
| read-only / not modifiable | nothing | `Buffer is read-only` |
| `c`, `cpp`, `objc`, `objcpp`, `cuda` with clangd attached | `vim.lsp.buf.format` → clangd, honouring `.clang-format` | none |
| same, clangd missing or not attached | nothing | `No language server can format this buffer` |

- No mapping is added on `LspAttach`.
- `gq` in C-family buffers uses Neovim's default `formatexpr` with an attached server, i.e.
  clangd range formatting (FR-008a).

## Server guarantees (`lsp/clangd.lua`)

- Starts only when the first C-family buffer appears, never at startup.
- Root: nearest directory with `.clangd`, `compile_commands.json` or `compile_flags.txt`,
  otherwise the git repository, otherwise single-file mode.
- Completion stays on request (`<C-x><C-o>`); accepting an item with `<C-y>` also applies its
  extra edits (e.g. `#include`) and expands argument placeholders (navigated with the default
  `<Tab>`/`<S-Tab>` snippet jumps). No auto-trigger and no mappings (FR-004b).
- Started without flags: clangd's own compilation-database discovery, background index,
  include insertion and fallback style apply.
- If `clangd` is not on `PATH`, nothing is shown while editing. `:checkhealth vim.lsp` reports
  it.
- Its diagnostics use the global display settings and toggles from `config.diagnostics`.
