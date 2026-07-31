class_name SelectableListRow
extends Button

signal entry_selected(entry: Resource)
signal entry_focused(entry: Resource)

var entry_data: Resource


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_emit_focused)
	mouse_entered.connect(grab_focus)


func setup(
	entry: Resource,
	entry_text: String,
	entry_icon: Texture2D,
	entry_tooltip: String
) -> void:
	entry_data = entry

	if entry_data == null:
		text = ""
		icon = null
		tooltip_text = ""
		disabled = true
		return

	text = entry_text
	icon = entry_icon
	tooltip_text = entry_tooltip
	disabled = false


func _pressed() -> void:
	if entry_data != null:
		entry_selected.emit(entry_data)


func _emit_focused() -> void:
	if entry_data != null:
		entry_focused.emit(entry_data)
