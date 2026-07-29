class_name EquipmentSlotsPanel
extends PanelContainer

@onready var slot_grid: GridContainer = (
	$MarginContainer/Content/SlotGrid
)

var equipment_manager: EquipmentManager


func set_equipment_manager(
	manager: EquipmentManager
) -> void:
	equipment_manager = manager
	refresh()


func refresh() -> void:
	for child in slot_grid.get_children():
		slot_grid.remove_child(child)
		child.queue_free()

	if equipment_manager == null:
		return

	for slot in EquipmentManager.EquipmentSlot.values():
		var slot_label := Label.new()
		slot_label.text = equipment_manager.get_slot_name(slot)
		slot_label.add_theme_font_size_override(
			"font_size",
			24
		)
		slot_grid.add_child(slot_label)

		var item_label := Label.new()
		var item := equipment_manager.get_item(slot)

		item_label.text = "-"

		if item != null:
			item_label.text = item.display_name

			if (
				item.hand_rule
				== EquipmentData.HandRule.TWO_HANDED
			):
				item_label.text += " (2H)"

		item_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_RIGHT
		)
		item_label.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)
		item_label.text_overrun_behavior = (
			TextServer.OVERRUN_TRIM_ELLIPSIS
		)
		item_label.add_theme_font_size_override(
			"font_size",
			24
		)
		slot_grid.add_child(item_label)
