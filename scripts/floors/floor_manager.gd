class_name FloorManager
extends Node2D


signal battle_requested(enemy: WorldEnemy)
signal floor_changed(
	floor_id: StringName,
	spawn_id: StringName
)

const FLOOR_SCENE_PATH_PATTERN := (
	"res://scenes/floors/%s.tscn"
)

@export var initial_floor_id: StringName = &"floor_1"
@export var initial_spawn_id: StringName = &"GameStart"

@onready var floor_container: Node2D = $"../FloorContainer"
@onready var player: Player = $"../Player"

var current_floor_id: StringName
var current_floor: Floor
var floor_states: Dictionary = {}
var is_transitioning: bool = false


func initialize() -> void:
	await change_floor(
		initial_floor_id,
		initial_spawn_id
	)


func change_floor(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	await player.wait_for_current_movement()

	if current_floor != null:
		floor_states[current_floor_id] = (
			current_floor.capture_runtime_state()
		)
		var departing_floor := current_floor
		current_floor = null
		departing_floor.queue_free()
		await departing_floor.tree_exited

	var floor_scene := _load_floor_scene(
		target_floor_id
	)

	current_floor = (
		floor_scene.instantiate() as Floor
	)
	assert(
		current_floor != null,
		"Floor scene root must use Floor or a subclass"
	)
	assert(
		current_floor.floor_id == target_floor_id,
		(
			"Floor scene id mismatch: requested %s, scene uses %s"
			% [target_floor_id, current_floor.floor_id]
		)
	)

	current_floor.disarm_transitions()
	floor_container.add_child(current_floor)
	current_floor.transition_requested.connect(
		_on_transition_requested
	)
	current_floor.battle_requested.connect(
		_on_floor_battle_requested
	)

	if floor_states.has(target_floor_id):
		current_floor.restore_runtime_state(
			floor_states[target_floor_id]
		)

	var spawn_point := current_floor.get_spawn_point(
		target_spawn_id
	)
	player.global_position = spawn_point.global_position
	current_floor_id = target_floor_id

	await get_tree().physics_frame
	await get_tree().physics_frame
	current_floor.arm_transitions_after_arrival(
		player
	)

	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	is_transitioning = false
	floor_changed.emit(
		current_floor_id,
		target_spawn_id
	)


func record_enemy_defeated(enemy: WorldEnemy) -> void:
	if current_floor == null or enemy == null:
		return

	current_floor.record_removed_object(
		enemy.get_floor_state_id()
	)


func _load_floor_scene(
	floor_id: StringName
) -> PackedScene:
	var floor_scene_path := (
		FLOOR_SCENE_PATH_PATTERN
		% String(floor_id)
	)
	assert(
		ResourceLoader.exists(
			floor_scene_path,
			"PackedScene"
		),
		"Unknown floor id: %s" % floor_id
	)

	var floor_scene := load(
		floor_scene_path
	) as PackedScene
	assert(
		floor_scene != null,
		"Failed to load floor scene: %s"
		% floor_scene_path
	)
	return floor_scene


func _on_transition_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	change_floor.call_deferred(
		target_floor_id,
		target_spawn_id
	)


func _on_floor_battle_requested(
	enemy: WorldEnemy
) -> void:
	battle_requested.emit(enemy)
