# Item System and Switch Interaction Validation

## Result

PASS

## Item system

- `RedFragment` is an `ItemPickup`.
- Its scene instance is visible and its `Sprite2D` has a texture.
- Its resource category is `KEY_ITEM` and it cannot be used directly.
- `Small Potion` can be used from inventory, heals 50 HP, and is consumed.
- `Blade LV0` can be used from inventory and has `max_stack = 1`.

## Switch interaction

- Player was positioned one tile below the first-floor switch and faced upward.
- Simulated the `interact` input action.
- Switch state changed from inactive to active.
- After the looping interaction animation reached its final frame,
  `Player.is_acting` returned to `false`.
- A subsequent `move_down` action moved the player from `(0, -224)` to
  `(0, -192)`, proving input was no longer locked.

## Visual check

- `screenshots/item_system_switch_validation.png` was inspected.
- The first-floor scene, player idle state, HUD, pickups, and opened switch
  path rendered without missing-resource placeholders.

