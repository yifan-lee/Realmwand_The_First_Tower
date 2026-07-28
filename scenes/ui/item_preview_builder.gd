class_name ItemPreviewBuilder
extends RefCounted


static func for_player(
	item: ItemData,
	player: Player
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

	if item.item_type == ItemData.ItemType.WEAPON:
		preview.atk_delta = (
			item.attack_bonus
			- player.equipment_atk_bonus
		)
		preview.def_delta = (
			item.defense_bonus
			- player.equipment_def_bonus
		)
		preview.spd_delta = (
			item.speed_bonus
			- player.equipment_spd_bonus
		)

	return preview
