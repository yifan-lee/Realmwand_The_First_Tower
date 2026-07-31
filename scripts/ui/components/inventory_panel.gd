class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)

@export var row_scene: PackedScene

@onready var item_rows: VBoxContainer = (
	$MarginContainer/Content/ItemScroll/ItemRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _inventory: Inventory


func bind_inventory(inventory: Inventory) -> void:
	if _inventory != null:
		if _inventory.inventory_changed.is_connected(refresh):
			_inventory.inventory_changed.disconnect(refresh)

	_inventory = inventory

	if _inventory != null:
		_inventory.inventory_changed.connect(refresh)

	refresh()


func refresh() -> void:
	for child: Node in item_rows.get_children():
		item_rows.remove_child(child)
		child.queue_free()

	if _inventory == null:
		empty_label.visible = true
		return

	var items: Array[ItemData] = _inventory.get_all_items()
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


func _sort_items(
	left: ItemData,
	right: ItemData
) -> bool:
	return left.display_name < right.display_name


func _on_entry_selected(entry: Resource) -> void:
	var item: ItemData = entry as ItemData

	if item != null:
		item_selected.emit(item)
