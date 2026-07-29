# Player Debug Mode

Player debug state is configured through:

`res://resources/debug/player_debug_config.tres`

The resource is assigned to the root node of
`res://scenes/actors/player.tscn`.

## Enabling

1. Open `player_debug_config.tres` in the Godot Inspector.
2. Enable `Debug Mode > Enabled`.
3. Configure the desired starting state.
4. Run the project as a debug build.

The configuration is ignored in non-debug builds. It is disabled by
default.

## Configurable state

- Global world position.
- Level, current experience, gold, and unspent attribute points.
- Base HP, MP, ATK, DEF, and SPD.
- Current HP and MP. A negative value starts the resource at its
  calculated maximum.
- All eight equipment slots.
- Starting inventory items.
- Starting learned skills.

Equipment entries are applied directly to their configured slots and
do not need to also appear in the debug inventory. Invalid slot and
equipment combinations produce a warning and are skipped.

When debug mode supplies a skills list, that list replaces the normal
starting learned skills. Future level-ups continue checking the
player's normal skill catalog.

The debug resource is read only at runtime; player state is never
written back to it.

## Enemy experience override

Every `EnemyData` resource exposes
`experience_reward_override`:

- `-1`: calculate experience from CP and the configured divisor.
- `0` or greater: use the specified value exactly.
