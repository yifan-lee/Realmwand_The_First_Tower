class_name InventoryMenu
extends PanelContainer

signal item_selected(item: ItemData)
signal item_focused(item: ItemData)
signal item_focus_cleared
signal cancelled

const CATEGORIES: Array[ItemData.ItemType] = [
	ItemData.ItemType.CONSUMABLE,
	ItemData.ItemType.EQUIPMENT,
	ItemData.ItemType.KEY_ITEM,
	ItemData.ItemType.MATERIAL,
]

@onready var category_list: VBoxContainer = (
	$MarginContainer/Content/Columns/CategoryList
)
@onready var item_list: VBoxContainer = (
	$MarginContainer/Content/Columns/ItemScroll/ItemList
)

var items: Array[ItemData] = []
var category_buttons: Dictionary = {}
var active_category: ItemData.ItemType = ItemData.ItemType.CONSUMABLE
var active_category_button: Button
var first_item_button: Button
var hovered_item_button: Button
var equipment_manager: EquipmentManager


func open(
	source_items: Array[ItemData],
	focus_first_category: bool = false,
	source_equipment_manager: EquipmentManager = null
) -> void:
	items = source_items
	equipment_manager = source_equipment_manager
	_build_categories()
	_select_category(active_category)
	visible = true

	if focus_first_category:
		grab_first_category_focus()


func close() -> void:
	hovered_item_button = null
	visible = false
	item_focus_cleared.emit()


func grab_first_category_focus() -> void:
	var first_button := (
		category_buttons.get(CATEGORIES[0]) as Button
	)

	if is_instance_valid(first_button):
		first_button.call_deferred("grab_focus")


func grab_first_item_focus() -> void:
	_focus_first_item()


func _build_categories() -> void:
	for child in category_list.get_children():
		category_list.remove_child(child)
		child.queue_free()

	category_buttons.clear()

	for category in CATEGORIES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.add_theme_font_size_override("font_size", 28)
		button.text = _get_category_name(category)
		button.focus_entered.connect(
			_on_category_focused.bind(category, button)
		)
		button.mouse_entered.connect(
			_on_category_focused.bind(category, button)
		)
		button.pressed.connect(
			_on_category_pressed.bind(category, button)
		)
		category_list.add_child(button)
		category_buttons[category] = button


func _select_category(category: ItemData.ItemType) -> void:
	active_category = category
	active_category_button = (
		category_buttons.get(category) as Button
	)
	first_item_button = null
	hovered_item_button = null
	_clear_item_buttons()

	var item_counts: Dictionary = {}
	var category_items: Dictionary = {}

	for item in items:
		if item.item_type != category:
			continue

		item_counts[item.id] = int(item_counts.get(item.id, 0)) + 1
		category_items[item.id] = item

	for item_id in category_items:
		var item := category_items[item_id] as ItemData
		var count := int(item_counts[item_id])
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.add_theme_font_size_override("font_size", 28)
		button.text = item.display_name

		if count > 1:
			button.text += "  x%d" % count

		if item is EquipmentData and equipment_manager != null:
			var equipped_text := (
				equipment_manager.get_equipped_slot_text(
					item as EquipmentData
				)
			)

			if not equipped_text.is_empty():
				button.text += "  [%s]" % equipped_text

		button.pressed.connect(
			_on_item_button_pressed.bind(item)
		)
		button.focus_entered.connect(
			_on_item_button_focused.bind(item)
		)
		button.focus_exited.connect(
			_queue_item_focus_clear_check
		)
		button.mouse_entered.connect(
			_on_item_button_mouse_entered.bind(
				button,
				item
			)
		)
		button.mouse_exited.connect(
			_on_item_button_mouse_exited.bind(button)
		)
		item_list.add_child(button)

		if first_item_button == null:
			first_item_button = button

	if first_item_button == null:
		var empty_label := Label.new()
		empty_label.text = "Empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 28)
		item_list.add_child(empty_label)


func _clear_item_buttons() -> void:
	for child in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()


func _get_category_name(category: ItemData.ItemType) -> String:
	match category:
		ItemData.ItemType.CONSUMABLE:
			return "Potions"
		ItemData.ItemType.EQUIPMENT:
			return "Equipment"
		ItemData.ItemType.KEY_ITEM:
			return "Key Items"
		ItemData.ItemType.MATERIAL:
			return "Materials"

	return "Key Items"


func _on_category_focused(
	category: ItemData.ItemType,
	button: Button
) -> void:
	active_category_button = button

	if category != active_category:
		_select_category(category)

	item_focus_cleared.emit()


func _on_category_pressed(
	category: ItemData.ItemType,
	button: Button
) -> void:
	_on_category_focused(category, button)
	_focus_first_item()


func _focus_first_item() -> void:
	if is_instance_valid(first_item_button):
		first_item_button.call_deferred("grab_focus")


func _on_item_button_pressed(item: ItemData) -> void:
	item_selected.emit(item)


func _on_item_button_focused(item: ItemData) -> void:
	item_focused.emit(item)


func _on_item_button_mouse_entered(
	button: Button,
	item: ItemData
) -> void:
	hovered_item_button = button
	item_focused.emit(item)


func _on_item_button_mouse_exited(button: Button) -> void:
	if hovered_item_button == button:
		hovered_item_button = null

	_queue_item_focus_clear_check()


func _queue_item_focus_clear_check() -> void:
	call_deferred("_emit_item_focus_cleared_if_needed")


func _emit_item_focus_cleared_if_needed() -> void:
	if hovered_item_button != null:
		return

	var focus_owner := get_viewport().gui_get_focus_owner()

	if (
		focus_owner != null
		and item_list.is_ancestor_of(focus_owner)
	):
		return

	item_focus_cleared.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return

	var focus_owner := get_viewport().gui_get_focus_owner()
	var focus_is_in_categories := (
		focus_owner != null
		and category_list.is_ancestor_of(focus_owner)
	)
	var focus_is_in_items := (
		focus_owner != null
		and item_list.is_ancestor_of(focus_owner)
	)

	if (
		event.is_action_pressed("ui_cancel")
		and (
			focus_is_in_categories
			or focus_is_in_items
		)
	):
		cancelled.emit()
		get_viewport().set_input_as_handled()
	elif (
		event.is_action_pressed("ui_right")
		and focus_is_in_categories
	):
		_focus_first_item()
		get_viewport().set_input_as_handled()
	elif (
		event.is_action_pressed("ui_left")
		and focus_is_in_items
		and is_instance_valid(active_category_button)
	):
		active_category_button.grab_focus()
		get_viewport().set_input_as_handled()
