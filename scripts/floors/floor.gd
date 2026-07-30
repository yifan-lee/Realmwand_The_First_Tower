class_name Floor
extends Node2D

@export_group("Identity")
@export var floor_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Spawning")
@export var default_spawn_id: StringName = &"FromStart"

@onready var spawn_points: Node2D = $SpawnPoints


func get_spawn_point(spawn_id: StringName) -> Marker2D:
	var resolved_id := spawn_id

	if resolved_id == &"":
		resolved_id = default_spawn_id

	var marker := spawn_points.get_node_or_null(
		NodePath(String(resolved_id))
	) as Marker2D

	if marker == null:
		push_error(
			"Floor '%s' has no spawn point '%s'."
			% [floor_id, resolved_id]
		)

	return marker