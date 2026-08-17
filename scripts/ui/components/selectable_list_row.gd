class_name SelectableListRow
extends Button

signal entry_selected(entry: Resource)
signal entry_focused(entry: Resource)

var entry_data: Resource
var entry: Resource:
	get:
		return entry_data
	set(value):
		entry_data = value


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	focus_entered.connect(_emit_focused)
	mouse_entered.connect(grab_focus)


func setup(
	p_entry: Resource,
	entry_text: String,
	entry_icon: Texture2D,
	entry_tooltip: String,
	is_disabled: bool = false
) -> void:
	entry_data = p_entry
	text = entry_text
	icon = entry_icon if entry_icon != null else (p_entry.get("icon") as Texture2D if p_entry != null and "icon" in p_entry else null)
	tooltip_text = entry_tooltip
	disabled = is_disabled
	focus_mode = Control.FOCUS_ALL


func _pressed() -> void:
	entry_selected.emit(entry_data)


func _emit_focused() -> void:
	entry_focused.emit(entry_data)
