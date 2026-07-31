extends Floor


class SwitchTerrainRule:
	extends RefCounted

	var switch_id: StringName
	var wall_cells: Array[Vector2i]
	var wall_snapshots: Array[Floor.TileCellSnapshot] = []

	func _init(
		target_switch_id: StringName,
		target_wall_cells: Array[Vector2i]
	) -> void:
		switch_id = target_switch_id
		wall_cells = target_wall_cells


@onready var wall_layer: TileMapLayer = %WallLayer
@onready var interactables: Node2D = %Interactables

var switch_rules: Array[SwitchTerrainRule] = []


func _ready() -> void:
	_create_switch_rules()
	_cache_switch_terrain()
	_apply_initial_switch_states()


func _create_switch_rules() -> void:
	switch_rules = [
		SwitchTerrainRule.new(
			&"wall_passage",
			[
				Vector2i(1, -6),
				Vector2i(0, -6),
                Vector2i(-1, -6),
			]
		),
	]


func _cache_switch_terrain() -> void:
	for rule: SwitchTerrainRule in switch_rules:
		rule.wall_snapshots = capture_tile_cells(
			wall_layer,
			rule.wall_cells
		)


func _apply_initial_switch_states() -> void:
	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch == null:
			continue

		_apply_switch_state(
			floor_switch.switch_id,
			floor_switch.is_active
		)


func _on_floor_switch_state_changed(
	switch_id: StringName,
	is_active: bool
) -> void:
	_apply_switch_state(switch_id, is_active)


func _apply_switch_state(
	switch_id: StringName,
	is_active: bool
) -> void:
	for rule: SwitchTerrainRule in switch_rules:
		if rule.switch_id != switch_id:
			continue

		set_tile_cells_removed(
			wall_layer,
			rule.wall_snapshots,
			is_active
		)
		return

	push_error(
		"Floor '%s' has no terrain rule for switch '%s'."
		% [floor_id, switch_id]
	)