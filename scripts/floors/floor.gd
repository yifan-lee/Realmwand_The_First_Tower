class_name Floor
extends Node2D


signal transition_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
)
signal battle_requested(enemy: WorldEnemy)

@export var floor_id: StringName
@export var display_name: String
@export_multiline var description: String

@onready var spawn_points: Node2D = $SpawnPoints

var runtime_state: Dictionary = {}


func _ready() -> void:
	for node: Node in find_children(
		"*",
		"WorldEnemy",
		true,
		false
	):
		var enemy := node as WorldEnemy
		if enemy != null:
			enemy.battle_requested.connect(
				_on_enemy_battle_requested
			)

	for node: Node in find_children(
		"*",
		"Pickup",
		true,
		false
	):
		if node.has_signal("collected"):
			node.collected.connect(
				_on_persistent_object_removed
			)

	for transition: FloorTransition in _get_transitions():
		transition.transition_requested.connect(
			request_transition
		)


func get_spawn_point(spawn_id: StringName) -> Marker2D:
	var spawn_point := spawn_points.get_node_or_null(
		NodePath(String(spawn_id))
	) as Marker2D

	assert(
		spawn_point != null,
		"Floor %s is missing spawn point %s"
		% [floor_id, spawn_id]
	)

	return spawn_point


func capture_runtime_state() -> Dictionary:
	var captured_state := runtime_state.duplicate(true)

	for node: Node in _get_persistent_nodes():
		var object_id: StringName = node.call(
			"get_floor_state_id"
		)
		captured_state[object_id] = node.call(
			"save_floor_state"
		)

	runtime_state = captured_state.duplicate(true)
	return captured_state


func restore_runtime_state(state: Dictionary) -> void:
	runtime_state = state.duplicate(true)

	for node: Node in _get_persistent_nodes():
		var object_id: StringName = node.call(
			"get_floor_state_id"
		)

		if not runtime_state.has(object_id):
			continue

		var object_state: Dictionary = (
			runtime_state[object_id]
		)

		if bool(object_state.get("removed", false)):
			node.queue_free()
			continue

		node.call(
			"restore_floor_state",
			object_state
		)


func record_removed_object(
	object_id: StringName
) -> void:
	runtime_state[object_id] = {
		"removed": true,
	}


func disarm_transitions() -> void:
	for transition: FloorTransition in _get_transitions():
		transition.disarm()


func arm_transitions_after_arrival(
	player: Player
) -> void:
	for transition: FloorTransition in _get_transitions():
		if transition.should_suppress_at_arrival(
			player
		):
			transition.suppress_until_body_exits(
				player
			)
		else:
			transition.arm()


func request_transition(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	transition_requested.emit(
		target_floor_id,
		target_spawn_id
	)


func _get_persistent_nodes() -> Array[Node]:
	var persistent_nodes: Array[Node] = []

	for node: Node in find_children(
		"*",
		"",
		true,
		false
	):
		if (
			node.has_method("get_floor_state_id")
			and node.has_method("save_floor_state")
			and node.has_method("restore_floor_state")
		):
			persistent_nodes.append(node)

	return persistent_nodes


func _get_transitions() -> Array[FloorTransition]:
	var transitions: Array[FloorTransition] = []

	for node: Node in find_children(
		"*",
		"FloorTransition",
		true,
		false
	):
		var transition := node as FloorTransition
		if transition != null:
			transitions.append(transition)

	return transitions


func _on_enemy_battle_requested(
	enemy: WorldEnemy
) -> void:
	battle_requested.emit(enemy)


func _on_persistent_object_removed(
	object_id: StringName
) -> void:
	record_removed_object(object_id)
