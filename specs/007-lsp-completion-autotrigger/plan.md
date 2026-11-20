# Implementation Plan: Auto-triggered LSP Completion with IDE-style Keys

**Branch**: `master` (no feature branch) | **Date**: 2026-11-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-lsp-completion-autotrigger/spec.md`

## Summary

Turn on Neovim 0.12's built-in `'autocomplete'` in buffers with a completion-capable language
server. The buffer's `'complete'` asks the server first (a small guarded wrapper around
`vim.lsp.omnifunc`), then buffer words. A comparator registered through
`vim.lsp.completion.enable()` lists server items first, ordered by fuzzy score. Insert-mode
`<Tab>` / `<S-Tab>` move through the menu without inserting (`<Down>` / `<Up>`) and fall back
to snippet jumps or a literal Tab. `<CR>` accepts a selected item (`<C-y>`) or inserts a line
break. `<C-Space>` / `<C-@>` trigger completion manually. No plugin is added. The prototype
showed `<C-n>` / `<C-p>` cannot lose their in-buffer preview, so the spec was revised
(research R4).

## Technical Context

**Language/Version**: Lua (LuaJIT) on Neovim 0.12 (verified on 0.12.6)

**Primary Dependencies**: built-in `'autocomplete'`, `'complete'` function sources,
`vim.lsp.completion`, `vim.snippet`. External: language servers already configured (lua_ls,
neocmake, clangd), all optional.

**Storage**: N/A

**Testing**: manual and RPC-driven headless checks per [quickstart.md](quickstart.md);
`nvim --headless "+qa"`; `--startuptime`; `:checkhealth`; lua_ls diagnostics on changed files

**Target Platform**: macOS (primary), Linux; no platform-specific code

**Project Type**: personal Neovim configuration

**Performance Goals**: no visible typing delay (built-in time-sliced sources, asynchronous LSP
requests); no measurable startup cost

**Constraints**: startup < 100 ms; no messages; 80-column Lua style from `.editorconfig`; no
global Lua functions (source referenced via `v:lua.require'…'`)

**Scale/Scope**: one new module (~100 lines), one line in `init.lua`, README updates

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Native-First | Built-in `'autocomplete'`, `'complete'` `F` source, `vim.lsp.completion`, `vim.snippet`; no nvim-cmp / blink.cmp / mini.completion (research R1) | ✅ |
| II. Modular Lua | New single-concern module `config.completion`; `init.lua` only gains a `require`; one augroup `config_completion` with `clear = true`; no globals | ✅ |
| III. Fast, Deferred Startup | Only key mappings and an autocommand are created at startup; options and `vim.lsp.completion` are touched on `LspAttach` | ✅ |
| IV. Reproducible & Fault-Tolerant | Without servers nothing changes and nothing is shown; mapping fallbacks always produce the stock key | ✅ |
| V. Consistent Style | Every mapping has a `desc`; `.editorconfig` style; lua_ls-clean | ✅ |
| Workflow | Workflow change → Spec Kit flow; small focused commits | ✅ |

**Post-design re-check**: still passes. Five insert-mode mappings (`<C-@>` shares `<C-Space>`'s function)
replace stock or default behaviour only in the documented states (contract).
The insert-mode `<Tab>` / `<S-Tab>` replace Neovim's default snippet-jump mappings in insert
mode and re-implement them (research R4). This is a deliberate overlap, not a violation.

## Project Structure

### Documentation (this feature)

```text
specs/007-lsp-completion-autotrigger/
├── plan.md              # This file
├── research.md          # Phase 0: prototype findings and decisions
├── data-model.md        # Phase 1: buffer options, comparator, source function
├── quickstart.md        # Phase 1: validation scenarios
├── contracts/
│   └── keymaps-and-completion.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 (/speckit-tasks)
```

### Source Code (repository root)

```text
init.lua                 # CHANGED: require("config.completion") after config.lsp
lua/config/
├── completion.lua       # NEW: mappings, LspAttach/LspDetach, source, comparator
├── lsp.lua              # unchanged
└── options.lua          # unchanged ('completeopt' stays)
README.md                # CHANGED: completion keys, C/C++ completion note
```

**Structure Decision**: Completion behaviour is its own concern, separate from server
activation (`config.lsp`) and editor options (`config.options`), so it gets one module in
`lua/config/`, like `config.search` and `config.diagnostics`.

## Implementation Notes

1. **`lua/config/completion.lua`** exports `M.source` (for `'completefunc'`) and sets up on
   load:
   - `compare(a, b)` per [data-model.md](data-model.md) (server first, fuzzy score, then
     `sortText` / word).
   - `M.source(findstart, base)`: the word/trigger-character guard (research R3), then
     `vim.lsp.omnifunc`.
   - `LspAttach` (augroup `config_completion`): skip clients without
     `textDocument/completion`; `vim.lsp.completion.enable(true, client.id, buf,
     { cmp = compare })`; set `vim.bo[buf].autocomplete`, `.complete`, `.completefunc`.
   - `LspDetach`: if no other completion-capable client remains on the buffer, reset the three
     options to their global values (`vim.bo[buf][name] = vim.go[name]`, or `:setlocal
     name<`). Neovim detaches its own completion handler.
   - Insert-mode expression mappings per the [contract](contracts/keymaps-and-completion.md):
     `<Tab>`, `<S-Tab>`, `<CR>`, and one function for `<C-Space>` and `<C-@>`. Snippet branch:
     `vim.snippet.active({ direction = d })` → `<Cmd>lua vim.snippet.jump(d)<CR>`. The `<CR>`
     mapping must not use `replace_keycodes = false`.
2. **`init.lua`**: `require("config.completion")` after `require("config.lsp")`.
3. **README**: a "Completion" section describing the automatic menu, the key table, that
   default keys still work (with the `<C-n>` / `<C-p>` preview note), and `<C-Space>` /
   `<C-@>`; update the C/C++ paragraph (`<C-x><C-o>` → automatic; accept with `<CR>` or
   `<C-y>`).
4. Verify R7 (`std::` after a label-like dedent) in a real terminal UI; if it reproduces, keep
   the spec's edge-case note, otherwise drop it. *(Done: fixed by the trigger-character
   request, research R7; the edge-case note was removed.)*
5. *(Added during implementation, research R7 and R9)*: a `TextChangedI` autocommand asks the
   server after a trigger character, a `TextChangedP` autocommand refreshes incomplete server
   lists, and buffers with a server add `nosort` to their local `'completeopt'`; see
   [data-model.md](data-model.md) Autocommands.

## Complexity Tracking

No constitution violations; nothing to justify.
