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

	if item.attack_bonus != 0:
		detail.properties.append(
			"ATK: %+d" % item.attack_bonus
		)

	if item.defense_bonus != 0:
		detail.properties.append(
			"DEF: %+d" % item.defense_bonus
		)

	if item.speed_bonus != 0:
		detail.properties.append(
			"SPD: %+d" % item.speed_bonus
		)

	if item.item_type == ItemData.ItemType.WEAPON:
		detail.properties.append("Type: Equipment")
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
