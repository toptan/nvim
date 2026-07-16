## MODIFIED Requirements

### Requirement: Leader group descriptions

The system SHALL expose a table, `Config.leader_group_clues`, describing the purpose of each
`<Leader>` prefix in normal and visual mode (`b` Buffer, `c` Code, `e` Explore/Edit, `f` Find,
`g` Git, `l` Language, `m` Map, `o` Other, `s` Session, `t` Toggle, `v` Visits), for consumption by
`mini.clue` (configured in `plugin/60-mini.lua`, see the `keybinding-clues` capability).

#### Scenario: Opening the leader-key popup

- **WHEN** `mini.clue` reads `Config.leader_group_clues` and the user presses `<Leader>` and waits
- **THEN** the popup shows the configured group description for each prefix key
