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


func _ready() -> void:
	EventBus.floor_change_requested.connect(
		_on_floor_change_requested
	)

	change_floor(
		starting_floor_id,
		starting_spawn_id
	)


func change_floor(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	if target_floor_id == &"":
		push_error("Cannot load a floor with an empty ID.")
		return

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
		return

	var floor_scene := ResourceLoader.load(
		floor_path,
		"PackedScene"
	) as PackedScene

	if floor_scene == null:
		push_error(
			"Failed to load floor scene: %s"
			% floor_path
		)
		return

	# Runtime-only: the requested floor is only known during play.
	var new_floor := floor_scene.instantiate() as Floor

	if new_floor == null:
		push_error(
			"Floor scene root must inherit Floor: %s"
			% floor_path
		)
		return

	if new_floor.floor_id != target_floor_id:
		push_error(
			"Floor ID '%s' does not match requested ID '%s'."
			% [
				new_floor.floor_id,
				target_floor_id,
			]
		)
		new_floor.queue_free()
		return

	floor_container.add_child(new_floor)

	var spawn_point := new_floor.get_spawn_point(
		target_spawn_id
	)

	if spawn_point == null:
		floor_container.remove_child(new_floor)
		new_floor.queue_free()
		return

	player.set_input_enabled(false)

	store_current_floor_state()

	if is_instance_valid(current_floor):
		floor_container.remove_child(current_floor)
		current_floor.queue_free()

	current_floor = new_floor
	current_floor_id = target_floor_id

	_apply_saved_floor_state(current_floor)

	
	player.global_position = spawn_point.global_position

	player.set_input_enabled(true)


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


func restore_save_data(data: Dictionary) -> bool:
	var floor_id := StringName(String(data.get("current_floor_id", "")))
	if floor_id.is_empty():
		return false
	var states_value: Variant = data.get("floor_states", {})
	if not (states_value is Dictionary):
		return false
	player.set_input_enabled(false)
	if is_instance_valid(current_floor):
		floor_container.remove_child(current_floor)
		current_floor.queue_free()
	current_floor = null
	current_floor_id = &""
	floor_states = states_value.duplicate(true)
	change_floor(floor_id, &"")
	if not is_instance_valid(current_floor):
		player.set_input_enabled(true)
		return false
	var position_value: Variant = data.get("player_local_position", [])
	if position_value is Array and position_value.size() >= 2:
		var local_position := Vector2(float(position_value[0]), float(position_value[1]))
		player.global_position = current_floor.to_global(local_position)
	player.set_input_enabled(true)
	return true

func _apply_saved_floor_state(
	floor: Floor
) -> void:
	var floor_key := String(floor.floor_id)

	if not floor_states.has(floor_key):
		return

	var saved_state: Dictionary = floor_states[floor_key]

	floor.apply_runtime_state(saved_state)
