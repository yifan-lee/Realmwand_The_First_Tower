# Player Progression Goal Validation

Run time: 2026-07-28 21:05 EDT

## Logic assertions

- Level 1 requires 60 EXP (`50 + 10 * 1`).
- Initial player CP is 74.
- Slime CP is 23 and grants 5 EXP with divisor 5.
- Gaining 60 EXP raises the player to level 2 with 0 carried EXP.
- Level 2 requires 70 EXP.
- Automatic level growth changes base stats to HP 210, MP 105,
  ATK 21, DEF 22, and SPD 25.
- Level-up grants 5 unspent attribute points.
- Automatic growth raises player CP from 74 to 79.
- Spending one point on DEF raises DEF by 2, lowers available points
  by 1, and raises CP by 1.

## Interaction assertions

- Opening the player menu and selecting `Attributes` displays the
  allocation panel.
- Clicking `+5 SPD` lowers available points from 5 to 4 and raises
  SPD from 25 to 30.
- The points label and SPD value refresh immediately.
- `Back` closes the allocation panel, restores the menu controls,
  and refreshes the player status panel.
- The editor reported zero errors after the scene stopped.

## Visual evidence

- `../screenshots/attribute_allocation_panel_fixed.png`
- `../screenshots/attribute_allocation_after_spd.png`
