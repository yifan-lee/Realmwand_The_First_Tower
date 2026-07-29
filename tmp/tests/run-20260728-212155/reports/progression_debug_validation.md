# Progression and Debug Configuration Validation

Run time: 2026-07-28 21:25 EDT

## Basic regression

- Result: 8/8 passed.
- Main scene started and stopped with zero editor errors.

## Enemy experience

- Slime with `experience_reward_override = -1` used its calculated
  reward of 5 EXP.
- A duplicated enemy with override 99 returned exactly 99 EXP.
- Override 0 returned exactly 0 EXP.

## Skill unlock

- The level 1 player knew only `basic_attack`.
- Gaining 60 EXP raised the player to level 2.
- Level 2 automatically learned `power_strike`.
- The world message displayed `Learned skill: Power Strike`.
- The player menu showed Basic Attack and Power Strike.

## Debug player configuration

A temporary enabled `PlayerDebugConfig` was injected into a separate
Player instance. Runtime assertions verified:

- Global position `(320, 160)`.
- Level 7, 12 EXP, 34 gold, and 9 unspent points.
- Base HP 300, MP 150, ATK 40, DEF 50, and SPD 60.
- Current HP 123 and negative configured MP resolving to full 150.
- Sword equipped in the right hand, producing total ATK 50.
- One Small Potion in the inventory.
- Power Strike as the sole starting learned skill.

The temporary player was removed after validation.

## Evidence

- `basic_regression.md`
- `../screenshots/main_scene.png`
- `../screenshots/level_2_skills.png`
