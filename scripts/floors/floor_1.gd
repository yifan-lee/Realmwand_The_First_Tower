extends Floor


@onready var wall_layer: TileMapLayer = %WallLayer

@onready var wall_switch: FloorSwitch = $Interactables/WallSwitch
@onready var switch_red: FloorSwitch = $Interactables/SwitchRed
@onready var switch_blue: FloorSwitch = $Interactables/SwitchBlue
@onready var switch_yellow: FloorSwitch = $Interactables/SwitchYellow
@onready var up_stair: Area2D = $Interactables/UpStair

var wall_passage_snapshots: Array[Floor.TileCellSnapshot] = []
var stair_wall_snapshots: Array[Floor.TileCellSnapshot] = []


func _ready() -> void:
	_cache_switch_terrain()
	_apply_initial_switch_states()


func _cache_switch_terrain() -> void:
	wall_passage_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(1, -6),
			Vector2i(0, -6),
			Vector2i(-1, -6),
		]
	)
	stair_wall_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(0, -9),
		]
	)


func _apply_initial_switch_states() -> void:
	_update_wall_passage()
	_update_colored_switches()


func _on_floor_switch_state_changed(
	switch_id: StringName,
	_is_active: bool
) -> void:
	match switch_id:
		&"wall_passage":
			_update_wall_passage()
		&"switch_red", &"switch_blue", &"switch_yellow":
			_update_colored_switches()


func _update_wall_passage() -> void:
	set_tile_cells_removed(
		wall_layer,
		wall_passage_snapshots,
		wall_switch.is_active
	)


func _update_colored_switches() -> void:
	var all_active := (
		switch_red.is_active
		and switch_blue.is_active
		and switch_yellow.is_active
	)

	set_tile_cells_removed(
		wall_layer,
		stair_wall_snapshots,
		all_active
	)
	up_stair.visible = all_active
	up_stair.monitoring = all_active
	up_stair.monitorable = all_active