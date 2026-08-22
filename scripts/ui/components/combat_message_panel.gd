class_name CombatMessagePanel
extends Control

@export var max_messages: int = 5
@export var message_lifetime: float = 3.8
@export var fade_in_time: float = 0.15
@export var fade_out_time: float = 0.4

@onready var message_container: VBoxContainer = $Margin/MessageContainer

var _active_entries: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Margin"):
		$Margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if message_container != null:
		message_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


func push_message(message: String) -> void:
	if message.strip_edges().is_empty():
		return

	if message_container == null:
		return

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Lightweight sleek translucent stylebox
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.10, 0.72)
	style.border_color = Color(0.20, 0.29, 0.32, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", 17)
	label.add_theme_color_override("default_color", UIColors.TEXT_MAIN)
	
	var bbcode_content := message
	if not bbcode_content.begins_with("["):
		bbcode_content = "[color=#%s]%s[/color]" % [UIColors.TEXT_MAIN.to_html(false), bbcode_content]
	
	label.text = "[center]%s[/center]" % bbcode_content
	panel.add_child(label)

	panel.modulate.a = 0.0
	message_container.add_child(panel)

	var entry := {
		"node": panel,
		"tween": null,
		"is_fading_out": false
	}
	_active_entries.append(entry)

	# Enter & lifetime animation
	var tween := create_tween()
	entry["tween"] = tween
	tween.tween_property(panel, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(message_lifetime)
	tween.tween_property(panel, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func(): _remove_entry(entry))

	_trim_excess()


func _trim_excess() -> void:
	while _active_entries.size() > max_messages:
		var oldest = _active_entries[0]
		if not oldest["is_fading_out"]:
			oldest["is_fading_out"] = true
			if oldest["tween"] != null and is_instance_valid(oldest["tween"]):
				oldest["tween"].kill()
			var fast_tween := create_tween()
			fast_tween.tween_property(oldest["node"], "modulate:a", 0.0, 0.15)
			fast_tween.tween_callback(func(): _remove_entry(oldest))
		break


func _remove_entry(entry: Dictionary) -> void:
	_active_entries.erase(entry)
	if is_instance_valid(entry["node"]):
		entry["node"].queue_free()


func clear_all() -> void:
	for entry in _active_entries:
		if entry["tween"] != null and is_instance_valid(entry["tween"]):
			entry["tween"].kill()
		if is_instance_valid(entry["node"]):
			entry["node"].queue_free()
	_active_entries.clear()
