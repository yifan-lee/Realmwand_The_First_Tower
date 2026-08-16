extends Floor

@onready var switch_atk_1: FloorSwitch = $Interactables/SwitchAtk1
@onready var door_atk_1: FloorDoor = $Interactables/DoorAtk1
@onready var switch_atk_2: FloorSwitch = $Interactables/SwitchAtk2
@onready var door_atk_2: FloorDoor = $Interactables/DoorAtk2
@onready var switch_spd_1: FloorSwitch = $Interactables/SwitchSpd1
@onready var door_spd_1: FloorDoor = $Interactables/DoorSpd1
@onready var switch_def_1: FloorSwitch = $Interactables/SwitchDef1
@onready var door_def_1: FloorDoor = $Interactables/DoorDef1
@onready var switch_spd_2: FloorSwitch = $Interactables/SwitchSpd2
@onready var one_way_spd_1: OneWayPassage = $Interactables/OneWaySpd1


func _ready() -> void:
	# 1. 监听机关状态变更
	switch_atk_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_atk_2.state_changed.connect(_on_floor_switch_state_changed)
	switch_spd_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_def_1.state_changed.connect(_on_floor_switch_state_changed)
	switch_spd_2.state_changed.connect(_on_floor_switch_state_changed)
	
	# 2. 初始静默同步状态（不发送系统消息）
	_apply_initial_switch_states()


## 初始/读档状态同步（notify = false 保证不误报提示）
func _apply_initial_switch_states() -> void:
	_update_door_atk_1(false)
	_update_door_atk_2(false)
	_update_door_spd_1(false)
	_update_door_def_1(false)
	_update_one_way_spd_1(false)


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
		&"switch_spd_2":
			_update_one_way_spd_1(true)


## 单向通道联动逻辑
func _update_one_way_spd_1(notify: bool = true) -> void:
	if switch_spd_2.is_active:
		one_way_spd_1.direction = OneWayPassage.PassageDirection.LEFT
	else:
		one_way_spd_1.direction = OneWayPassage.PassageDirection.DOWN

	if notify:
		if switch_spd_2.is_active:
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
	door_atk_2.set_open(switch_atk_2.is_active)
	if notify:
		if switch_atk_2.is_active:
			EventBus.system_message_requested.emit("某处的攻击之门打开了。")
		else:
			EventBus.system_message_requested.emit("某处的攻击之门关闭了。")


func _update_door_def_1(notify: bool = true) -> void:
	door_def_1.set_open(switch_def_1.is_active)
	if notify:
		if switch_def_1.is_active:
			EventBus.system_message_requested.emit("某处的防御之门打开了。")
		else:
			EventBus.system_message_requested.emit("某处的防御之门关闭了。")


func _update_door_spd_1(notify: bool = true) -> void:
	door_spd_1.set_open(switch_spd_1.is_active)
	if notify:
		if switch_spd_1.is_active:
			EventBus.system_message_requested.emit("某处的速度之门打开了。")
		else:
			EventBus.system_message_requested.emit("某处的速度之门关闭了。")
