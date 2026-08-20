class_name UIInputGate
extends RefCounted

## 常见的 UI 导航与移动 Action 映射
const NAV_ACTIONS: Array[StringName] = [
	&"ui_up", &"ui_down", &"ui_left", &"ui_right",
	&"move_up", &"move_down", &"move_left", &"move_right",
	&"ui_accept", &"ui_cancel", &"toggle_menu"
]

var _blocked_actions: Dictionary[StringName, bool] = {}


## 在 UI 打开（open）时调用：检测哪些动作当前正处于物理按下状态，全部加入 blocked 集合
func reset_gate() -> void:
	_blocked_actions.clear()
	for action in NAV_ACTIONS:
		if Input.is_action_pressed(action):
			_blocked_actions[action] = true


## 在 UI 的 _input 或 _unhandled_input 头部调用
## 返回 true: 允许 UI 继续处理该事件（放行）
## 返回 false: 该事件属于长按继承或处于 blocked 状态，应被 UI 丢弃并 consume
func filter_event(event: InputEvent) -> bool:
	if event == null:
		return true

	# 1. 如果是按键松开（Release）事件：从 blocked 集合中移除对应动作
	for action in NAV_ACTIONS:
		if event.is_action_released(action):
			_blocked_actions.erase(action)

	# 2. 如果是按下（Pressed）事件：检查是否命中 blocked 集合
	if event.is_pressed():
		for action in _blocked_actions.keys():
			if event.is_action(action):
				return false

	return true


## 是否有动作正在被阻断
func has_blocked_actions() -> bool:
	return not _blocked_actions.is_empty()
