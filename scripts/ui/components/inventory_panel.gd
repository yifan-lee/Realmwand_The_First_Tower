class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)

@export var item_row_scene: PackedScene

@onready var item_rows: VBoxContainer = %ItemRows
@onready var empty_label: Label = %EmptyLabel

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
		var row: InventoryItemRow = (
			item_row_scene.instantiate()
			as InventoryItemRow
		)

		if row == null:
			push_error("InventoryPanel item_row_scene has an invalid root.")
			return

		item_rows.add_child(row)
		row.setup(
			item,
			_inventory.get_quantity(item.id)
		)
		row.item_selected.connect(_on_item_selected)


func _sort_items(
	left: ItemData,
	right: ItemData
) -> bool:
	return left.display_name < right.display_name


func _on_item_selected(item: ItemData) -> void:
	item_selected.emit(item)