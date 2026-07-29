class_name TrackedItemCountRow
extends HBoxContainer

@onready var icon_rect: TextureRect = $Icon
@onready var name_label: Label = $NameLabel
@onready var count_label: Label = $CountLabel


func setup(item: ItemData, count: int) -> void:
	icon_rect.texture = item.icon
	icon_rect.visible = item.icon != null
	name_label.text = item.display_name
	count_label.text = "×%d" % count
