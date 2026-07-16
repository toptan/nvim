# text-objects Specification

## Purpose
TBD - created by archiving change add-mini-ai-surround-bufremove-notify-trailspace. Update Purpose after archive.

## Requirements

### Requirement: mini.ai default textobjects

The system SHALL provide `a`/`i` prefixed textobjects (brackets, quotes, tag, argument, and the
rest of `mini.ai`'s built-in set) via `mini.ai` (part of `mini.nvim`, configured in
`plugin/60-mini.lua`) with its default mappings: `a`/`i` main prefixes, `an`/`in`/`al`/`il`
next/last variants, `g[`/`g]` goto-edge. These next/last mappings intentionally override Neovim's
built-in incremental-selection mappings of the same name.

#### Scenario: Operating on a bracket/quote/tag/argument textobject

- **WHEN** the user types an operator followed by `a` or `i` and a supported textobject identifier
  (e.g. `di"`, `va)`, `cit`, `daa`) in normal or visual mode
- **THEN** the operator applies to the around/inside region of that textobject

#### Scenario: Next/last textobject variants override built-in incremental selection

- **WHEN** the user types `an`, `in`, `al`, or `il` (optionally preceded by an operator) in normal
  or visual mode
- **THEN** `mini.ai`'s next/last textobject behavior runs instead of Neovim's built-in
  incremental-selection mapping of the same name

### Requirement: Treesitter-based function and class textobjects

The system SHALL provide `f` (function) and `c` (class) textobject identifiers, usable as `af`,
`if`, `ac`, `ic`, backed by `mini.ai`'s `gen_spec.treesitter()` reading the `@function.outer` /
`@function.inner` / `@class.outer` / `@class.inner` captures from the current buffer's
`textobjects.scm` treesitter query (as bundled by the `nvim-treesitter-textobjects` plugin
dependency for languages it covers).

#### Scenario: Operating on a function textobject

- **WHEN** the buffer's language has a `textobjects.scm` query defining `@function.outer`/
  `@function.inner`, the cursor is inside a function, and the user types an operator followed by
  `af` or `if` (e.g. `daf`, `vif`)
- **THEN** the operator applies to the whole function (`af`) or its body (`if`)

#### Scenario: Operating on a class textobject

- **WHEN** the buffer's language has a `textobjects.scm` query defining `@class.outer`/
  `@class.inner`, the cursor is inside a class, and the user types an operator followed by `ac` or
  `ic`
- **THEN** the operator applies to the whole class (`ac`) or its body (`ic`)

#### Scenario: No treesitter query available for the buffer's language

- **WHEN** the buffer's language has no `textobjects.scm` query defining function/class captures
  and the user types `af`, `if`, `ac`, or `ic`
- **THEN** no match is found and no error is raised, consistent with `mini.ai`'s normal
  not-found behavior
