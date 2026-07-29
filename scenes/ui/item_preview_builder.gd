class_name ItemPreviewBuilder
extends RefCounted


static func for_player(
	item: ItemData,
	player: Player,
	target_slot: int = EquipmentManager.INVALID_SLOT
) -> CombatantPreviewData:
	var preview := CombatantPreviewData.new()

	preview.hp_delta = minf(
		item.healing_amount,
		player.max_hp - player.current_hp
	)
	preview.mp_delta = minf(
		item.mp_recovery_amount,
		player.max_mp - player.current_mp
	)

	if item is EquipmentData:
		var equipment := item as EquipmentData
		var deltas := player.equipment_manager.get_bonus_delta(
			equipment,
			target_slot
		)

		preview.max_hp_delta = float(
			deltas.get(&"max_hp", 0.0)
		)
		preview.max_mp_delta = float(
			deltas.get(&"max_mp", 0.0)
		)
		preview.atk_delta = float(
			deltas.get(&"atk", 0.0)
		)
		preview.def_delta = float(
			deltas.get(&"def", 0.0)
		)
		preview.spd_delta = float(
			deltas.get(&"spd", 0.0)
		)

	return preview
