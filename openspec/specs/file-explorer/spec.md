# file-explorer Specification

## Purpose
TBD - created by archiving change add-mini-input-files-cursorword. Update Purpose after archive.

## Requirements

### Requirement: mini.files default file explorer

The system SHALL provide a file explorer via `mini.files` (part of `mini.nvim`, configured in
`plugin/60-mini.lua`) with its default configuration: buffer-local mappings inside the explorer
(`q` close, `l`/`L` go in, `h`/`H` go out, `'`/`m` bookmarks, `<BS>` reset, `@` reveal cwd, `g?`
help, `=` synchronize, `<`/`>` trim), `permanent_delete = true`, and `use_as_default_explorer =
true` (directory buffers open in `mini.files` instead of netrw).

#### Scenario: Opening a directory path

- **WHEN** the user opens a file-system path that is a directory (e.g. `:edit .`)
- **THEN** `mini.files` opens showing that directory's contents, instead of netrw

#### Scenario: Deleting an entry inside the explorer

- **WHEN** the user deletes a file or directory entry from within the `mini.files` explorer and
  synchronizes the change
- **THEN** the entry is permanently removed from the file system (no trash/undo)

### Requirement: Toggle explorer anchored on the current file

The system SHALL toggle the `mini.files` explorer with `-` in normal mode, anchored on the current
buffer's file (opening reveals that file in the tree; pressing again while open closes it).

#### Scenario: Opening the explorer on the current file

- **WHEN** the explorer is closed and the user presses `-`
- **THEN** the explorer opens with the current buffer's file focused in its parent directory's
  listing

#### Scenario: Closing the explorer

- **WHEN** the explorer is open (with no pending unsaved file-system actions) and the user presses
  `-`
- **THEN** the explorer closes

### Requirement: Toggle explorer anchored on the working directory

The system SHALL toggle the `mini.files` explorer with `<Leader>ed` in normal mode, anchored on the
current working directory.

#### Scenario: Opening the explorer on the working directory

- **WHEN** the explorer is closed and the user presses `<Leader>ed`
- **THEN** the explorer opens showing the current working directory's contents

#### Scenario: Closing the explorer

- **WHEN** the explorer is open (with no pending unsaved file-system actions) and the user presses
  `<Leader>ed`
- **THEN** the explorer closes
