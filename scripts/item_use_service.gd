class_name ItemUseService
extends RefCounted


static func can_use(
	item: ItemData,
	player: Player,
	in_battle: bool
) -> bool:
	if item == null or player == null:
		return false

	if in_battle and not item.usable_in_battle:
		return false

	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			var preview := ItemPreviewBuilder.for_player(
				item,
				player
			)
			return (
				not is_zero_approx(preview.hp_delta)
				or not is_zero_approx(preview.mp_delta)
			)

		ItemData.ItemType.EQUIPMENT:
			return item is EquipmentData

		ItemData.ItemType.SPECIAL:
			return false

	return false


static func use(
	item: ItemData,
	player: Player,
	in_battle: bool,
	target_slot: int = EquipmentManager.INVALID_SLOT
) -> bool:
	if not can_use(item, player, in_battle):
		return false

	match item.item_type:
		ItemData.ItemType.CONSUMABLE:
			var used_item := item

			if item.consumed_on_use:
				used_item = player.consume_item(item.id)

				if used_item == null:
					return false

			player.heal(used_item.healing_amount)
			player.restore_mp(used_item.mp_recovery_amount)
			return true

		ItemData.ItemType.EQUIPMENT:
			var equipment := item as EquipmentData
			return player.equip_item(
				equipment,
				target_slot
			)

	return false
