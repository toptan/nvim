# Research: Prominent Diagnostic Popup

All findings verified on 2026-11-20 against Neovim 0.12.6 with this config loaded headless
(`nvim --headless -u init.lua`), colour scheme `catppuccin` (bundled with Neovim).

## R1 — One border for every popup (FR-001, FR-002, FR-010)

- **Decision**: Set the global option `winborder = "rounded"` in `config.options`.
- **Rationale**:
  - Since 0.11, `'winborder'` is the default border for every floating window opened without an
    explicit `border`. That covers the diagnostic popup (`vim.diagnostic.open_float`), hover and
    signature help (`vim.lsp.util.open_floating_preview`), and plugin floats.
  - Verified: the diagnostic and hover popups both got `╭─╮│╯─╰│`. A float opened with
    `border = "none"` kept `"none"`, so plugins that choose their own border keep it (spec
    edge case).
  - The rounded set uses box-drawing characters from basic Unicode, so no Nerd Font is needed
    (FR-002; `vim.g.have_nerd_font = false`).
  - The completion menu (`pum`) is not a floating window and is unaffected.
  - Setting an option has no measurable startup cost (Principle III).
- **Alternatives considered**:
  - `vim.diagnostic.config({ float = { border = "rounded" } })` only: rejected because it
    styles only diagnostics, and the clarification asks for every popup.
  - Wrapping `vim.lsp.util.open_floating_preview`: rejected as a fragile monkey-patch that
    `'winborder'` makes unnecessary.
  - `"single"` / `"double"` / `"solid"`: any would meet FR-001. `"rounded"` is the spec's
    default and the most common choice. `"solid"` has no visible line and depends entirely on a
    background contrast that the scheme does not provide (R2).

## R2 — Border colour must actually be visible (FR-003, SC-002)

- **Finding**: The bundled catppuccin links `FloatBorder` → `WinSeparator`, which is nearly
  invisible:

  | Background | `FloatBorder` fg | Popup bg (`NormalFloat` → `Pmenu`) | Editor bg |
  |---|---|---|---|
  | dark | `#11111b` (crust) | `#181825` | transparent (terminal) |
  | light | `#dce0e8` | `#e6e9ef` | transparent (terminal) |

  A border alone would not make the popup "more prominent and visible". This is the root of
  the user's complaint.
- **Decision**: In the existing `ColorScheme` autocommand in `config.colorscheme`, after the
  transparency pass, set `FloatBorder` to the foreground of `FloatTitle` (resolved with
  `link = false`) and the background of `NormalFloat`. Under catppuccin that is blue: `#89b4fa`
  in dark mode, `#1e66f5` in light mode. The border then matches the title colour.
- **Rationale**:
  - Taking the colour from the active scheme's title instead of a hard-coded hex keeps it in
    the scheme's palette. It follows the dark/light switch, because catppuccin reloads and the
    autocommand runs again.
  - Using the popup's background for the border cells makes the frame read as part of the
    popup, not as a strip of terminal background.
  - The autocommand is created before `colorscheme` is called, so it applies on the very first
    load too.
  - If `FloatTitle` has no foreground (some other scheme), the group is left as the scheme
    defined it.
- **Alternatives considered**:
  - Linking to `DiagnosticInfo`: rejected because the popup is shared by hover and signature
    help, so a diagnostic colour would be misleading.
  - Hard-coded hex: rejected because it breaks the dark/light switch and other schemes.
  - Catppuccin plugin options: not applicable, because the bundled scheme has none.

## R3 — Title, source and severity colour in the diagnostic popup (FR-004 – FR-006)

- **Decision**: In `config.diagnostics` `M.setup()`, extend the existing `vim.diagnostic.config`
  call with `float = { title = " Diagnostics ", header = "", source = true }`.
- **Rationale** (verified output for a line with a sourced warning and an unsourced
  two-line error):

  ```text
  ╭──────── Diagnostics ────────╮
  │1. Lua Diagnostics.: unused local x │   ← DiagnosticFloatingWarn
  │2. an error                         │   ← DiagnosticFloatingError
  │   second line                      │   ← DiagnosticFloatingError
  ╰────────────────────────────────────╯
  ```

  - `title` is passed through to the float window (title position `center`, highlighted with
    `FloatTitle`).
  - `header = ""` removes the default in-body "Diagnostics:" line, which the title now
    duplicates.
  - `source = true` prefixes every entry that has a source. An entry with no source gets no
    prefix and no `nil` (spec edge case).
  - Severity colouring is core behaviour: each message is drawn with
    `DiagnosticFloating{Error,Warn,Info,Hint}`, which link to the same `Diagnostic*` groups as
    signs and virtual text (FR-006). No change is needed.
  - Because it is part of `vim.diagnostic.config`, it applies to every way of opening the popup
    (`<C-w>d`, `:lua vim.diagnostic.open_float()`, jump-with-float) without passing options
    (FR-007).
  - It lives in `M.setup()`, which already runs on the first `DiagnosticChanged` (any source)
    or the first toggle. The style is therefore in place before any diagnostic exists to be
    shown (FR-008), and `vim.diagnostic` still does not load at startup.
- **Alternatives considered**: `source = "if_many"` was rejected because FR-005 asks for the
  source on every entry whenever it is known.

## R4 — Diagnostics toggled off (spec edge case)

- **Finding**: With `vim.diagnostic.enable(false)`, `vim.diagnostic.open_float()` still opens a
  popup with the cursor line's diagnostics. Core treats an explicit request as a request.
- **Decision**: Keep core behaviour. Suppressing it would need a remapped `<C-w>d` (violates
  FR-009) or a wrapper around `open_float` (monkey-patch). The spec edge case was updated to
  match. A line with no diagnostics opens nothing, so no empty frame can appear.

## R5 — Screen edges and narrow windows (spec edge cases)

- **Expected (not probed headless)**: `open_floating_preview` sizes and anchors the float
  against the editor size and flips it above/left when there is no room, counting the border
  in that size. No configuration is planned; T003 confirms it manually (quickstart §2.4–2.5).
  If clipping is seen, revisit before marking US1 done.
- **Verified in a real terminal (tmux, T003)**: at 100×15 the full border stays on screen for
  the top line, the last line (popup flips above) and a far-right cursor (popup shifts left).
  At 30 columns the popup wraps and its border is complete, but the last wrapped line is
  hidden. Core sizing (`vim.lsp.util._make_floating_popup_size`) counts wrapped rows by
  characters while the window wraps at word boundaries. The same clipping happens with
  `border = "none"`, so it is not caused by this feature; at 50 columns and wider nothing is
  hidden. Accepted as a core limitation; the hidden line can be reached by pressing `<C-w>d`
  again to enter the popup and scrolling.
