wextends Floor

@onready var stair_up: Area2D = $Interactables/StairUp
@onready var from_below_stair: Marker2D = $SpawnPoints/FromBelowStair

# 规则激活状态（解密成功后设为 false）
var is_rule_active: bool = true

# 记录玩家上一步的朝向（初始默认向前/向上）
var _last_facing: Vector2 = Vector2.UP
var _player: Player = null
var _pending_teleport: bool = false


func _ready() -> void:
	# 延迟一帧获取 Player 节点并绑定移动信号
	call_deferred("_setup_player_listener")


func _setup_player_listener() -> void:
	_player = get_tree().get_root().find_child("Player", true, false) as Player
		
	if _player != null:
		_last_facing = _player.facing_direction
		_player.movement_finished.connect(_on_player_movement_finished)


func _input(event: InputEvent) -> void:
	if not is_rule_active or _player == null or not _player.input_enabled:
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
		
		if _player.is_moving:
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

	var current_facing := _player.facing_direction
	
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
	_player.facing_direction = Vector2.UP
	_last_facing = Vector2.UP
	
	# 可选：如果在战斗管理器或 UI 中有消息提示面板，可以提示玩家
	# print("违反迷宫规则，被传送回起点！")


## 当触发了解密机关/StairUp 时的回调
func unlock_rule() -> void:
	is_rule_active = false
	print("Floor 3 迷宫规则已解除！")
