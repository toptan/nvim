# Data Model: Bash Language Server

The feature adds configuration data only; no state beyond what the existing modules keep.

## Filetype → server map (`lua/config/lsp.lua`, `servers`)

| Key (filetype) | Value (server) | Change |
|----------------|----------------|--------|
| `sh`           | `bashls`       | NEW    |
| `bash`         | `bashls`       | NEW    |
| existing keys  | unchanged      | —      |

The existing `enabled` set is keyed by server name, so `vim.lsp.enable("bashls")` runs once
however many `sh`/`bash` buffers trigger it.

## Server config (`lsp/bashls.lua`)

| Field          | Value                                  | Source |
|----------------|----------------------------------------|--------|
| `cmd`          | `{ "bash-language-server", "start", }` | R1     |
| `filetypes`    | `{ "bash", "sh", }`                    | R2     |
| `root_markers` | `{ ".git", }`                          | R1     |
| `on_init`      | if `shfmt` is not executable: `server_capabilities.documentFormattingProvider = false` | R4 |

No `settings`: server defaults apply (ShellCheck on `PATH`, shfmt on `PATH`, `.editorconfig`
honoured, background analysis limits).

## Tree-sitter tables (`lua/config/treesitter.lua`)

| Table       | Entry           | Change |
|-------------|-----------------|--------|
| `LANGUAGES` | `"bash"` (kept in alphabetical order, after `"asm"`) | NEW |
| `FILETYPES` | `bash = "bash"`, `sh = "bash"` (directly after `asm = "asm"`) | NEW |

## `<leader>lf` dispatch (dispatch unchanged; no-op edits are undone, research R3)

| Buffer state | Result |
|--------------|--------|
| read-only / not modifiable | WARN `Buffer is read-only` |
| `sh`/`bash`, bashls attached, shfmt on `PATH` | whole buffer formatted via bashls → shfmt |
| `sh`/`bash`, shfmt missing (capability off) or server not attached | WARN `No language server can format this buffer` |
