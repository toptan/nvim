## Purpose

Defines the custom colorschemes shipped in `colors/` and their shared implementation in
`lua/retro/init.lua`, which layer modern highlight groups onto built-in Neovim colorschemes that
lack them.

## Requirements

### Requirement: Shared colorscheme module
The system SHALL implement all custom colorscheme highlight-group logic once, in
`lua/retro/init.lua`'s `M.load(opts)`, and have each `colors/<name>.lua` file be a thin wrapper
that calls it with `{ name, base, flavor }`. Highlight-group logic SHALL NOT be duplicated across
`colors/*.lua` files.

#### Scenario: Loading any of the custom colorschemes
- **WHEN** the user runs `:colorscheme <name>` for `retro`, `retroplus`, `defaultplus`,
  `habamaxplus`, or `lunapercheplus`
- **THEN** `lua/retro/init.lua`'s `M.load` runs with that scheme's `base` and `flavor`, first
  loading the built-in base colorscheme and then layering the additional highlight groups on top

### Requirement: Base colorscheme selection
The system SHALL derive each custom colorscheme from a specific built-in base colorscheme:
`retro` and `retroplus` from `retrobox`; `defaultplus` from `default`; `habamaxplus` from
`habamax`; `lunapercheplus` from `lunaperche`. The base colorscheme's own classic highlight
groups (set for the current `&background`) SHALL be preserved and only the missing groups added.

#### Scenario: Loading retroplus
- **WHEN** the user runs `:colorscheme retroplus`
- **THEN** the built-in `retrobox` colorscheme is loaded first, and its classic highlight groups
  remain in effect except where explicitly overridden

### Requirement: Tree-sitter capture flavor
The system SHALL support two Tree-sitter capture-mapping flavors: `"plus"`, which assigns
catppuccin-style semantic roles to captures (e.g. `@variable.builtin` -> red,
`@property` -> lavender, `@keyword.function` -> mauve) backed by the base theme's palette; and
`"classic"`, which links captures to the base theme's original classic groups (e.g.
`@type` -> `Type`, `@function` -> `Function`), preserving that theme's original look with no new
hues introduced. `retro` uses `"classic"`; `retroplus`, `defaultplus`, `habamaxplus`, and
`lunapercheplus` use `"plus"`.

#### Scenario: Comparing retro and retroplus on the same buffer
- **WHEN** the same Lua buffer is viewed first under `:colorscheme retro` and then under
  `:colorscheme retroplus`
- **THEN** under `retro`, syntax colors match plain `retrobox` (e.g. types yellow, keywords red,
  functions green), while under `retroplus`, additional catppuccin-style role colors appear
  (e.g. struct fields in lavender) not present in `retro`

### Requirement: Per-base, per-background palettes
The system SHALL define a palette of named color roles (catppuccin's role names: `rosewater`,
`red`, `green`, `blue`, `text`, `base`, etc.) for each base colorscheme, with separate values for
`dark` and `light` `&background` where the base theme itself supports both (habamax is dark-only
and SHALL share one palette for both keys). Palette values SHALL approximate the base theme's own
existing hues, not import catppuccin's colors directly.

#### Scenario: Switching background in a light/dark-aware base
- **WHEN** `&background` changes from `dark` to `light` while a `"plus"`-flavor colorscheme built
  on `default`, `retrobox`, or `lunaperche` is active
- **THEN** the colorscheme is reloaded and picks the `light` palette for that base, without
  requiring a config change

### Requirement: Additional UI/plugin highlight coverage
The system SHALL define highlight groups, beyond what the base colorscheme provides, for floating
windows, window separators/winbar, diff/health/quickfix/markdown extras, LSP diagnostics
(virtual text/lines/underline/floating/sign, per severity), LSP references and inlay hints, and
`mini.nvim` plugin groups (completion, files, pick, statusline, tabline, notify, diff, hipatterns,
etc.), for every custom colorscheme regardless of flavor.

#### Scenario: Opening a floating window (e.g. hover or diagnostics float)
- **WHEN** any custom colorscheme is active and a floating window is opened
- **THEN** `NormalFloat`, `FloatBorder`, and `FloatTitle` are styled per that colorscheme's
  palette, not left at the base colorscheme's defaults

#### Scenario: A diagnostic of a given severity appears
- **WHEN** a diagnostic of a given severity (error/warn/info/hint/ok) is shown as virtual text,
  underline, floating text, or a sign
- **THEN** it is colored consistently for that severity across all display modes, using colors
  derived from the active colorscheme's palette
