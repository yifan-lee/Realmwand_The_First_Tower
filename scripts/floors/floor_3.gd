extends Floor

@onready var stair_up: Area2D = $Interactables/StairUp
@onready var from_below_stair: Marker2D = $SpawnPoints/FromBelowStair

# 规则激活状态（解密成功后设为 false）
var is_rule_active: bool = true

# 记录玩家上一步的朝向（初始默认向前/向上）
var _last_facing: Vector2 = Vector2.UP
var _player: Player = null
var _is_first_step: bool = true


func _ready() -> void:
	# 延迟一帧获取 Player 节点并绑定移动信号
	call_deferred("_setup_player_listener")


func _setup_player_listener() -> void:
	_player = get_tree().get_root().find_child("Player", true, false) as Player
		
	if _player != null:
		_last_facing = _player.facing_direction
		_player.movement_finished.connect(_on_player_movement_finished)


func _on_player_movement_finished() -> void:
	# 如果规则已解除，或者玩家未获取到，则不进行限制
	if not is_rule_active or _player == null:
		return

	var current_facing := _player.facing_direction
	
	# 第一步不触发规则，只记录方向
	if _is_first_step:
		_is_first_step = false
		_last_facing = current_facing
		return

	# 允许的方向 1：向前（保持上一次朝向）
	var forward_dir := _last_facing
	
	# 允许的方向 2：右转
	var right_dir := Vector2.ZERO
	match _last_facing:
		Vector2.UP: right_dir = Vector2.LEFT
		Vector2.RIGHT: right_dir = Vector2.UP
		Vector2.DOWN: right_dir = Vector2.RIGHT
		Vector2.LEFT: right_dir = Vector2.DOWN

	# 检查当前朝向是否合法
	var is_valid_move := (current_facing == forward_dir or current_facing == right_dir)

	if is_valid_move:
		# 移动合法，更新记录的朝向
		_last_facing = current_facing
	else:
		# 移动违规（左转或后退）：立刻传送回起点！
		_fail_and_teleport_to_start()


func _fail_and_teleport_to_start() -> void:
	if _player == null or from_below_stair == null:
		return

	# 瞬间重置玩家位置到起点
	_player.global_position = from_below_stair.global_position
	# 重置朝向记录
	_player.facing_direction = Vector2.UP
	_last_facing = Vector2.UP
	# 重新允许第一步豁免
	_is_first_step = true
	
	# 可选：如果在战斗管理器或 UI 中有消息提示面板，可以提示玩家
	# print("违反迷宫规则，被传送回起点！")


## 当触发了解密机关/StairUp 时的回调
func unlock_rule() -> void:
	is_rule_active = false
	print("Floor 3 迷宫规则已解除！")
