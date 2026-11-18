# Neovim Daily Driver Config Constitution

## Core Principles

### I. Native-First

Built-in Neovim functionality is the default choice; a plugin is the exception.

- A plugin MUST NOT be added when Neovim core provides the capability adequately
  (e.g. `vim.pack` for plugin management, `vim.lsp.config`/`vim.lsp.enable` for LSP,
  built-in treesitter, diagnostics, commenting, and snippets).
- Every plugin added MUST have a one-line justification (in a comment beside its
  spec or in the commit message) stating what core Neovim lacks.
- When Neovim core gains a feature that makes a plugin redundant, the plugin
  SHOULD be removed in favour of the native feature.

Rationale: Fewer dependencies mean fewer breakages on upgrade, less startup
cost, and a config that stays understandable for years.

### II. Modular Lua

The configuration is written in Lua and organised by concern.

- All configuration MUST be Lua; Vimscript is allowed only via `vim.cmd` for
  functionality that has no Lua API.
- `init.lua` MUST remain a thin entry point that only loads modules.
- Each module MUST own a single concern (options, keymaps, autocommands, LSP,
  a single plugin or a tightly related plugin group).
- Global state MUST NOT be introduced beyond what Neovim itself requires
  (`vim.g`, `vim.o`, etc.); modules share data via `require`.
- Autocommands MUST be created inside named augroups with `clear = true` so
  re-sourcing a module never duplicates them.

Rationale: Small, single-purpose modules can be read, disabled, or replaced in
isolation, which keeps a long-lived personal config maintainable.

### III. Fast, Deferred Startup

Editing must be available immediately; everything else waits.

- Only what is needed to render the first buffer (options, core keymaps,
  colorscheme) MAY run eagerly at startup.
- Plugins and features tied to a filetype, command, key, or event MUST be
  loaded on that trigger rather than at startup.
- Startup time, measured with `nvim --startuptime` on an empty buffer, SHOULD
  stay below 100 ms; a change that regresses it noticeably MUST be justified.

Rationale: A daily-driver editor is opened many times a day; startup latency is
paid on every launch.

### IV. Reproducible & Fault-Tolerant

The config must come up cleanly on a fresh machine and never break the editor.

- Cloning the repository into the Neovim config directory and starting Neovim
  MUST be sufficient to install plugins and reach a working editor, with no
  manual steps other than installing documented external tools.
- External dependencies (language servers, formatters, linters, CLI tools)
  MUST be listed in the README.
- A missing external tool or a failing plugin MUST NOT raise errors at startup;
  the affected feature degrades silently or with a single, non-blocking notice
  (use `pcall` and `vim.fn.executable` checks where appropriate).
- `nvim --headless "+qa"` MUST exit without errors.

Rationale: Editors are needed most when something else is broken; the config
must never be the reason the editor is unusable.

### V. Consistent Style

All code follows one formatting standard, enforced by tooling.

- Formatting MUST follow `.editorconfig` (Lua: 2-space indent, 80-column limit,
  double quotes, trailing table separators, explicit call parentheses).
- Lua files MUST be free of `lua_ls` diagnostics errors; warnings SHOULD be
  resolved or explicitly suppressed with a justification.
- Keymaps MUST set a `desc` so they are discoverable.

Rationale: Uniform code removes friction when revisiting rarely touched modules
and lets tooling catch mistakes early.

## Technical Constraints

- **Target runtime**: latest stable Neovim (0.12 or newer, required for
  `vim.pack`). Nightly-only APIs MUST NOT be used.
- **Platform**: macOS is the primary platform; platform-specific code MUST be
  guarded so it does not fail elsewhere.
- **Plugin lockfile**: `nvim-pack-lock.json` is machine-local and is not
  committed (see `.gitignore`).
- **Licence**: the repository is released into the public domain (Unlicense);
  vendored third-party code MUST NOT be added.

## Development Workflow

- Every change MUST be verified before commit by: launching Neovim and
  exercising the changed feature, confirming `nvim --headless "+qa"` exits
  cleanly, and checking `:checkhealth` for new errors.
- Commits MUST be small and focused on one concern and SHOULD follow
  Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`).
- Non-trivial features (new language support, workflow changes, plugin
  replacements) SHOULD go through the Spec Kit flow (specify → plan → tasks →
  implement); small tweaks MAY be committed directly.

## Governance

- This constitution supersedes ad-hoc preferences; specs, plans, and tasks
  MUST be checked against it, and any deviation MUST be justified in the plan's
  complexity tracking section.
- Amendments are made via `/speckit-constitution`, recorded in the Sync Impact
  Report, and committed with a `docs:` commit describing the change.
- Versioning follows semantic versioning: MAJOR for removing or redefining a
  principle, MINOR for adding a principle or materially expanding guidance,
  PATCH for clarifications and wording fixes.
- Compliance is reviewed whenever a plan is produced and whenever Neovim is
  upgraded to a new minor version (to revisit Principle I).

**Version**: 1.0.0 | **Ratified**: 2026-11-18 | **Last Amended**: 2026-11-18
