extends Floor

@onready var wall_layer: TileMapLayer = %WallLayer
@onready var stair_up: Area2D = $Interactables/StairUp
@onready var from_below_stair: Marker2D = $SpawnPoints/FromBelowStair
@onready var switch1: FloorSwitch = $Interactables/Switch1

# 规则激活状态（解密成功后设为 false）
var is_rule_active: bool = true

# 记录玩家上一步的朝向（初始默认向前/向上）
var _last_facing: Vector2 = Vector2.UP
var _player: Player = null
var _pending_teleport: bool = false
var _fail_count: int = 0
var switch1_snapshots: Array[Floor.TileCellSnapshot] = []


func _ready() -> void:
	_cache_switch_terrain()
	stair_up.body_entered.connect(
		_on_stair_up_body_entered
	)
	switch1.state_changed.connect(_on_floor_switch_state_changed)

	# 延迟一帧获取 Player 节点并绑定移动信号
	call_deferred("_setup_player_listener")


func _exit_tree() -> void:
	if (
		is_instance_valid(_player)
		and _player.movement_finished.is_connected(
			_on_player_movement_finished
		)
	):
		_player.movement_finished.disconnect(
			_on_player_movement_finished
		)

	_pending_teleport = false
	_player = null


func _setup_player_listener() -> void:
	_player = get_tree().get_root().find_child("Player", true, false) as Player
		
	if _player != null:
		_last_facing = _player.movement.facing_direction
		if not _player.movement_finished.is_connected(
			_on_player_movement_finished
		):
			_player.movement_finished.connect(
				_on_player_movement_finished
			)


func capture_runtime_state() -> Dictionary:
	var state := super()
	state["is_rule_active"] = is_rule_active
	state["fail_count"] = _fail_count
	return state


func apply_runtime_state(state: Dictionary) -> void:
	super(state)
	is_rule_active = bool(
		state.get("is_rule_active", is_rule_active)
	)
	_fail_count = int(state.get("fail_count", _fail_count))


func _on_stair_up_body_entered(body: Node2D) -> void:
	if body is Player:
		unlock_rule()


func _input(event: InputEvent) -> void:
	if not is_rule_active or _player == null or _player.is_movement_locked() or not _player.movement.input_enabled:
		return
		
	var direction := Vector2.ZERO
	if event.is_action("move_up"): direction = Vector2.UP
	elif event.is_action("move_down"): direction = Vector2.DOWN
	elif event.is_action("move_left"): direction = Vector2.LEFT
	elif event.is_action("move_right"): direction = Vector2.RIGHT

	if direction == Vector2.ZERO or not event.is_pressed():
		return

	if event is InputEventKey and (event as InputEventKey).echo:
		return

	var forward_dir := _last_facing
	var right_dir := Vector2.ZERO
	match _last_facing:
		Vector2.UP: right_dir = Vector2.LEFT
		Vector2.RIGHT: right_dir = Vector2.UP
		Vector2.DOWN: right_dir = Vector2.RIGHT
		Vector2.LEFT: right_dir = Vector2.DOWN

	var is_valid_move := (direction == forward_dir or direction == right_dir)

	# 起点特赦：如果出发地或目的地是起点，则放行（同时也替代了之前的“第一步特赦”）
	if not is_valid_move and from_below_stair != null:
		var current_pos := _player.global_position
		var target_pos := current_pos + direction * _player.grid_size
		var start_pos := from_below_stair.global_position
		if current_pos.distance_to(start_pos) < 1.0 or target_pos.distance_to(start_pos) < 1.0:
			is_valid_move = true

	if not is_valid_move:
		get_viewport().set_input_as_handled()
		
		# 阻断玩家当前的持键状态，防止继续执行非法操作
		_player.set_input_enabled(false)
		
		if _player.movement.is_moving:
			# 如果玩家正在合法移动的过程中按下了非法按键，则等当前移动完毕后传送
			_pending_teleport = true
		else:
			# 如果玩家静止时按下了非法按键，立刻传送
			_fail_and_teleport_to_start()
			_player.set_input_enabled(true)


func _on_player_movement_finished() -> void:
	if not is_rule_active or _player == null:
		return

	if _pending_teleport:
		_pending_teleport = false
		_fail_and_teleport_to_start()
		_player.set_input_enabled(true)
		return

	var current_facing := _player.movement.facing_direction
	
	var forward_dir := _last_facing
	var right_dir := Vector2.ZERO
	match _last_facing:
		Vector2.UP: right_dir = Vector2.LEFT
		Vector2.RIGHT: right_dir = Vector2.UP
		Vector2.DOWN: right_dir = Vector2.RIGHT
		Vector2.LEFT: right_dir = Vector2.DOWN

	var is_valid_move := (current_facing == forward_dir or current_facing == right_dir)

	# 同步在完成时也检测特赦（防止有未能拦截的边界情况）
	if not is_valid_move and from_below_stair != null:
		var current_pos := _player.global_position
		var prev_pos := current_pos - current_facing * _player.grid_size
		var start_pos := from_below_stair.global_position
		if current_pos.distance_to(start_pos) < 1.0 or prev_pos.distance_to(start_pos) < 1.0:
			is_valid_move = true

	if is_valid_move:
		_last_facing = current_facing
	else:
		_fail_and_teleport_to_start()


func _fail_and_teleport_to_start() -> void:
	if _player == null or from_below_stair == null:
		return

	# 瞬间重置玩家位置到起点
	_player.global_position = from_below_stair.global_position
	# 重置朝向记录
	_player.movement.facing_direction = Vector2.UP
	_last_facing = Vector2.UP
	
	_fail_count += 1
	if _fail_count >= 3:
		EventBus.system_message_requested.emit("这层角色只能前进和左拐。")


## 当触发了解密机关/StairUp 时的回调
func unlock_rule() -> void:
	if not is_rule_active:
		return

	is_rule_active = false
	_pending_teleport = false
	EventBus.system_message_requested.emit("Floor 3 迷宫规则已解除！")


func _on_floor_switch_state_changed(
	switch_id: StringName,
	_is_active: bool
) -> void:
	match switch_id:
		&"switch1":
			_update_wall_passage_first(true)

func _update_wall_passage_first(notify: bool = true) -> void:
	set_tile_cells_removed(
		wall_layer,
		switch1_snapshots,
		switch1.is_active
	)
	if notify:
		if switch1.is_active:
			EventBus.system_message_requested.emit("某处的墙壁降下了，露出了捷径。")
		else:
			EventBus.system_message_requested.emit("捷径已关闭。")

func _cache_switch_terrain() -> void:
	switch1_snapshots = capture_tile_cells(
		wall_layer,
		[
			Vector2i(-1, -5),
			Vector2i(-2, -5),
		]
	)
