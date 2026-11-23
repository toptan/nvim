# Research: Tree-sitter Parsers and Syntax-Aware Text Objects

All findings were checked against nvim-treesitter `main` (52773f0, 2026-11-21),
nvim-treesitter-textobjects `main` (5c7b026, 2026-09-03), Neovim 0.12.6 and tree-sitter CLI
0.27.0. A throwaway prototype ran in isolated XDG directories in the scratchpad, never in the
real config or data directories.

## R1. Plugin branch and versions

- **Decision**: Use the default branch (`main`) of both plugins by passing no `version` in the
  `vim.pack` specs.
- **Rationale**: `main` is the rewrite for Neovim 0.12+. The old `master` branch is frozen and
  meant for Neovim 0.11. The textobjects `main` branch pairs with nvim-treesitter `main`.
  The lockfile (machine-local) pins the revisions actually installed.
- **Alternatives**: `master` branches (incompatible API, frozen); tagged releases (neither repo
  tags `main` releases regularly).

## R2. What each plugin adds over core (Principle I justification)

- **nvim-treesitter**: downloads, builds and updates parsers (`install`, `update`), and ships
  the matching queries (highlights, folds, injections, indents) plus an indent expression.
  Core Neovim bundles only a few parsers, has no installer, and has no tree-sitter indentation.
- **nvim-treesitter-textobjects**: text-object and move functions driven by `textobjects.scm`
  queries. Core has no syntax-aware text objects or function/class jumps.
- Highlighting (`vim.treesitter.start`), folding (`vim.treesitter.foldexpr`) and injections are
  core features, so they are used directly. The plugin is only the source of parsers and
  queries for them.

## R3. Loading strategy (Principle III)

- **Decision**: `vim.pack.add` runs at startup with `load = function() end`, so the plugins
  are registered (and installed on a fresh machine) but nothing is added to `runtimepath` and
  no plugin code runs. The first `FileType` event for a supported filetype runs
  `:packadd nvim-treesitter` and `:packadd nvim-treesitter-textobjects` once.
- **Rationale**: Measured cost of `vim.pack.add` for both plugins with a no-op loader: 1.5–3 ms
  at startup. The plugin's README says it "does not support lazy-loading". The reason is that
  `plugin/` registers extra filetype→language mappings and the `:TS*` commands. None of the 12
  languages needs those mappings: each language name equals its Neovim filetype, and core
  maps `help` to `vimdoc`. So late loading is safe for this language list. Parsers and queries
  live in `stdpath("data")/site`, which is on `runtimepath` by default. So highlighting and
  folding work with installed parsers even before the plugin is loaded.
- **Alternatives**: eager `load = true` (sources the plugin files on every start, including an
  empty buffer, against FR-002); deferring `vim.pack.add` itself to the first `FileType`
  (a first-time plugin install would then block opening the first file, and
  `PackChanged` hooks would miss installs).
- **Load check**: `:packadd` of a package that is not on disk raises no error (verified), so
  after `:packadd` the module checks that `lua/<plugin>/init.lua` is on `runtimepath` before
  treating the plugins as loaded. Without the plugins, the installed nvim-treesitter queries
  still work for highlighting and folding, but the indent expression and the mappings are
  not set.
- **Consequence**: `:TSInstall`/`:TSUpdate` exist only after the first supported file has been
  opened in a session. That is accepted. Automatic install and update cover the spec.

## R4. Plugin install without confirmation (Principle IV)

- **Decision**: `vim.pack.add(..., { confirm = false })`.
- **Rationale**: The default asks for confirmation before the first install. That is a manual
  step on a fresh clone and blocks `nvim --headless "+qa"`. Verified: with `confirm = false`
  the headless start installs both plugins and exits, printing only vim.pack's progress.

## R5. Parser installation trigger and completion

- **Decision**: On the first supported `FileType` of a session, call
  `require("nvim-treesitter").install(LANGUAGES)` once. It returns an async task. Its
  `:await(cb)` callback (run through `vim.schedule`) attaches every buffer still pending.
- **Rationale**: `install` skips installed parsers, and with several languages and no
  `summary` option it is silent when nothing needs installing. `cpp` pulls in `c` and
  `markdown` pulls in `markdown_inline` as dependencies (already in the list). Measured: all
  12 parsers built in 4.2 s. A buffer whose `vim.treesitter.start` failed before installation
  succeeds afterwards in the same session (verified with `cpp`: no failure caching).
- **Concurrency**: one install task per session (module flag). An update requested while
  `install == "running"` is not started; it stays in `update_pending` and runs from the
  install's completion callback. So install and update never overlap, and the plugin's
  per-language lock (`installing[lang]`) is only a second safeguard.
- **Alternatives**: install at startup (rejected in clarification); install only the opened
  file's language (spec requires all missing ones).

## R6. Update on plugin change

- **Decision**: A `PackChanged` autocommand, created before `vim.pack.add`, reacts to
  `kind == "install"` or `"update"` for either plugin. It sets the
  `update_pending` flag. If the plugins are already loaded in this session (and no install is
  running), one `vim.schedule`d run of `require("nvim-treesitter").update(LANGUAGES)`
  follows. Otherwise the update waits until the first supported `FileType` loads the
  plugins, and runs there after the install task. This keeps plugin code off startup,
  including the first start of a fresh clone, when `vim.pack.add` itself fires
  `PackChanged` (`install`). `delete` is ignored.
- **Rationale**: `vim.pack.update` can change both plugins in one go. The pending flag
  collapses those events into one update per change batch (SC-003). `update` only rebuilds
  parsers whose pinned revision changed, and reloads the parser table first, so it uses the
  new revisions. With no parsers installed (first plugin install) it is a silent no-op, so
  the deferred update after a fresh clone costs nothing.
- **Alternatives**: `:TSUpdate` command (prints a summary line not requested; needs `plugin/`
  sourced); updating every start (wasteful, against US2-3).

## R7. Messages

- nvim-treesitter's logger echoes `[nvim-treesitter/install/<lang>]: Installing parser` and
  `... Language installed` for each parser (two lines, not one). Errors use `ErrorMsg`. These
  are the "default progress output" chosen in clarification. Spec wording was corrected to
  "progress lines per parser". The config passes no `summary` option and adds no messages.
- Each message is a separate `nvim_echo` from a scheduled callback. Single-line messages do
  not trigger a hit-enter prompt. A multi-line build error (compiler stderr) can, which is the
  plugin's own behaviour and accepted under FR-012 (no suppressing or reformatting).
- **Tool pre-check (Principle IV)**: before `install()`/`update()` the module checks
  `vim.fn.executable()` for `tree-sitter`, `curl`, `tar` and at least one of `$CC`, `cc`,
  `gcc`, `clang`. If any is missing, it skips the call and shows one
  `vim.notify(..., vim.log.levels.WARN)` per session ("Tree-sitter parsers not installed,
  missing: tree-sitter, cc"). Without this, the plugin would print an error per parser in
  every session, because missing parsers are retried on every start. Failures that occur
  with all tools present (network, compile errors) remain the plugin's own output.

## R8. Feature activation per language

- **Highlighting**: `vim.treesitter.start(buf, lang)` in `pcall`. Core ftplugins for `lua`,
  `markdown` and `help` already call it. Calling it again is harmless.
- **Folding**: only when the language has a `folds` query
  (`#vim.treesitter.query.get_files(lang, "folds") > 0`). Then set window-local (`vim.wo[win][0]`)
  `foldmethod=expr`, `foldexpr=v:lua.vim.treesitter.foldexpr()`, `foldlevel=99` in every
  window showing the buffer. `foldlevel=99` makes files open unfolded. The spec assumption
  "window's default fold level" was wrong: the default 0 closes all folds. The spec now says
  "files open with all folds open", which this satisfies.
- **Indentation**: only when the language has an `indents` query; then
  `indentexpr=v:lua.require'nvim-treesitter'.indentexpr()`. Verified that built-in indent
  scripts run before the config's `FileType` handler does not apply and the value persists;
  for C, a non-empty `indentexpr` overrides `cindent`.
- **Text objects and jumps**: only when the language has a `textobjects` query.

Query availability found in the plugins (determines behaviour, nothing hard-coded):

| Language | folds | indents | textobjects |
|----------|-------|---------|-------------|
| asm | – | – | – |
| c, cpp, cmake, lua, python | ✓ | ✓ | ✓ |
| markdown | ✓ | ✓ | ✓ (class = section) |
| editorconfig | ✓ | – | – |
| vim | ✓ | – | ✓ |
| vimdoc (`help`) | – | – | – |

Where a query is missing, Neovim's built-in behaviour stays (spec edge case: fall back to the
editor's built-in indentation). `cmake` has no class captures and `lua`/`vim` have none
either, so `ac`/`ic`/`]c`/`[c` select or move nowhere there. They are silent no-ops (verified:
a jump with no target leaves the cursor and raises no error).

## R9. Text objects and jumps

- **Decision**: Buffer-local mappings calling
  `require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")`
  (modes `x`, `o`) and `require("nvim-treesitter-textobjects.move").goto_next_start` /
  `goto_previous_start` (modes `n`, `x`, `o`). Default plugin config: `lookahead = false`
  (nothing selected when the cursor is not inside the construct, US3-3), `set_jumps = true`
  (jump list, FR-010a). `move` honours `v:count1`. No `setup()` call needed.
- **`]c`/`[c` in diff mode**: expression mappings return `"]c"`/`"[c"` (non-recursive, so
  the built-in diff jump runs) when `vim.wo.diff` is set, otherwise a `<Cmd>` call to the
  class jump. Verified: `2]c` in a diff window lands on the second change (count kept). After
  `:diffoff` the same key does the class jump without reopening the file.
- **Detaching**: if a buffer's filetype changes to an unsupported one, the mappings are
  removed, tree-sitter is stopped and the fold options are reset (FR-006/FR-010b, FR-009).
  Verified: a new filetype with an indent script (`json`) replaces `indentexpr`, but one
  without (`text`) keeps the tree-sitter expression. So detach also resets `indentexpr` to
  the global value, but only when it still holds the tree-sitter expression.

## R10. Filetype → language map

`asm, c, cmake, cpp, editorconfig, lua, markdown, python, vim` map to the language of the same
name, and `help` maps to `vimdoc`. `markdown_inline` and `regex` have no filetype
(injection only). `checkhealth` buffers, which core also maps to `vimdoc`, are not in scope.
Note: Neovim detects `*.h` as `cpp` by default, so headers use the C++ parser.

## R11. External tools

nvim-treesitter `main` requires `tar`, `curl`, `tree-sitter` CLI ≥ 0.26.1 (not the npm
package) and a C compiler. `git` is already required by `vim.pack`. All are reported by
`:checkhealth nvim-treesitter` once the plugin is loaded. The README lists them.
