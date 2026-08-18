class_name Inventory
extends Node

signal inventory_changed
signal item_added(item: ItemData, amount: int)
signal item_removed(item: ItemData, amount: int)

var _items: Dictionary[StringName, ItemData] = {}
var _quantities: Dictionary[StringName, int] = {}


func add_item(item: ItemData, amount: int = 1) -> int:
	if item == null or item.id.is_empty() or amount <= 0:
		return amount

	var current_amount := get_quantity(item.id)
	var accepted_amount := mini(
		amount,
		item.max_stack - current_amount
	)

	if accepted_amount <= 0:
		return amount

	_items[item.id] = item
	_quantities[item.id] = current_amount + accepted_amount

	item_added.emit(item, accepted_amount)
	inventory_changed.emit()

	return amount - accepted_amount


func remove_item(
	item_id: StringName,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	var current_amount := get_quantity(item_id)

	if current_amount < amount:
		return false

	var remaining_amount := current_amount - amount
	var item: ItemData = _items[item_id]

	if remaining_amount == 0:
		_items.erase(item_id)
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = remaining_amount

	item_removed.emit(item, amount)
	inventory_changed.emit()

	return true


func has_item(
	item_id: StringName,
	amount: int = 1
) -> bool:
	return get_quantity(item_id) >= amount


func get_quantity(item_id: StringName) -> int:
	return _quantities.get(item_id, 0)


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id)


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []

	for item: ItemData in _items.values():
		result.append(item)

	return result


func get_remaining_capacity(
	item: ItemData
) -> int:
	if item == null or item.id.is_empty():
		return 0

	return maxi(
		0,
		item.max_stack
		- get_quantity(item.id)
	)


func capture_save_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: ItemData in get_all_items():
		if item.resource_path.is_empty():
			continue
		result.append({
			"resource_path": item.resource_path,
			"quantity": get_quantity(item.id),
		})
	return result


func clear() -> void:
	_items.clear()
	_quantities.clear()
	inventory_changed.emit()


func restore_save_data(entries_value: Variant) -> void:
	_items.clear()
	_quantities.clear()
	if entries_value is Array:
		for entry_value: Variant in entries_value:
			if not (entry_value is Dictionary):
				continue
			var path := String(entry_value.get("resource_path", ""))
			var item := load(path) as ItemData
			if item != null:
				add_item(item, int(entry_value.get("quantity", 1)))
	inventory_changed.emit()

