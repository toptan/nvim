# Data Model: Prominent Diagnostic Popup

No persisted data. The feature is three pieces of editor state, all set by configuration and
kept for the session.

## Popup border (global option)

| Field | Value | Notes |
|---|---|---|
| `'winborder'` | `"rounded"` | Default border for every float that does not set its own |

- Set once at startup by `config.options`.
- A float that passes `border` explicitly (including `"none"`) overrides it.

## Popup border colour (highlight group `FloatBorder`)

| Field | Source | Catppuccin dark | Catppuccin light |
|---|---|---|---|
| `fg` | `FloatTitle` fg (resolved) | `#89b4fa` | `#1e66f5` |
| `bg` | `NormalFloat` bg (resolved) | `#181825` | `#e6e9ef` |

- Recomputed on every `ColorScheme` event, including the dark/light reload.
- If `FloatTitle` has no `fg`, `FloatBorder` stays as the scheme defined it.

## Diagnostic popup style (`vim.diagnostic.config().float`)

| Field | Value | Requirement |
|---|---|---|
| `title` | `" Diagnostics "` | FR-004 |
| `header` | `""` | Avoids a duplicate in-body heading |
| `source` | `true` | FR-005 |
| border | inherited from `'winborder'` | FR-001 |
| entry colour | core `DiagnosticFloating<Severity>` | FR-006 |

- Applied once by `config.diagnostics.setup()` together with the initial display settings.
- The existing toggles (`<leader>td/tt/tl`) change other keys of the same config and leave
  `float` alone.
