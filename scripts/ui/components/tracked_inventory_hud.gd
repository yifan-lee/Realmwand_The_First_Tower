class_name TrackedInventoryHUD
extends PanelContainer

@onready var item_rows: VBoxContainer = %ItemRows

var _inventory: Inventory


func bind_inventory(
	inventory: Inventory
) -> void:
	_inventory = inventory

	for child: Node in item_rows.get_children():
		var row: TrackedItemRow = (
			child as TrackedItemRow
		)

		if row != null:
			row.bind_inventory(_inventory)