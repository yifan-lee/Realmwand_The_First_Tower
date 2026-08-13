extends Floor


@onready var wall_layer: TileMapLayer = %WallLayer

@onready var switch_first: FloorSwitch = $Interactables/FloorSwitch
@onready var up_stair: Area2D = $Interactables/StairUp

var switch_first_snapshots: Array[Floor.TileCellSnapshot] = []


func _ready() -> void:
	switch_first.state_changed.connect(_on_floor_switch_state_changed)
	_cache_switch_terrain()
	_apply_initial_switch_states()


func _cache_switch_terrain() -> void:
	switch_first_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(0, -11),
			Vector2i(0, -12),
			Vector2i(0, -13),
		]
	)


func _apply_initial_switch_states() -> void:
	_update_stairs()


func _on_floor_switch_state_changed(
	switch_id: StringName,
	_is_active: bool
) -> void:
	match switch_id:
		&"switch_first":
			_update_stairs()


func _update_stairs() -> void:
	set_tile_cells_removed(
		wall_layer,
		switch_first_snapshots,
		switch_first.is_active
	)
	up_stair.visible = switch_first.is_active
	up_stair.monitoring = switch_first.is_active
	up_stair.monitorable = switch_first.is_active
	EventBus.system_message_requested.emit("某处的墙壁消失了，显露出了楼梯。")