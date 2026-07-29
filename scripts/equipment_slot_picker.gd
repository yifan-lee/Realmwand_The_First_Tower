class_name EquipmentSlotPicker
extends PanelContainer

signal slot_selected(slot: int)
signal slot_focused(slot: int)
signal focus_cleared
signal cancelled

@onready var title_label: Label = (
	$MarginContainer/Content/TitleLabel
)
@onready var left_button: Button = (
	$MarginContainer/Content/HandButtons/LeftButton
)
@onready var right_button: Button = (
	$MarginContainer/Content/HandButtons/RightButton
)


func _ready() -> void:
	left_button.pressed.connect(
		_on_slot_selected.bind(
			EquipmentManager.EquipmentSlot.LEFT_HAND
		)
	)
	right_button.pressed.connect(
		_on_slot_selected.bind(
			EquipmentManager.EquipmentSlot.RIGHT_HAND
		)
	)
	left_button.focus_entered.connect(
		_on_slot_focused.bind(
			EquipmentManager.EquipmentSlot.LEFT_HAND
		)
	)
	right_button.focus_entered.connect(
		_on_slot_focused.bind(
			EquipmentManager.EquipmentSlot.RIGHT_HAND
		)
	)
	left_button.mouse_entered.connect(
		_on_slot_focused.bind(
			EquipmentManager.EquipmentSlot.LEFT_HAND
		)
	)
	right_button.mouse_entered.connect(
		_on_slot_focused.bind(
			EquipmentManager.EquipmentSlot.RIGHT_HAND
		)
	)
	left_button.mouse_exited.connect(
		_queue_focus_clear_check
	)
	right_button.mouse_exited.connect(
		_queue_focus_clear_check
	)


func open(item: EquipmentData) -> void:
	title_label.text = "Equip %s to:" % item.display_name
	visible = true
	left_button.call_deferred("grab_focus")


func close() -> void:
	visible = false
	focus_cleared.emit()


func _on_slot_selected(slot: int) -> void:
	slot_selected.emit(slot)


func _on_slot_focused(slot: int) -> void:
	slot_focused.emit(slot)


func _queue_focus_clear_check() -> void:
	call_deferred("_emit_focus_cleared_if_needed")


func _emit_focus_cleared_if_needed() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner()

	if (
		focus_owner != null
		and is_ancestor_of(focus_owner)
	):
		return

	focus_cleared.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return

	var focus_owner := get_viewport().gui_get_focus_owner()

	if focus_owner == null or not is_ancestor_of(focus_owner):
		return

	cancelled.emit()
	get_viewport().set_input_as_handled()
