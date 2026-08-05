class_name SaveSlotRow
extends PanelContainer

signal load_requested(slot_id: String)
signal overwrite_requested(slot_id: String)
signal delete_requested(slot_id: String)

@onready var name_label: Label = $Margin/Content/Info/NameLabel
@onready var detail_label: Label = $Margin/Content/Info/DetailLabel
@onready var load_button: Button = $Margin/Content/LoadButton
@onready var overwrite_button: Button = $Margin/Content/OverwriteButton
@onready var delete_button: Button = $Margin/Content/DeleteButton

var slot_id := ""
var _delete_armed := false


func _ready() -> void:
	load_button.pressed.connect(_on_load_pressed)
	overwrite_button.pressed.connect(_on_overwrite_pressed)
	delete_button.pressed.connect(_on_delete_pressed)


func display_save(data: Dictionary) -> void:
	slot_id = String(data.get("slot_id", ""))
	name_label.text = String(data.get("display_name", "未命名存档"))
	detail_label.text = "%s · %s" % [
		String(data.get("floor_id", "未知楼层")),
		String(data.get("saved_at", "")),
	]
	_reset_delete_confirmation()


func focus_first_button() -> void:
	load_button.grab_focus()


func _on_load_pressed() -> void:
	_reset_delete_confirmation()
	load_requested.emit(slot_id)


func _on_overwrite_pressed() -> void:
	_reset_delete_confirmation()
	overwrite_requested.emit(slot_id)


func _on_delete_pressed() -> void:
	if not _delete_armed:
		_delete_armed = true
		delete_button.text = "再次确认"
		return
	delete_requested.emit(slot_id)


func _reset_delete_confirmation() -> void:
	_delete_armed = false
	delete_button.text = "删除"
