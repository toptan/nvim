## ADDED Requirements

### Requirement: mini.indentscope default scope visualization, no animation

The system SHALL visualize the current indent scope via `mini.indentscope` (part of `mini.nvim`,
configured in `plugin/60-mini.lua`) with its default configuration, except the step-drawing
animation SHALL be disabled (`draw.animation = gen_animation.none()`) so the scope indicator draws
instantly rather than animating in. Default mappings stay active: `ii`/`ai` textobjects, `[i`/`]i`
motions.

#### Scenario: Cursor rests inside an indented block

- **WHEN** the cursor is inside an indented block of code and the default draw delay has elapsed
- **THEN** the scope indicator symbol is drawn immediately alongside the scope's lines, with no
  step-by-step animation

#### Scenario: Using the scope textobject

- **WHEN** the user types an operator followed by `ii` or `ai` (e.g. `dii`, `vai`)
- **THEN** the operator applies to the current indent scope's body (`ii`) or body-plus-border
  (`ai`)

#### Scenario: Jumping to scope borders

- **WHEN** the user presses `[i` or `]i` in normal mode
- **THEN** the cursor jumps to the top or bottom border line of the current indent scope
