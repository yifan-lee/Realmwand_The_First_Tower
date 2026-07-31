class_name TrackedItemRow
extends HBoxContainer

@export var item: ItemData

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var quantity_label: Label = %QuantityLabel

var _inventory: Inventory


func _ready() -> void:
	refresh()


func bind_inventory(
	inventory: Inventory
) -> void:
	if _inventory != null:
		if _inventory.inventory_changed.is_connected(
			refresh
		):
			_inventory.inventory_changed.disconnect(
				refresh
			)

	_inventory = inventory

	if _inventory != null:
		_inventory.inventory_changed.connect(refresh)

	refresh()


func refresh() -> void:
	if item == null:
		visible = false
		return

	visible = true

	icon_rect.texture = item.icon
	name_label.text = item.display_name

	var quantity: int = 0

	if _inventory != null:
		quantity = _inventory.get_quantity(item.id)

	quantity_label.text = "×%d" % quantity