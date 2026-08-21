extends Floor

@onready var wall_layer: TileMapLayer = %WallLayer

@onready var switch_atk_1: FloorSwitch = $Interactables/SwitchAtk1
@onready var door_atk_1: FloorDoor = $Interactables/DoorAtk1
@onready var switch_atk_2: FloorSwitch = $Interactables/SwitchAtk2
@onready var door_atk_2: FloorDoor = $Interactables/DoorAtk2
@onready var switch_spd_1: FloorSwitch = $Interactables/SwitchSpd1
@onready var door_spd_1: FloorDoor = $Interactables/DoorSpd1
@onready var switch_def_1: FloorSwitch = $Interactables/SwitchDef1
@onready var door_def_1: FloorDoor = $Interactables/DoorDef1
@onready var switch_bal_1: FloorSwitch = $Interactables/SwitchBal1
@onready var portal_1: FloorPortal = $Interactables/Portal1
@onready var portal_2: FloorPortal = $Interactables/Portal2
@onready var switch_spd_2: FloorSwitch = $Interactables/SwitchSpd2
@onready var switch_spd_3: FloorSwitch = $Interactables/SwitchSpd3
@onready var one_way_spd_1: OneWayPassage = $Interactables/OneWaySpd1
@onready var one_way_spd_2: OneWayPassage = $Interactables/OneWaySpd2
@onready var one_way_spd_3: OneWayPassage = $Interactables/OneWaySpd3
@onready var one_way_spd_4: OneWayPassage = $Interactables/OneWaySpd4
@onready var one_way_spd_5: OneWayPassage = $Interactables/OneWaySpd5
@onready var switch_neu_1: FloorSwitch = $Interactables/SwitchNeu1
@onready var switch_neu_2: FloorSwitch = $Interactables/SwitchNeu2
@onready var switch_neu_3: FloorSwitch = $Interactables/SwitchNeu3
@onready var up_stair: Area2D = $Interactables/StairAbove

var switch_final_snapshots: Array[Floor.TileCellSnapshot] = []
var switch_atk_2_snapshots: Array[Floor.TileCellSnapshot] = []
var switch_spd_1_snapshots: Array[Floor.TileCellSnapshot] = []


func _ready() -> void:
	# 1. 监听机关状态变更
	switch_atk_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_atk_2.state_changed.connect(_on_floor_switch_state_changed)
	switch_spd_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_def_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_bal_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_spd_2.state_changed.connect(_on_floor_switch_state_changed)
	switch_spd_3.state_changed.connect(_on_floor_switch_state_changed)
	switch_neu_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_neu_2.state_changed.connect(_on_floor_switch_state_changed)
	switch_neu_3.state_changed.connect(_on_floor_switch_state_changed)
	
	_cache_switch_terrain()
	
	# 2. 初始静默同步状态（不发送系统消息）
	_apply_initial_switch_states()


func _cache_switch_terrain() -> void:
	switch_final_snapshots = capture_dynamic_wall(
		wall_layer,
		&"WallFinal"
	)

	switch_atk_2_snapshots = capture_dynamic_wall(
		wall_layer,
		&"WallAtk2"
	)

	switch_spd_1_snapshots = capture_dynamic_wall(
		wall_layer,
		&"WallSpd1"
	)


## 初始/读档状态同步（notify = false 保证不误报提示）
func _apply_initial_switch_states() -> void:
	_update_door_atk_1(false)
	_update_door_atk_2(false)
	_update_door_spd_1(false)
	_update_door_def_1(false)
	_update_portal_bal_1(false)
	_update_one_way_spd_2(false)
	_update_one_way_spd_3(false)
	_update_final_door(false)


## 玩家真实交互时触发
func _on_floor_switch_state_changed(
	switch_id: StringName,
	_is_active: bool
) -> void:
	match switch_id:
		&"switch_atk_1":
			_update_door_atk_1(true)
		&"switch_atk_2":
			_update_door_atk_2(true)
		&"switch_spd_1":
			_update_door_spd_1(true)
		&"switch_def_1":
			_update_door_def_1(true)
		&"switch_bal_1":
			_update_portal_bal_1(true)
		&"switch_spd_2":
			_update_one_way_spd_2(true)
		&"switch_spd_3":
			_update_one_way_spd_3(true)
		&"switch_neu_1", &"switch_neu_2", &"switch_neu_3":
			_update_final_door(true)


func _update_final_door(notify: bool = true) -> void:
	var all_active := (
		switch_neu_1.is_active
		and switch_neu_2.is_active
		and switch_neu_3.is_active
	)
	set_tile_cells_removed(
		wall_layer,
		switch_final_snapshots,
		all_active
	)
	up_stair.visible = all_active
	up_stair.monitoring = all_active
	up_stair.monitorable = all_active
	if notify:
		if all_active:
			EventBus.system_message_requested.emit("三座机关都被打开了，通道被打开了！")
		elif switch_neu_1.is_active or switch_neu_2.is_active or switch_neu_3.is_active:
			EventBus.system_message_requested.emit("机关被激活了，但好像还需要启动其他机关...")
		else:
			EventBus.system_message_requested.emit("通道已关闭。")

## 单向通道联动逻辑
func _update_one_way_spd_2(notify: bool = true) -> void:
	if switch_spd_2.is_active:
		one_way_spd_3.direction = OneWayPassage.PassageDirection.DOWN
	else:
		one_way_spd_3.direction = OneWayPassage.PassageDirection.LEFT

	if notify:
		if switch_spd_2.is_active:
			EventBus.system_message_requested.emit("某处的单向通道改变了方向。")
		else:
			EventBus.system_message_requested.emit("某处的单向通道改变了方向。")

func _update_one_way_spd_3(notify: bool = true) -> void:
	if switch_spd_3.is_active:
		one_way_spd_1.direction = OneWayPassage.PassageDirection.LEFT
		one_way_spd_4.direction = OneWayPassage.PassageDirection.LEFT
	else:
		one_way_spd_1.direction = OneWayPassage.PassageDirection.RIGHT
		one_way_spd_4.direction = OneWayPassage.PassageDirection.RIGHT

	if notify:
		if switch_spd_3.is_active:
			EventBus.system_message_requested.emit("某处的单向通道改变了方向。")
		else:
			EventBus.system_message_requested.emit("某处的单向通道改变了方向。")


## 门状态更新逻辑
func _update_door_atk_1(notify: bool = true) -> void:
	door_atk_1.set_open(switch_atk_1.is_active)
	if notify:
		if switch_atk_1.is_active:
			EventBus.system_message_requested.emit("某处的攻击之门打开了。")
		else:
			EventBus.system_message_requested.emit("某处的攻击之门关闭了。")


func _update_door_atk_2(notify: bool = true) -> void:
	set_tile_cells_removed(
		wall_layer,
		switch_atk_2_snapshots,
		switch_atk_2.is_active
	)
	door_atk_2.set_open(switch_atk_2.is_active)
	if notify:
		if switch_atk_2.is_active:
			EventBus.system_message_requested.emit("某处的攻击之门打开了。\n出现了通向它的捷径。")
		else:
			EventBus.system_message_requested.emit("某处的攻击之门关闭了。\n捷径关闭了。")


func _update_door_def_1(notify: bool = true) -> void:
	door_def_1.set_open(switch_def_1.is_active)
	if notify:
		if switch_def_1.is_active:
			EventBus.system_message_requested.emit("某处的防御之门打开了。")
		else:
			EventBus.system_message_requested.emit("某处的防御之门关闭了。")


func _update_door_spd_1(notify: bool = true) -> void:
	set_tile_cells_removed(
		wall_layer,
		switch_spd_1_snapshots,
		switch_spd_1.is_active
	)
	door_spd_1.set_open(switch_spd_1.is_active)
	if notify:
		if switch_spd_1.is_active:
			EventBus.system_message_requested.emit("某处的速度之门打开了。\n出现了通向它的捷径。")
		else:
			EventBus.system_message_requested.emit("某处的速度之门关闭了。")


## 传送门状态更新逻辑
func _update_portal_bal_1(notify: bool = true) -> void:
	portal_1.set_active(switch_bal_1.is_active)
	portal_2.set_active(switch_bal_1.is_active)
	if notify:
		if switch_bal_1.is_active:
			EventBus.system_message_requested.emit("某处的传送门被激活了。")
		else:
			EventBus.system_message_requested.emit("传送门已关闭。")
