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

	if is_instance_valid(current_floor):
		floor_container.remove_child(current_floor)
		current_floor.queue_free()

	current_floor = new_floor
	current_floor_id = target_floor_id
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