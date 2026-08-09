class_name EquipmentLoadout
extends Node

signal equipment_changed
signal item_equipped(
	slot: int,
	item: EquipmentData
)
signal item_unequipped(
	slot: int,
	item: EquipmentData
)

enum Slot {
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	MAIN_WEAPON,
	SUB_WEAPON,
	ACCESSORY_1,
	ACCESSORY_2,
	ARMS,
}

var _equipped: Dictionary[int, EquipmentData] = {}


func can_equip(
	item: EquipmentData,
	target_slot: int
) -> bool:
	if item == null:
		return false

	match item.slot_type:
		EquipmentData.EquipmentSlotType.HEAD:
			return target_slot == Slot.HEAD

		EquipmentData.EquipmentSlotType.CHEST:
			return target_slot == Slot.CHEST

		EquipmentData.EquipmentSlotType.ARMS:
			return target_slot == Slot.ARMS

		EquipmentData.EquipmentSlotType.HANDS:
			return target_slot == Slot.HANDS

		EquipmentData.EquipmentSlotType.LEGS:
			return target_slot == Slot.LEGS

		EquipmentData.EquipmentSlotType.FEET:
			return target_slot == Slot.FEET

		EquipmentData.EquipmentSlotType.ACCESSORY:
			return (
				target_slot == Slot.ACCESSORY_1
				or target_slot == Slot.ACCESSORY_2
			)

		EquipmentData.EquipmentSlotType.WEAPON:
			return _can_equip_weapon(
				item,
				target_slot
			)

	return false


func equip(
	item: EquipmentData,
	target_slot: int
) -> Array[EquipmentData]:
	var displaced_items: Array[EquipmentData] = []

	if not can_equip(item, target_slot):
		return displaced_items

	displaced_items = get_displaced_items(
		item,
		target_slot
	)

	for displaced_item: EquipmentData in displaced_items:
		_remove_equipped_item(displaced_item)

	if (
		item.slot_type == EquipmentData.EquipmentSlotType.WEAPON
		and item.weapon_rule == EquipmentData.WeaponRule.TWO_HANDED
	):
		_equipped[Slot.MAIN_WEAPON] = item
		_equipped[Slot.SUB_WEAPON] = item
	else:
		_equipped[target_slot] = item

	for displaced_item: EquipmentData in displaced_items:
		item_unequipped.emit(
			target_slot,
			displaced_item
		)

	item_equipped.emit(target_slot, item)
	equipment_changed.emit()

	return displaced_items


func unequip(slot: int) -> EquipmentData:
	var item := get_equipped(slot)

	if item == null:
		return null

	_remove_equipped_item(item)

	item_unequipped.emit(slot, item)
	equipment_changed.emit()

	return item


func get_equipped(slot: int) -> EquipmentData:
	return _equipped.get(slot)


func get_unique_equipped_items() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []

	for item: EquipmentData in _equipped.values():
		if not result.has(item):
			result.append(item)

	return result


func capture_save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var captured: Array[EquipmentData] = []
	for slot: int in _equipped.keys():
		var item: EquipmentData = _equipped[slot]
		if captured.has(item) or item.resource_path.is_empty():
			continue
		captured.append(item)
		result.append({"slot": slot, "resource_path": item.resource_path})
	return result


func restore_save_data(entries_value: Variant) -> void:
	_equipped.clear()
	if entries_value is Array:
		for entry_value: Variant in entries_value:
			if not (entry_value is Dictionary):
				continue
			var item := load(String(entry_value.get("resource_path", ""))) as EquipmentData
			if item != null:
				equip(item, int(entry_value.get("slot", -1)))
	equipment_changed.emit()


func _can_equip_weapon(
	item: EquipmentData,
	target_slot: int
) -> bool:
	match item.weapon_rule:
		EquipmentData.WeaponRule.MAIN_ONLY:
			return target_slot == Slot.MAIN_WEAPON

		EquipmentData.WeaponRule.SUB_ONLY:
			return target_slot == Slot.SUB_WEAPON

		EquipmentData.WeaponRule.EITHER_WEAPON:
			return (
				target_slot == Slot.MAIN_WEAPON
				or target_slot == Slot.SUB_WEAPON
			)

		EquipmentData.WeaponRule.TWO_HANDED:
			return (
				target_slot == Slot.MAIN_WEAPON
				or target_slot == Slot.SUB_WEAPON
			)

	return false


func _collect_displaced_items(
	item: EquipmentData,
	target_slot: int
) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	var affected_slots: Array[int] = [target_slot]

	if (
		item.slot_type
		== EquipmentData.EquipmentSlotType.WEAPON
		and item.weapon_rule
		== EquipmentData.WeaponRule.TWO_HANDED
	):
		affected_slots = [
			Slot.MAIN_WEAPON,
			Slot.SUB_WEAPON,
		]

	for slot: int in affected_slots:
		var equipped_item := get_equipped(slot)

		if (
			equipped_item != null
			and not result.has(equipped_item)
		):
			result.append(equipped_item)

	return result


func _remove_equipped_item(
	item: EquipmentData
) -> void:
	var slots_to_clear: Array[int] = []

	for slot: int in _equipped.keys():
		if _equipped[slot] == item:
			slots_to_clear.append(slot)

	for slot: int in slots_to_clear:
		_equipped.erase(slot)


func get_max_hp_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.max_hp_bonus

	return total


func get_max_mp_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.max_mp_bonus

	return total


func get_atk_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.atk_bonus

	return total


func get_def_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.def_bonus

	return total


func get_spd_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.spd_bonus

	return total


func get_displaced_items(
	item: EquipmentData,
	target_slot: int
) -> Array[EquipmentData]:
	if not can_equip(item, target_slot):
		return []

	return _collect_displaced_items(
		item,
		target_slot
	)


func get_compatible_slots(
	item: EquipmentData
) -> Array[int]:
	var result: Array[int] = []
	for slot: int in Slot.values():
		if can_equip(item, slot):
			result.append(slot)
	return result


func get_slots_for_item(
	item: EquipmentData
) -> Array[int]:
	var result: Array[int] = []
	if item == null:
		return result
	for slot: int in _equipped:
		if _equipped[slot] == item:
			result.append(slot)
	return result


func get_affected_slots(
	item: EquipmentData,
	target_slot: int
) -> Array[int]:
	var result: Array[int] = [target_slot]
	if (
		item != null
		and item.slot_type == EquipmentData.EquipmentSlotType.WEAPON
		and item.weapon_rule == EquipmentData.WeaponRule.TWO_HANDED
	):
		result = [Slot.MAIN_WEAPON, Slot.SUB_WEAPON]
	return result
