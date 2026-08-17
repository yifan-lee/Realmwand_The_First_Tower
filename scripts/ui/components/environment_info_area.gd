class_name EnvironmentInfoArea
extends Control

@onready var info_hud: FloorInfoHUD = $FloorInfoHUD


func _ready() -> void:
	EventBus.screen_fade_in_with_info_started.connect(_on_screen_fade_in_with_info_started)
	# Set initial resting position aligned with bottom border
	await get_tree().process_frame
	if is_instance_valid(info_hud):
		info_hud.position = Vector2(0.0, -info_hud.size.y)


func _on_screen_fade_in_with_info_started(floor_name: String, floor_desc: String) -> void:
	info_hud.set_info(floor_name, floor_desc)
	
	# Wait one frame for the PanelContainer to recalculate its height based on the new text
	await get_tree().process_frame
	
	var resting_pos := Vector2(0.0, -info_hud.size.y)
	info_hud.scale = Vector2(1.5, 1.5)
	var screen_size := get_viewport().get_visible_rect().size
	var target_center := (
		(screen_size - info_hud.size * info_hud.scale) / 2.0
		- global_position
	)
	info_hud.position = target_center

	var tween := create_tween()
	
	# Wait in the center for 1.5 seconds
	tween.tween_interval(1.5)
	
	# Shrink and move to fixed bottom-left resting position
	tween.tween_property(info_hud, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(info_hud, "position", resting_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): EventBus.screen_fade_in_finished.emit())
