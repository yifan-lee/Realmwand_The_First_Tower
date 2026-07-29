class_name SelectionDetailBuilder
extends RefCounted


static func from_skill(
	skill: SkillData,
	current_mp: float,
	remaining_cd: float
) -> SelectionDetailData:
	var detail := SelectionDetailData.new()

	detail.title = skill.display_name
	detail.description = skill.description

	detail.properties.append(
		"Power: %.0f" % skill.skill_power
	)

	detail.properties.append(
		"MP Cost: %d" % skill.mp_cost
	)

	detail.properties.append(
		"Cooldown: %.1fs" % skill.cooldown_seconds
	)

	if remaining_cd > 0.0:
		detail.warning = (
			"Cooling down: %.1fs remaining"
			% remaining_cd
		)
	elif current_mp < skill.mp_cost:
		detail.warning = "Not enough MP"

	return detail


static func from_item(
	item: ItemData,
	player: Player,
	in_battle: bool
) -> SelectionDetailData:
	var detail := SelectionDetailData.new()

	detail.title = item.display_name
	detail.description = item.description

	if item.healing_amount != 0:
		detail.properties.append(
			"HP Recovery: %d" % item.healing_amount
		)

	if item.mp_recovery_amount != 0:
		detail.properties.append(
			"MP Recovery: %d" % item.mp_recovery_amount
		)

	if item is EquipmentData:
		var equipment := item as EquipmentData

		detail.properties.append("Type: Equipment")
		detail.properties.append(
			"Slot: %s" % _get_equipment_slot_text(equipment)
		)

		_append_bonus(
			detail,
			"Max HP",
			equipment.max_hp_bonus
		)
		_append_bonus(
			detail,
			"Max MP",
			equipment.max_mp_bonus
		)
		_append_bonus(detail, "ATK", equipment.atk_bonus)
		_append_bonus(detail, "DEF", equipment.def_bonus)
		_append_bonus(detail, "SPD", equipment.spd_bonus)

		var equipped_slots := (
			player.equipment_manager
			.get_equipped_slot_text(equipment)
		)

		if not equipped_slots.is_empty():
			detail.properties.append(
				"Equipped: %s" % equipped_slots
			)
	elif item.item_type == ItemData.ItemType.SPECIAL:
		detail.properties.append("Type: Special")

	if in_battle and not item.usable_in_battle:
		detail.warning = "Cannot be used in battle"
	elif item.item_type == ItemData.ItemType.SPECIAL:
		detail.warning = "Cannot be used directly"
	elif (
		item.item_type == ItemData.ItemType.CONSUMABLE
		and item.healing_amount > 0
		and item.mp_recovery_amount <= 0
		and player.current_hp >= player.max_hp
	):
		detail.warning = "HP is already full"
	elif (
		item.item_type == ItemData.ItemType.CONSUMABLE
		and item.mp_recovery_amount > 0
		and item.healing_amount <= 0
		and player.current_mp >= player.max_mp
	):
		detail.warning = "MP is already full"

	return detail


static func _append_bonus(
	detail: SelectionDetailData,
	label: String,
	value: float
) -> void:
	if is_zero_approx(value):
		return

	detail.properties.append(
		"%s: %+.0f" % [label, value]
	)


static func _get_equipment_slot_text(
	equipment: EquipmentData
) -> String:
	match equipment.slot_type:
		EquipmentData.EquipmentSlotType.HEAD:
			return "Head"
		EquipmentData.EquipmentSlotType.CHEST:
			return "Chest"
		EquipmentData.EquipmentSlotType.HANDS:
			return "Hands"
		EquipmentData.EquipmentSlotType.LEGS:
			return "Legs"
		EquipmentData.EquipmentSlotType.FEET:
			return "Feet"
		EquipmentData.EquipmentSlotType.ACCESSORY:
			return "Accessory"
		EquipmentData.EquipmentSlotType.HAND:
			return _get_hand_rule_text(equipment.hand_rule)

	return "Unknown"


static func _get_hand_rule_text(
	hand_rule: EquipmentData.HandRule
) -> String:
	match hand_rule:
		EquipmentData.HandRule.LEFT_ONLY:
			return "Left Hand"
		EquipmentData.HandRule.RIGHT_ONLY:
			return "Right Hand"
		EquipmentData.HandRule.EITHER_HAND:
			return "Either Hand"
		EquipmentData.HandRule.TWO_HANDED:
			return "Two-Handed"

	return "Hand"
