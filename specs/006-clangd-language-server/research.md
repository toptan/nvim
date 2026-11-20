# Research: clangd Language Server with Built-in Formatting

All findings were checked on this machine on 2026-11-20 with Neovim 0.12.6 and clangd /
clang-format 23.1.6 (Homebrew LLVM), using headless `nvim --clean` prototypes against a small
C++ project (git repository, `.clang-format`, compilation database in `build-debug/`).

## R1. Starting clangd

- **Decision**: a new `lsp/clangd.lua` with `cmd = { "clangd" }` and
  `filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }`. `config.lsp` maps each of those five
  filetypes to `clangd` and calls `vim.lsp.enable("clangd")` on the first such `FileType`
  event, the same lazy pattern as `lua_ls` and `neocmake`.
- **Rationale**: clangd needs no arguments; its defaults (background index, include insertion,
  `.clang-format` discovery) are what the spec asks for on the server side (FR-004a,
  clarification Q2). Neovim's default omni-completion applies the inserted `#include` (R8).
  Neovim's built-in detection maps `.h` to `cpp` unless `g:c_syntax_for_h` is set, and the
  prototype attached to both `.cpp` (`cpp`) and `.c` (`c`) buffers. The name `clangd` matches
  nvim-lspconfig, so `:checkhealth vim.lsp` and `:lsp` show the familiar name.
- **Alternatives considered**: passing flags such as `--background-index`,
  `--header-insertion=never` or `--fallback-style` (either already the default or against
  FR-004a / FR-006); `proto` filetype (out of scope per the spec); nvim-lspconfig (a plugin
  for one small table, Principle I).

## R2. Project root

- **Decision**: `root_markers = { { ".clangd", "compile_commands.json", "compile_flags.txt" },
  ".git" }`.
- **Rationale**: In 0.12 a nested list gives its markers equal priority, ahead of `.git`, so a
  sub-project with its own `.clangd` or compilation database becomes the root, and otherwise
  the repository does. The root only scopes the client (one clangd per root); clangd itself
  finds the compilation database per file (R3). With no marker (a lone file outside any
  repository) the prototype showed `root_dir == nil` and clangd attaching in single-file mode,
  so nothing else is scanned (spec edge case).
- **Alternatives considered**: `.git` first, as for neocmake (a monorepo with several C++
  sub-projects would then share one client whose root is wrong for each); a custom
  `root_dir` function (more code for no observed benefit).

## R3. Compilation database discovery (FR-004, clarification Q3)

- **Decision**: no `--compile-commands-dir` and no search logic. Rely on clangd's own lookup
  (file's directory and its parents, plus a `build/` subdirectory at each level). Projects
  with another build directory add a `.clangd` file
  (`CompileFlags: { CompilationDatabase: build-debug }`) or symlink `compile_commands.json`
  into the root; the README documents both.
- **Rationale**: Prototype: with the database only in `build-debug/`, clangd did not find it
  and reported errors for project headers. After adding the `.clangd` file above (no editor
  change, no restart flags) the same file showed 0 diagnostics (SC-004).
- **Alternatives considered**: globbing `build*/` and `cmake-build-*/` from the editor (rejected
  in clarification Q3).

## R4. Formatting through clangd (FR-005 – FR-008a, clarification Q1)

- **Decision**: no server-side changes; the existing `<leader>lf` LSP path
  (`vim.lsp.buf.format({ async = false, timeout_ms = 3000 })`) already handles clangd.
  Range formatting stays enabled, so Neovim's attach defaults set
  `formatexpr=v:lua.vim.lsp.formatexpr()` and `gq` formats through clangd.
- **Rationale**: Prototype results:
  - clangd advertises document, range and on-type formatting.
  - `<leader>lf`'s call produced output byte-for-byte identical to
    `clang-format --assume-filename=<file>` with a project `.clang-format`
    (`IndentWidth: 4`) — SC-002.
  - Formatting an already formatted, saved buffer left `changedtick` unchanged and the buffer
    `nomodified` — SC-003, FR-007. Neovim applies the server's text edits in one undo step.
  - `gq` over a range reformatted those lines via clangd (FR-008a).
  - On-type formatting is opt-in in 0.12 (`vim.lsp.on_type_formatting.enable()`) and is not
    enabled, so typing never reformats.
- **Alternatives considered**: running `clang-format` directly like gersemi (FR-008 forbids a
  second formatting path).

## R5. Missing server and failures (FR-011, FR-012)

- **Decision**: no extra code. If `clangd` is not on `PATH`, `vim.lsp.enable` stays silent and
  `:checkhealth vim.lsp` reports it, as for `lua_ls` and `neocmake`. `<leader>lf` then shows
  the existing `No language server can format this buffer`.
- **Rationale**: Matches features 003 and 005 and Principle IV.

## R6. Index cache location

- **Finding**: clangd's background index is written to `.cache/clangd/index/` next to the
  compilation database that was used (in the prototype, `build-debug/.cache/`), i.e. normally
  inside an already ignored build directory. With a database symlinked into the project root
  the cache lands in the root, and the project should ignore `.cache/`. The README mentions
  this in one sentence; no editor change.

## R7. Diagnostic source label

- **Finding**: clangd diagnostics carry `source` (`clang`, `clangd`, or `clang-tidy`), so the
  bordered popup from feature 004 names them. No change.

## R8. Applying completion extra edits (FR-004b)

- **Finding** (verified during implementation): clangd sends the `#include` as an extra edit
  (`additionalTextEdits`) on the completion item. In Neovim 0.12.6, completion invoked on
  request, including the default `vim.lsp.omnifunc` (`<C-x><C-o>`), registers the
  `CompleteDone` handler that applies these edits (`trigger()` calls `register_completedone`
  for `Invoked` requests in `$VIMRUNTIME/lua/vim/lsp/completion.lua`). It runs when an item
  is accepted with `<C-y>`. The same handler expands snippet items: Neovim advertises
  `snippetSupport`, so clangd sends function calls with argument placeholders, which
  `vim.snippet` expands and `<Tab>`/`<S-Tab>` jump between by default. Any `command` attached
  to the item is run as well. A `--clean` prototype with no `on_attach` inserted
  `#include <string>` and expanded `add(int a, int b)` as a snippet.
- **Decision**: no code. Neovim's default omni-completion already satisfies FR-004b for every
  server, so other file types behave as before.
- **Correction**: an earlier version of this section said only `vim.lsp.completion.enable()`
  registers the handler and planned an `on_attach` calling it. That missed the call in
  `trigger()`. The `on_attach` was removed as redundant.
