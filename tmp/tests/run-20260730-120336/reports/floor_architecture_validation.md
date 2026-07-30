# Floor architecture validation

## Scope

- Replace per-floor `FloorDefinition` resources with the strict
  `res://scenes/floors/{floor_id}.tscn` naming convention.
- Keep shared metadata and lifecycle behavior on `Floor`.
- Keep floor-specific Switch-to-map behavior on `floor_1.gd`.
- Remove the current Door implementation and unused floor scaffolding.

## Runtime assertions

- `floor_1` loaded from `floor_id = floor_1`.
- World position `(64, -256)` resolved to `Walls` cell `(2, -8)`.
- Initial inactive Switch:
  - wall source: `1`
  - wall atlas: `(0, 1)`
- Active Switch:
  - `is_active = true`
  - wall source: `-1` (cell erased)
- Inactive Switch after toggling back:
  - `is_active = false`
  - wall source: `1`
  - wall atlas: `(0, 1)`
- Floor transition:
  - `floor_1 -> floor_2 / FromDownStair` succeeded.
  - Player arrived at `(0, 32)`.
  - `floor_2 -> floor_1 / FromFloor2Stairs` succeeded.
  - Player arrived at `(0, 0)`.
- State restoration after returning to `floor_1`:
  - Switch remained active.
  - Target wall source remained `-1`.

## Visual inspection

- Inactive close-up shows the configured blue wall tile.
- Active close-up shows the underlying white floor tile at the same position.
- No missing-scene placeholder or layout break was visible.

## Cleanup checks

- Active scripts and scenes contain no Door class, Door scene, or Door script
  references.
- `FloorCatalog`, `FloorDefinition`, their per-floor resources, the unused
  `floor_basic.tscn`, and `floor_backup.gd` were removed.

## Result

**PASS**

Final project basic regression: 8/8 passed.

## Evidence

- `tmp/tests/run-20260730-120650/reports/basic_regression.md`
- `tmp/tests/run-20260730-120336/screenshots/floor_1_switch_inactive_closeup.png`
- `tmp/tests/run-20260730-120336/screenshots/floor_1_switch_active_closeup.png`
