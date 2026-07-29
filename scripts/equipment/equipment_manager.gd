class_name EquipmentManager
extends RefCounted

signal equipment_changed

enum EquipmentSlot {
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	LEFT_HAND,
	RIGHT_HAND,
	ACCESSORY,
}

const INVALID_SLOT := -1
const HAND_SLOTS: Array[int] = [
	EquipmentSlot.LEFT_HAND,
	EquipmentSlot.RIGHT_HAND,
]

var equipped_items: Dictionary = {}


func _init() -> void:
	for slot in EquipmentSlot.values():
		equipped_items[slot] = null


func get_item(slot: EquipmentSlot) -> EquipmentData:
	return equipped_items.get(slot) as EquipmentData


func capture_state() -> Dictionary:
	return equipped_items.duplicate()


func restore_state(state: Dictionary) -> void:
	for slot: int in EquipmentSlot.values():
		equipped_items[slot] = (
			state.get(slot) as EquipmentData
		)

	equipment_changed.emit()


func get_default_slot(item: EquipmentData) -> int:
	if item == null:
		return INVALID_SLOT

	match item.slot_type:
		EquipmentData.EquipmentSlotType.HEAD:
			return EquipmentSlot.HEAD
		EquipmentData.EquipmentSlotType.CHEST:
			return EquipmentSlot.CHEST
		EquipmentData.EquipmentSlotType.HANDS:
			return EquipmentSlot.HANDS
		EquipmentData.EquipmentSlotType.LEGS:
			return EquipmentSlot.LEGS
		EquipmentData.EquipmentSlotType.FEET:
			return EquipmentSlot.FEET
		EquipmentData.EquipmentSlotType.ACCESSORY:
			return EquipmentSlot.ACCESSORY
		EquipmentData.EquipmentSlotType.HAND:
			return _get_default_hand_slot(item)

	return INVALID_SLOT


func _get_default_hand_slot(item: EquipmentData) -> int:
	match item.hand_rule:
		EquipmentData.HandRule.LEFT_ONLY:
			return EquipmentSlot.LEFT_HAND
		EquipmentData.HandRule.RIGHT_ONLY:
			return EquipmentSlot.RIGHT_HAND
		EquipmentData.HandRule.TWO_HANDED:
			return EquipmentSlot.RIGHT_HAND
		EquipmentData.HandRule.EITHER_HAND:
			if get_item(EquipmentSlot.LEFT_HAND) == null:
				return EquipmentSlot.LEFT_HAND
			if get_item(EquipmentSlot.RIGHT_HAND) == null:
				return EquipmentSlot.RIGHT_HAND
			return EquipmentSlot.RIGHT_HAND

	return INVALID_SLOT


func requires_hand_selection(item: EquipmentData) -> bool:
	return (
		item != null
		and item.slot_type == EquipmentData.EquipmentSlotType.HAND
		and item.hand_rule == EquipmentData.HandRule.EITHER_HAND
	)


func can_equip(
	item: EquipmentData,
	target_slot: int = INVALID_SLOT
) -> bool:
	if item == null:
		return false

	var resolved_slot := _resolve_slot(item, target_slot)

	if resolved_slot == INVALID_SLOT:
		return false

	if item.slot_type != EquipmentData.EquipmentSlotType.HAND:
		return resolved_slot == get_default_slot(item)

	match item.hand_rule:
		EquipmentData.HandRule.LEFT_ONLY:
			return resolved_slot == EquipmentSlot.LEFT_HAND
		EquipmentData.HandRule.RIGHT_ONLY:
			return resolved_slot == EquipmentSlot.RIGHT_HAND
		EquipmentData.HandRule.EITHER_HAND:
			return resolved_slot in HAND_SLOTS
		EquipmentData.HandRule.TWO_HANDED:
			return resolved_slot in HAND_SLOTS

	return false


func equip(
	item: EquipmentData,
	target_slot: int = INVALID_SLOT
) -> bool:
	if not can_equip(item, target_slot):
		return false

	var resolved_slot := _resolve_slot(item, target_slot)
	_apply_equip(equipped_items, item, resolved_slot)
	equipment_changed.emit()
	return true


func get_displaced_items(
	item: EquipmentData,
	target_slot: int = INVALID_SLOT
) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []

	if not can_equip(item, target_slot):
		return result

	var resolved_slot := _resolve_slot(item, target_slot)

	if (
		item.slot_type == EquipmentData.EquipmentSlotType.HAND
		and item.hand_rule == EquipmentData.HandRule.TWO_HANDED
	):
		_append_displaced_item(
			result,
			get_item(EquipmentSlot.LEFT_HAND)
		)
		_append_displaced_item(
			result,
			get_item(EquipmentSlot.RIGHT_HAND)
		)
	else:
		_append_displaced_item(
			result,
			get_item(resolved_slot)
		)

	return result


func unequip(slot: EquipmentSlot) -> EquipmentData:
	var item := get_item(slot)

	if item == null:
		return null

	if (
		item.hand_rule
		== EquipmentData.HandRule.TWO_HANDED
	):
		equipped_items[EquipmentSlot.LEFT_HAND] = null
		equipped_items[EquipmentSlot.RIGHT_HAND] = null
	else:
		equipped_items[slot] = null

	equipment_changed.emit()
	return item


func is_equipped(item: EquipmentData) -> bool:
	return not get_equipped_slots(item).is_empty()


func get_equipped_slots(item: EquipmentData) -> Array[int]:
	var result: Array[int] = []

	for slot in equipped_items:
		if equipped_items[slot] == item:
			result.append(slot)

	return result


func get_equipped_slot_text(item: EquipmentData) -> String:
	var labels: Array[String] = []

	for slot in get_equipped_slots(item):
		labels.append(get_slot_short_name(slot))

	if labels.is_empty():
		return ""

	return "/".join(labels)


func get_slot_name(slot: int) -> String:
	match slot:
		EquipmentSlot.HEAD:
			return "Head"
		EquipmentSlot.CHEST:
			return "Chest"
		EquipmentSlot.HANDS:
			return "Hands"
		EquipmentSlot.LEGS:
			return "Legs"
		EquipmentSlot.FEET:
			return "Feet"
		EquipmentSlot.LEFT_HAND:
			return "Left Hand"
		EquipmentSlot.RIGHT_HAND:
			return "Right Hand"
		EquipmentSlot.ACCESSORY:
			return "Accessory"

	return "Unknown"


func get_slot_short_name(slot: int) -> String:
	match slot:
		EquipmentSlot.LEFT_HAND:
			return "L"
		EquipmentSlot.RIGHT_HAND:
			return "R"

	return get_slot_name(slot)


func get_total_bonus(stat_name: StringName) -> float:
	return _get_total_bonus_from(equipped_items, stat_name)


func get_bonus_delta(
	item: EquipmentData,
	target_slot: int = INVALID_SLOT
) -> Dictionary:
	var resolved_slot := _resolve_slot(item, target_slot)

	if not can_equip(item, resolved_slot):
		return {}

	var simulated := equipped_items.duplicate()
	_apply_equip(simulated, item, resolved_slot)

	return {
		&"max_hp": (
			_get_total_bonus_from(simulated, &"max_hp")
			- get_total_bonus(&"max_hp")
		),
		&"max_mp": (
			_get_total_bonus_from(simulated, &"max_mp")
			- get_total_bonus(&"max_mp")
		),
		&"atk": (
			_get_total_bonus_from(simulated, &"atk")
			- get_total_bonus(&"atk")
		),
		&"def": (
			_get_total_bonus_from(simulated, &"def")
			- get_total_bonus(&"def")
		),
		&"spd": (
			_get_total_bonus_from(simulated, &"spd")
			- get_total_bonus(&"spd")
		),
	}


func _resolve_slot(
	item: EquipmentData,
	target_slot: int
) -> int:
	if item == null:
		return INVALID_SLOT

	if target_slot != INVALID_SLOT:
		return target_slot

	return get_default_slot(item)


func _apply_equip(
	equipment: Dictionary,
	item: EquipmentData,
	resolved_slot: int
) -> void:
	var occupying_item := equipment.get(resolved_slot) as EquipmentData

	if (
		occupying_item != null
		and occupying_item.hand_rule
		== EquipmentData.HandRule.TWO_HANDED
	):
		equipment[EquipmentSlot.LEFT_HAND] = null
		equipment[EquipmentSlot.RIGHT_HAND] = null

	if (
		item.slot_type == EquipmentData.EquipmentSlotType.HAND
		and item.hand_rule == EquipmentData.HandRule.TWO_HANDED
	):
		equipment[EquipmentSlot.LEFT_HAND] = item
		equipment[EquipmentSlot.RIGHT_HAND] = item
		return

	equipment[resolved_slot] = item


func _append_displaced_item(
	result: Array[EquipmentData],
	item: EquipmentData
) -> void:
	if item == null:
		return

	if (
		item.hand_rule == EquipmentData.HandRule.TWO_HANDED
		and result.has(item)
	):
		return

	result.append(item)


func _get_total_bonus_from(
	equipment: Dictionary,
	stat_name: StringName
) -> float:
	var result := 0.0

	for slot in equipment:
		var item := equipment[slot] as EquipmentData

		if item == null:
			continue

		if (
			slot == EquipmentSlot.RIGHT_HAND
			and item.hand_rule
			== EquipmentData.HandRule.TWO_HANDED
			and equipment[EquipmentSlot.LEFT_HAND] == item
		):
			continue

		match stat_name:
			&"max_hp":
				result += item.max_hp_bonus
			&"max_mp":
				result += item.max_mp_bonus
			&"atk":
				result += item.atk_bonus
			&"def":
				result += item.def_bonus
			&"spd":
				result += item.spd_bonus

	return result
