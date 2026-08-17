class_name BattleStatusController
extends RefCounted

## 战斗状态单一真值源管理器：负责所有 ActiveStatus 的增删改查、生命周期流转与属性加成计算。

var _statuses: Dictionary = {}  # Dictionary[Node, Array[ActiveStatus]]


func apply_status(target: Node, status_data: StatusEffectData) -> ActiveStatus:
	if target == null or status_data == null:
		return null

	var list: Array[ActiveStatus] = _get_or_create_status_list(target)

	# 查找同 ID 状态
	var existing: ActiveStatus = null
	if not status_data.id.is_empty():
		for s in list:
			if s.data.id == status_data.id:
				existing = s
				break

	if existing != null:
		match status_data.stack_policy:
			StatusEffectData.StackPolicy.REFRESH:
				existing.refresh_duration()
				return existing
			StatusEffectData.StackPolicy.ADD_STACK:
				existing.add_stack()
				return existing
			StatusEffectData.StackPolicy.EXTEND:
				existing.extend_duration(status_data.duration_count)
				return existing
			StatusEffectData.StackPolicy.REPLACE:
				list.erase(existing)
			StatusEffectData.StackPolicy.INDEPENDENT:
				pass  # 允许独立并存

	var new_status := ActiveStatus.new(status_data, target)
	list.append(new_status)
	return new_status


func remove_status(target: Node, status: ActiveStatus) -> void:
	if target == null or status == null:
		return
	if _statuses.has(target):
		var list: Array[ActiveStatus] = _statuses[target]
		list.erase(status)


func remove_statuses_by_polarity(target: Node, polarity: StatusEffectData.Polarity) -> void:
	if target == null or not _statuses.has(target):
		return
	var list: Array[ActiveStatus] = _statuses[target]
	for i in range(list.size() - 1, -1, -1):
		if list[i].data.polarity == polarity:
			list.remove_at(i)


func on_action_finished(actor: Node) -> void:
	if actor == null or not _statuses.has(actor):
		return
	var list: Array[ActiveStatus] = _statuses[actor]
	for i in range(list.size() - 1, -1, -1):
		var status := list[i]
		status.on_owner_action_completed()
		if status.is_expired():
			list.remove_at(i)


func on_trigger_event(actor: Node, trigger_type: StatusEffectData.TriggerType) -> void:
	if actor == null or not _statuses.has(actor):
		return
	var list: Array[ActiveStatus] = _statuses[actor]
	for i in range(list.size() - 1, -1, -1):
		var status := list[i]
		if status.on_trigger_event(trigger_type):
			if status.is_expired():
				list.remove_at(i)


func on_shield_depleted(actor: Node) -> void:
	if actor == null or not _statuses.has(actor):
		return
	var list: Array[ActiveStatus] = _statuses[actor]
	for i in range(list.size() - 1, -1, -1):
		var status := list[i]
		if status.data.end_condition == StatusEffectData.EndCondition.SHIELD_DEPLETED:
			list.remove_at(i)


func get_effective_stat(base_value: float, actor: Node, stat_type: StatusEffectData.StatType) -> float:
	if actor == null or not _statuses.has(actor):
		return base_value

	var added_value := 0.0
	var multiplier := 1.0
	var list: Array[ActiveStatus] = _statuses[actor]
	for status: ActiveStatus in list:
		if status.data == null or status.data.affected_stat != stat_type:
			continue
		var stacks := float(status.current_stacks)
		if status.data.operation == StatusEffectData.OpType.MULTIPLY:
			multiplier *= (1.0 + (status.data.value - 1.0) * stacks)
		else:
			added_value += status.data.value * stacks

	return maxf(0.0, (base_value + added_value) * multiplier)


func get_skill_power_modifier(actor: Node, skill_type: int) -> float:
	if actor == null or not _statuses.has(actor):
		return 1.0

	var added_value := 0.0
	var multiplier := 1.0
	var list: Array[ActiveStatus] = _statuses[actor]
	for status: ActiveStatus in list:
		if status.data == null or status.data.affected_stat != StatusEffectData.StatType.SKILL_POWER:
			continue
		if status.data.restrict_skill_type and status.data.target_skill_type != skill_type:
			continue
		var stacks := float(status.current_stacks)
		if status.data.operation == StatusEffectData.OpType.MULTIPLY:
			multiplier *= (1.0 + (status.data.value - 1.0) * stacks)
		else:
			added_value += status.data.value * stacks

	return maxf(0.0, (1.0 + added_value) * multiplier)


func get_active_effects_for_ui(actor: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if actor == null or not _statuses.has(actor):
		return result

	var list: Array[ActiveStatus] = _statuses[actor]
	for status: ActiveStatus in list:
		if status.data == null:
			continue
		result.append({
			&"id": status.data.id,
			&"icon": status.data.icon,
			&"text": status.get_formatted_text(),
			&"polarity": status.data.polarity,
			&"status": status,
		})
	return result


func get_statuses(actor: Node) -> Array[ActiveStatus]:
	if actor == null or not _statuses.has(actor):
		return []
	return _statuses[actor].duplicate()


func clear_actor_statuses(actor: Node) -> void:
	if actor != null and _statuses.has(actor):
		_statuses.erase(actor)


func clear_all() -> void:
	_statuses.clear()


func _get_or_create_status_list(actor: Node) -> Array[ActiveStatus]:
	if not _statuses.has(actor):
		var new_list: Array[ActiveStatus] = []
		_statuses[actor] = new_list
		return new_list
	return _statuses[actor]
