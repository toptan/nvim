# Contract: Popup Style

What the user (and any plugin) can rely on after this feature.

## Every floating popup

- Opened without an explicit `border`: drawn with a rounded border `╭─╮│╯─╰│`.
- Opened with an explicit `border` (any value, including `"none"`): unchanged.
- The border is highlighted with `FloatBorder`: the active scheme's title colour on the popup
  background, recomputed whenever the colour scheme or `'background'` changes.
- The completion menu is not a floating popup and is not affected.

## Diagnostic popup (`<C-w>d`, `vim.diagnostic.open_float()`)

```text
╭──── Diagnostics ────╮
│1. <source>: <message> │   coloured by severity
│2. <message>           │   (no source known → no prefix)
╰───────────────────────╯
```

- The title ` Diagnostics ` is centred on the top border.
- There is no in-body "Diagnostics:" header line.
- Each entry with a source is prefixed `<source>: `.
- Each entry is coloured with `DiagnosticFloating<Severity>`.
- A cursor line with no diagnostics opens no popup.
- With diagnostics toggled off, an explicit request still opens the popup (core behaviour).

## Unchanged

- Key mappings: none added, removed or changed.
- `<leader>td/tt/tl` behaviour and messages.
- `config.diagnostics` public API: `M.setup()` (idempotent) is still the only export.
