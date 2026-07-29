# Level-up Allocation Validation

- Status: passed
- Godot: 4.7 stable
- Level trigger: 60 EXP at level 1

## Assertions

- Player advanced from level 1 to level 2 immediately after receiving EXP.
- Automatic growth produced HP 210, MP 105, ATK 21, DEF 22, SPD 25.
- The level-up allocation panel became visible with 5 remaining points.
- Player unhandled input was disabled while allocation was pending.
- Confirm remained disabled while points were unassigned.
- The HP plus and minus buttons both changed the pending allocation.
- A pending allocation of HP 2, MP 1, ATK 2 displayed:
  - HP `+20  Max +20`
  - MP `+5  Max +5`
  - ATK `+2`
- Confirm enabled only after all 5 points were assigned.
- Confirm committed HP 230, MP 110, ATK 23 and left DEF 22, SPD 25.
- Unspent points became 0, the panel closed, the HUD refreshed, and player
  unhandled input resumed.
- Learned skills at level 2 were Basic Attack and Power Strike.
- The editor reported 0 errors after the scene stopped.

## Evidence

- `../screenshots/level_up_initial.png`
- `../screenshots/level_up_preview.png`
