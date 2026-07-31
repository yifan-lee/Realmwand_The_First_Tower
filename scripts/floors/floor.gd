class_name Floor
extends Node2D


class TileCellSnapshot:
	extends RefCounted

	var cell: Vector2i
	var source_id: int
	var atlas_coords: Vector2i
	var alternative_tile: int

	func _init(
		target_cell: Vector2i,
		target_source_id: int,
		target_atlas_coords: Vector2i,
		target_alternative_tile: int
	) -> void:
		cell = target_cell
		source_id = target_source_id
		atlas_coords = target_atlas_coords
		alternative_tile = target_alternative_tile

@export_group("Identity")
@export var floor_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Spawning")
@export var default_spawn_id: StringName = &"FromStart"

@onready var spawn_points: Node2D = $SpawnPoints
@onready var interactables: Node2D = %Interactables


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


func capture_tile_cells(
	layer: TileMapLayer,
	cells: Array[Vector2i]
) -> Array[TileCellSnapshot]:
	var snapshots: Array[TileCellSnapshot] = []

	for cell: Vector2i in cells:
		var source_id := layer.get_cell_source_id(cell)

		if source_id == -1:
			push_error(
				"Floor '%s' has no tile at cell %s."
				% [floor_id, cell]
			)
			continue

		var snapshot := TileCellSnapshot.new(
			cell,
			source_id,
			layer.get_cell_atlas_coords(cell),
			layer.get_cell_alternative_tile(cell)
		)

		snapshots.append(snapshot)

	return snapshots


func set_tile_cells_removed(
	layer: TileMapLayer,
	snapshots: Array[TileCellSnapshot],
	removed: bool
) -> void:
	for snapshot: TileCellSnapshot in snapshots:
		if removed:
			layer.erase_cell(snapshot.cell)
		else:
			layer.set_cell(
				snapshot.cell,
				snapshot.source_id,
				snapshot.atlas_coords,
				snapshot.alternative_tile
			)

func capture_runtime_state() -> Dictionary:
	var switch_states: Dictionary = {}

	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch == null:
			continue

		if floor_switch.switch_id == &"":
			continue

		var switch_key := String(
			floor_switch.switch_id
		)

		switch_states[switch_key] = floor_switch.is_active

	return {
		"switches": switch_states,
	}

func apply_runtime_state(state: Dictionary) -> void:
	var switch_states_value: Variant = state.get(
		"switches",
		{}
	)

	if not (switch_states_value is Dictionary):
		push_error(
			"Floor '%s' has invalid switch state data."
			% floor_id
		)
		return

	var switch_states: Dictionary = switch_states_value

	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch == null:
			continue

		var switch_key := String(
			floor_switch.switch_id
		)

		if not switch_states.has(switch_key):
			continue

		floor_switch.set_active(
			bool(switch_states[switch_key])
		)