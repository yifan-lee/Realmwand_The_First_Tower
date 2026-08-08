extends Floor


@onready var wall_layer: TileMapLayer = %WallLayer

@onready var switch_first: FloorSwitch = $Interactables/SwitchFirst
@onready var switch_red: FloorSwitch = $Interactables/SwitchRed
@onready var switch_blue: FloorSwitch = $Interactables/SwitchBlue
@onready var switch_yellow: FloorSwitch = $Interactables/SwitchYellow
@onready var up_stair: Area2D = $Interactables/UpStair

var switch_first_snapshots: Array[Floor.TileCellSnapshot] = []
var switch_red_blue_snapshots: Array[Floor.TileCellSnapshot] = []
var switch_yellow_snapshots: Array[Floor.TileCellSnapshot] = []


func _ready() -> void:
	switch_first.state_changed.connect(_on_floor_switch_state_changed)
	switch_red.state_changed.connect(_on_floor_switch_state_changed)
	switch_blue.state_changed.connect(_on_floor_switch_state_changed)
	switch_yellow.state_changed.connect(_on_floor_switch_state_changed)
	_cache_switch_terrain()
	_apply_initial_switch_states()


func _cache_switch_terrain() -> void:
	switch_first_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(0, -5),
			Vector2i(0, -6),
		]
	)
	switch_red_blue_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(0, -12),
			Vector2i(0, -13),
		]
	)
	switch_yellow_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(0, -9),
		]
	)


func _apply_initial_switch_states() -> void:
	_update_wall_passage_first()
	_update_wall_passage_second()
	_update_stairs()


func _on_floor_switch_state_changed(
	switch_id: StringName,
	_is_active: bool
) -> void:
	match switch_id:
		&"switch_first":
			_update_wall_passage_first()
		&"switch_red", &"switch_blue":
			_update_wall_passage_second()
		&"switch_yellow":
			_update_stairs()


func _update_wall_passage_first() -> void:
	set_tile_cells_removed(
		wall_layer,
		switch_first_snapshots,
		switch_first.is_active
	)


func _update_wall_passage_second() -> void:
	var all_active := (
		switch_red.is_active
		and switch_blue.is_active
	)
	set_tile_cells_removed(
		wall_layer,
		switch_red_blue_snapshots,
		all_active
	)


func _update_stairs() -> void:

	set_tile_cells_removed(
		wall_layer,
		switch_yellow_snapshots,
		switch_yellow.is_active
	)
	up_stair.visible = switch_yellow.is_active
	up_stair.monitoring = switch_yellow.is_active
	up_stair.monitorable = switch_yellow.is_active