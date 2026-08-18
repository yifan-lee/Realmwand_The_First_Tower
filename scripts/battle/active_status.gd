@tool
class_name ActiveStatus
extends RefCounted

var data: StatusEffectData
var owner_actor: Node
var remaining_actions: int = 0
var remaining_triggers: int = 0
var current_stacks: int = 1
var current_trigger_count: int = 0


func _init(p_data: StatusEffectData, p_owner: Node) -> void:
	data = p_data
	owner_actor = p_owner
	remaining_actions = data.duration_count
	remaining_triggers = data.duration_count
	current_stacks = 1
	current_trigger_count = 0


func is_permanent() -> bool:
	if data == null:
		return true
	return data.end_condition == StatusEffectData.EndCondition.PERMANENT or data.duration_count == 0


func is_expired() -> bool:
	if is_permanent():
		return false
	match data.end_condition:
		StatusEffectData.EndCondition.OWNER_ACTIONS:
			return remaining_actions <= 0
		StatusEffectData.EndCondition.TRIGGER_COUNT:
			return remaining_triggers <= 0
		StatusEffectData.EndCondition.SHIELD_DEPLETED:
			return false  # 由外部破盾事件主动触发
	return false


func is_interval_active() -> bool:
	if data == null or data.trigger_interval <= 1:
		return true
	return ((current_trigger_count + 1) % data.trigger_interval) == 0


func get_remaining_to_interval() -> int:
	if data == null or data.trigger_interval <= 1:
		return 0
	var rem: int = data.trigger_interval - (current_trigger_count % data.trigger_interval)
	return rem


func on_owner_action_completed() -> void:
	if is_permanent():
		return
	if data.end_condition == StatusEffectData.EndCondition.OWNER_ACTIONS:
		remaining_actions = maxi(0, remaining_actions - 1)


func on_trigger_event(trigger_type: StatusEffectData.TriggerType) -> bool:
	if data == null:
		return false
	if data.trigger_type != trigger_type:
		return false

	current_trigger_count += 1

	if is_permanent():
		return true

	if data.end_condition == StatusEffectData.EndCondition.TRIGGER_COUNT:
		remaining_triggers = maxi(0, remaining_triggers - 1)
		return true

	return false


func refresh_duration() -> void:
	remaining_actions = data.duration_count
	remaining_triggers = data.duration_count


func extend_duration(amount: int) -> void:
	remaining_actions += amount
	remaining_triggers += amount


func add_stack() -> void:
	current_stacks = mini(data.max_stacks, current_stacks + 1)
	refresh_duration()


func get_formatted_text() -> String:
	if data == null:
		return ""
	var remaining: int = -1
	if not is_permanent():
		if data.end_condition == StatusEffectData.EndCondition.OWNER_ACTIONS:
			remaining = remaining_actions
		elif data.end_condition == StatusEffectData.EndCondition.TRIGGER_COUNT:
			remaining = remaining_triggers
	var rem_interval: int = get_remaining_to_interval()
	return data.get_formatted_description(remaining, current_stacks, rem_interval)
