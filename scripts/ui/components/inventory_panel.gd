class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)
signal item_focused(item: ItemData)

@export var row_scene: PackedScene

@onready var item_rows: FocusableList = (
	$MarginContainer/Content/ItemScroll/ItemRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _inventory: Inventory
var _item_type_filter: int = -1
var _battle_only: bool = false


func bind_inventory(inventory: Inventory) -> void:
	if _inventory != null:
		if _inventory.inventory_changed.is_connected(refresh):
			_inventory.inventory_changed.disconnect(refresh)

	_inventory = inventory

	if _inventory != null:
		_inventory.inventory_changed.connect(refresh)

	refresh()


func refresh() -> void:
	var focused_index := item_rows.get_focused_row_index(get_viewport().gui_get_focus_owner())
	item_rows.clear_rows()

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

		item_rows.add_row(row)
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

	if focused_index >= 0 and not item_rows.is_empty():
		var target_index := clampi(focused_index, 0, item_rows.get_rows().size() - 1)
		item_rows.get_rows()[target_index].grab_focus()
	elif focused_index >= 0 and item_rows.is_empty():
		get_viewport().gui_release_focus()



func set_item_type_filter(item_type: int) -> void:
	_item_type_filter = item_type
	refresh()


func clear_filter() -> void:
	set_item_type_filter(-1)


func set_battle_only(enabled: bool) -> void:
	_battle_only = enabled
	refresh()


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
