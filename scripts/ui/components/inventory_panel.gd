class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)
signal item_focused(item: ItemData)

@export var row_scene: PackedScene

@onready var item_rows: VBoxContainer = (
	$MarginContainer/Content/ItemScroll/ItemRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _inventory: Inventory
var _item_type_filter: int = -1
var _battle_only: bool = false
var _rows: Array[SelectableListRow] = []


func bind_inventory(inventory: Inventory) -> void:
	if _inventory != null:
		if _inventory.inventory_changed.is_connected(refresh):
			_inventory.inventory_changed.disconnect(refresh)

	_inventory = inventory

	if _inventory != null:
		_inventory.inventory_changed.connect(refresh)

	refresh()


func refresh() -> void:
	var focused_index := _focused_row_index(get_viewport().gui_get_focus_owner())
	_rows.clear()
	for child: Node in item_rows.get_children():
		item_rows.remove_child(child)
		child.queue_free()

	if _inventory == null:
		empty_label.visible = true
		return

	var items: Array[ItemData] = _inventory.get_all_items()
	items = items.filter(_matches_filter)
	items.sort_custom(_sort_items)

	empty_label.visible = items.is_empty()

	for item: ItemData in items:
		var row: SelectableListRow = (
			row_scene.instantiate()
			as SelectableListRow
		)

		if row == null:
			push_error("InventoryPanel row_scene has an invalid root.")
			return

		item_rows.add_child(row)
		_rows.append(row)
		row.setup(
			item,
			"%s  ×%d" % [
				item.display_name,
				_inventory.get_quantity(item.id),
			],
			item.icon,
			item.description
		)
		row.entry_selected.connect(_on_entry_selected)
		row.entry_focused.connect(_on_entry_focused)

	if focused_index >= 0:
		var target_index := clampi(focused_index, 0, _rows.size() - 1)
		if target_index >= 0 and target_index < _rows.size():
			_rows[target_index].grab_focus()


func set_item_type_filter(item_type: int) -> void:
	_item_type_filter = item_type
	refresh()


func clear_filter() -> void:
	set_item_type_filter(-1)


func set_battle_only(enabled: bool) -> void:
	_battle_only = enabled
	refresh()


func focus_first_item() -> bool:
	if _rows.is_empty():
		return false
	_rows.front().grab_focus()
	return true


func is_first_item_focused() -> bool:
	return (
		not _rows.is_empty()
		and get_viewport().gui_get_focus_owner() == _rows.front()
	)


func has_item_focus(focus: Control = null) -> bool:
	var resolved_focus := focus
	if resolved_focus == null:
		resolved_focus = get_viewport().gui_get_focus_owner()
	return _focused_row_index(resolved_focus) >= 0


func navigate_item_focus(direction: int) -> bool:
	var current_index := _focused_row_index(
		get_viewport().gui_get_focus_owner()
	)
	if current_index < 0:
		return false
	var next_index := clampi(
		current_index + direction,
		0,
		_rows.size() - 1
	)
	_rows[next_index].grab_focus()
	return true


func _focused_row_index(focus: Control) -> int:
	for index: int in _rows.size():
		if focus == _rows[index]:
			return index
	return -1


func _matches_filter(item: ItemData) -> bool:
	if _battle_only and not item.usable_in_battle:
		return false
	return _item_type_filter < 0 or item.item_type == _item_type_filter


func _sort_items(
	left: ItemData,
	right: ItemData
) -> bool:
	return left.display_name < right.display_name


func _on_entry_selected(entry: Resource) -> void:
	var item: ItemData = entry as ItemData

	if item != null:
		item_selected.emit(item)


func _on_entry_focused(entry: Resource) -> void:
	var item: ItemData = entry as ItemData
	if item != null:
		item_focused.emit(item)
