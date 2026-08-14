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
	_update_wall_passage_first(false)
	_update_wall_passage_second(false)
	_update_stairs(false)


func _on_floor_switch_state_changed(
	switch_id: StringName,
	_is_active: bool
) -> void:
	match switch_id:
		&"switch_first":
			_update_wall_passage_first(true)
		&"switch_red", &"switch_blue":
			_update_wall_passage_second(true)
		&"switch_yellow":
			_update_stairs(true)


func _update_wall_passage_first(notify: bool = true) -> void:
	set_tile_cells_removed(
		wall_layer,
		switch_first_snapshots,
		switch_first.is_active
	)
	if notify:
		if switch_first.is_active:
			EventBus.system_message_requested.emit("前方的墙壁降下了。")
		else:
			EventBus.system_message_requested.emit("前方的墙壁升起了。")


func _update_wall_passage_second(notify: bool = true) -> void:
	var all_active := (
		switch_red.is_active
		and switch_blue.is_active
	)
	set_tile_cells_removed(
		wall_layer,
		switch_red_blue_snapshots,
		all_active
	)
	if notify:
		if all_active:
			EventBus.system_message_requested.emit("两座机关产生共鸣，通道被打开了！")
		elif switch_red.is_active or switch_blue.is_active:
			EventBus.system_message_requested.emit("机关被激活了，但好像还需要启动另一个...")
		else:
			EventBus.system_message_requested.emit("通道已关闭。")


func _update_stairs(notify: bool = true) -> void:
	set_tile_cells_removed(
		wall_layer,
		switch_yellow_snapshots,
		switch_yellow.is_active
	)
	up_stair.visible = switch_yellow.is_active
	up_stair.monitoring = switch_yellow.is_active
	up_stair.monitorable = switch_yellow.is_active
	if notify:
		if switch_yellow.is_active:
			EventBus.system_message_requested.emit("某处的墙壁消失了，显露出了楼梯。")
		else:
			EventBus.system_message_requested.emit("楼梯被隐藏了。")
