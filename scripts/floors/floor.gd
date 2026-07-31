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
@onready var enemies: Node2D = %Enemies


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
	var pickup_states: Dictionary = {}
	var enemy_states: Dictionary = {}

	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch != null:
			if floor_switch.switch_id != &"":
				var switch_key := String(
					floor_switch.switch_id
				)

				switch_states[switch_key] = (
					floor_switch.is_active
				)

			continue

		var item_pickup := child as ItemPickup

		if item_pickup != null:
			if item_pickup.pickup_id != &"":
				var pickup_key := String(
					item_pickup.pickup_id
				)

				pickup_states[pickup_key] = {
					"is_collected":
						item_pickup.is_collected,
					"amount":
						item_pickup.amount,
				}

	for child: Node in enemies.get_children():
		var enemy := child as Enemy

		if enemy == null:
			continue

		if enemy.instance_id.is_empty():
			continue

		var enemy_key := String(
			enemy.instance_id
		)

		enemy_states[enemy_key] = {
			"is_defeated": enemy.is_defeated,
			"current_hp": enemy.current_hp,
			"current_mp": enemy.current_mp,
		}

	return {
		"switches": switch_states,
		"pickups": pickup_states,
		"enemies": enemy_states,
	}


func apply_runtime_state(state: Dictionary) -> void:
	_apply_switch_states(
		state.get("switches", {})
	)
	_apply_pickup_states(
		state.get("pickups", {})
	)
	_apply_enemy_states(
		state.get("enemies", {})
	)


func _apply_switch_states(
	switch_states_value: Variant
) -> void:
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


func _apply_pickup_states(
	pickup_states_value: Variant
) -> void:
	if not (pickup_states_value is Dictionary):
		push_error(
			"Floor '%s' has invalid pickup state data."
			% floor_id
		)
		return

	var pickup_states: Dictionary = pickup_states_value

	for child: Node in interactables.get_children():
		var item_pickup := child as ItemPickup

		if item_pickup == null:
			continue

		var pickup_key := String(
			item_pickup.pickup_id
		)

		if not pickup_states.has(pickup_key):
			continue

		var pickup_state_value: Variant = (
			pickup_states[pickup_key]
		)

		if not (pickup_state_value is Dictionary):
			push_error(
				"Pickup '%s' has invalid state data."
				% item_pickup.pickup_id
			)
			continue

		var pickup_state: Dictionary = (
			pickup_state_value
		)

		item_pickup.amount = maxi(
			1,
			int(
				pickup_state.get(
					"amount",
					item_pickup.amount
				)
			)
		)

		item_pickup.set_collected(
			bool(
				pickup_state.get(
					"is_collected",
					false
				)
			)
		)


func _apply_enemy_states(
	enemy_states_value: Variant
) -> void:
	if not (enemy_states_value is Dictionary):
		push_error(
			"Floor '%s' has invalid enemy state data."
			% floor_id
		)
		return

	var enemy_states: Dictionary = enemy_states_value

	for child: Node in enemies.get_children():
		var enemy := child as Enemy

		if enemy == null:
			continue

		var enemy_key := String(
			enemy.instance_id
		)

		if not enemy_states.has(enemy_key):
			continue

		var enemy_state_value: Variant = (
			enemy_states[enemy_key]
		)

		if not (enemy_state_value is Dictionary):
			push_error(
				"Enemy '%s' has invalid state data."
				% enemy.instance_id
			)
			continue

		var enemy_state: Dictionary = (
			enemy_state_value
		)

		enemy.current_hp = maxf(
			0.0,
			float(
				enemy_state.get(
					"current_hp",
					enemy.current_hp
				)
			)
		)

		enemy.current_mp = maxf(
			0.0,
			float(
				enemy_state.get(
					"current_mp",
					enemy.current_mp
				)
			)
		)

		enemy.set_defeated(
			bool(
				enemy_state.get(
					"is_defeated",
					false
				)
			)
		)