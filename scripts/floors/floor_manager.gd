class_name FloorManager
extends Node

const FLOOR_SCENE_DIRECTORY := "res://scenes/floors"

@export_group("Startup")
@export var starting_floor_id: StringName = &"floor_1"
@export var starting_spawn_id: StringName = &"FromStart"

@onready var floor_container: Node2D = %FloorContainer
@onready var player: Player = %Player

var current_floor: Floor
var current_floor_id: StringName = &""
var floor_states: Dictionary = {}

var _is_changing_floor: bool = false


func _ready() -> void:
	EventBus.floor_change_requested.connect(
		_on_floor_change_requested
	)

	call_deferred(
		"change_floor",
		starting_floor_id,
		starting_spawn_id
	)


func _instantiate_floor(target_floor_id: StringName) -> Floor:
	if target_floor_id == &"":
		push_error("Cannot load a floor with an empty ID.")
		return null

	var floor_path := (
		"%s/%s.tscn"
		% [
			FLOOR_SCENE_DIRECTORY,
			String(target_floor_id),
		]
	)

	if not ResourceLoader.exists(floor_path):
		push_error(
			"Floor scene does not exist: %s"
			% floor_path
		)
		return null

	var floor_scene := ResourceLoader.load(
		floor_path,
		"PackedScene"
	) as PackedScene

	if floor_scene == null:
		push_error(
			"Failed to load floor scene: %s"
			% floor_path
		)
		return null

	var new_floor := floor_scene.instantiate() as Floor

	if new_floor == null:
		push_error(
			"Floor scene root must inherit Floor: %s"
			% floor_path
		)
		return null

	if new_floor.floor_id != target_floor_id:
		push_error(
			"Floor ID '%s' does not match requested ID '%s'."
			% [
				new_floor.floor_id,
				target_floor_id,
			]
		)
		new_floor.queue_free()
		return null
		
	return new_floor


func _set_current_floor(new_floor: Floor) -> void:
	store_current_floor_state()

	if is_instance_valid(current_floor) and current_floor != new_floor:
		floor_container.remove_child(current_floor)
		current_floor.queue_free()

	if new_floor.get_parent() != floor_container:
		if new_floor.get_parent() != null:
			new_floor.get_parent().remove_child(new_floor)
		floor_container.add_child(new_floor)

	current_floor = new_floor
	current_floor_id = new_floor.floor_id

	_apply_saved_floor_state(current_floor)
	EventBus.floor_changed.emit(current_floor)


func change_floor(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	if _is_changing_floor:
		return
	_is_changing_floor = true
	
	player.lock_movement(&"floor_transition")
	
	EventBus.screen_fade_out_started.emit()
	await EventBus.screen_fade_out_finished

	# 同层传送分支：target_floor_id 为空 或 与当前楼层相同
	if target_floor_id.is_empty() or (is_instance_valid(current_floor) and target_floor_id == current_floor.floor_id):
		var spawn_point := current_floor.get_spawn_point(target_spawn_id)
		var f_name = current_floor.get("display_name")
		var f_desc = current_floor.get("description")
		player.global_position = spawn_point.global_position
		EventBus.screen_fade_in_with_info_started.emit(f_name, f_desc)
		await EventBus.screen_fade_in_finished
		player.unlock_movement(&"floor_transition")
		_is_changing_floor = false
		return

	# 跨层传送分支
	var new_floor := _instantiate_floor(target_floor_id)
	if new_floor == null:
		EventBus.screen_fade_in_with_info_started.emit("", "")
		await EventBus.screen_fade_in_finished
		player.unlock_movement(&"floor_transition")
		_is_changing_floor = false
		return

	# Add to tree temporarily to safely resolve node paths (like markers)
	floor_container.add_child(new_floor)

	var spawn_point := new_floor.get_spawn_point(
		target_spawn_id
	)

	if spawn_point == null:
		floor_container.remove_child(new_floor)
		new_floor.queue_free()
		EventBus.screen_fade_in_with_info_started.emit("", "")
		await EventBus.screen_fade_in_finished
		player.unlock_movement(&"floor_transition")
		_is_changing_floor = false
		return


	_set_current_floor(new_floor)
	
	player.global_position = spawn_point.global_position

	var f_name = new_floor.get("display_name") if "display_name" in new_floor else ""
	var f_desc = new_floor.get("description") if "description" in new_floor else ""
	EventBus.screen_fade_in_with_info_started.emit(f_name, f_desc)
	await EventBus.screen_fade_in_finished

	player.unlock_movement(&"floor_transition")
	_is_changing_floor = false


func _on_floor_change_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	change_floor(
		target_floor_id,
		target_spawn_id
	)


func store_current_floor_state() -> void:
	if not is_instance_valid(current_floor):
		return

	var floor_key := String(current_floor.floor_id)

	floor_states[floor_key] = (
		current_floor.capture_runtime_state()
	)


func capture_save_data() -> Dictionary:
	store_current_floor_state()
	var local_position := Vector2.ZERO
	if is_instance_valid(current_floor):
		local_position = current_floor.to_local(player.global_position)
	return {
		"current_floor_id": String(current_floor_id),
		"player_local_position": [local_position.x, local_position.y],
		"floor_states": floor_states.duplicate(true),
	}


func can_restore_save_data(data: Dictionary) -> bool:
	var floor_id := StringName(String(data.get("current_floor_id", "")))
	if floor_id.is_empty():
		return false
	var states_value: Variant = data.get("floor_states", {})
	if not (states_value is Dictionary):
		return false

	var test_floor := _instantiate_floor(floor_id)
	if test_floor == null:
		return false
	test_floor.queue_free()
	return true


func restore_save_data(data: Dictionary) -> bool:
	var floor_id := StringName(String(data.get("current_floor_id", "")))
	if floor_id.is_empty():
		return false
	var states_value: Variant = data.get("floor_states", {})
	if not (states_value is Dictionary):
		return false

	var new_floor := _instantiate_floor(floor_id)
	if new_floor == null:
		return false

	player.lock_movement(&"floor_transition")
	
	# Clear out current floor before applying state
	if is_instance_valid(current_floor):
		floor_container.remove_child(current_floor)
		current_floor.queue_free()
	current_floor = null
	current_floor_id = &""
	
	floor_states = states_value.duplicate(true)

	_set_current_floor(new_floor)

	var position_value: Variant = data.get("player_local_position", [])
	if position_value is Array and position_value.size() >= 2:
		var local_position := Vector2(float(position_value[0]), float(position_value[1]))
		player.global_position = current_floor.to_global(local_position)
	
	player.unlock_movement(&"floor_transition")
	return true


func _apply_saved_floor_state(
	floor: Floor
) -> void:
	var floor_key := String(floor.floor_id)

	if not floor_states.has(floor_key):
		return

	var saved_state: Dictionary = floor_states[floor_key]

	floor.apply_runtime_state(saved_state)
