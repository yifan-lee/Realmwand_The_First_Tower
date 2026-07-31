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