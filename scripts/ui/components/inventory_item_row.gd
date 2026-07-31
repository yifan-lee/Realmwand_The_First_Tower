class_name InventoryItemRow
extends Button

signal item_selected(item: ItemData)

var item_data: ItemData


func setup(item: ItemData, amount: int) -> void:
	item_data = item

	if item_data == null:
		text = ""
		icon = null
		disabled = true
		return

	text = "%s  ×%d" % [
		item_data.display_name,
		amount,
	]
	icon = item_data.icon
	tooltip_text = item_data.description
	disabled = false


func _pressed() -> void:
	if item_data != null:
		item_selected.emit(item_data)