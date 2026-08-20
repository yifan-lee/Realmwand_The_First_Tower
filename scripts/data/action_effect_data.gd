class_name ActionEffectData
extends Resource

enum TargetType {
	SELF,
	OPPONENT,
	ALL,
}

enum ResourceType {
	NONE,
	HP,
	MP,
	FP,
	SHIELD,
}

enum CalcMethod {
	FIXED_AMOUNT,
	SKILL_POWER,
	MAX_RATIO,
}

@export var target: TargetType = TargetType.OPPONENT

@export_group("Instant Resource Change")
@export var resource_type: ResourceType = ResourceType.HP
@export var calc_method: CalcMethod = CalcMethod.SKILL_POWER
@export var value: float = 1.0
@export var is_interrupt: bool = false
@export var is_free_action: bool = false

@export_group("Applied Status")
@export var status_to_apply: StatusEffectData = null


func get_target_prefix() -> String:
	match target:
		TargetType.SELF:
			return "对自身"
		TargetType.ALL:
			return "对全体"
		TargetType.OPPONENT:
			return "对敌方"
	return ""


func get_description() -> String:
	var desc_parts: Array[String] = []
	var target_prefix := get_target_prefix()

	if is_interrupt:
		desc_parts.append("%s打断吟唱" % target_prefix)

	if is_free_action:
		desc_parts.append("自由动作（不消耗行动机会）")

	if resource_type != ResourceType.NONE and not is_zero_approx(value):
		var res_name := _get_resource_name()
		match calc_method:
			CalcMethod.SKILL_POWER:
				if value > 0:
					desc_parts.append("%s造成 %.0f 点技能威力伤害" % [target_prefix, value])
				else:
					desc_parts.append("%s恢复 %.0f 点技能威力生命" % [target_prefix, absf(value)])
			CalcMethod.FIXED_AMOUNT:
				if value > 0:
					if resource_type == ResourceType.SHIELD:
						desc_parts.append("%s获得 %.0f 点护盾" % [target_prefix, value])
					else:
						desc_parts.append("%s恢复 %.0f 点%s" % [target_prefix, value, res_name])
				else:
					desc_parts.append("%s减少 %.0f 点%s" % [target_prefix, absf(value), res_name])
			CalcMethod.MAX_RATIO:
				if value > 0:
					if resource_type == ResourceType.SHIELD:
						desc_parts.append("%s获得最大生命值 %.0f%% 的护盾" % [target_prefix, value * 100.0])
					else:
						desc_parts.append("%s恢复最大%s %.0f%%" % [target_prefix, res_name, value * 100.0])
				else:
					desc_parts.append("%s减少最大%s %.0f%%" % [target_prefix, res_name, absf(value) * 100.0])

	if status_to_apply != null:
		var status_desc := status_to_apply.get_formatted_description()
		var status_name := status_to_apply.display_name if not status_to_apply.display_name.is_empty() else status_to_apply.get_stat_name()
		if not status_desc.is_empty():
			if status_desc.begins_with("【"):
				desc_parts.append(status_desc)
			else:
				desc_parts.append("%s施加【%s】：%s" % [target_prefix, status_name, status_desc])

	return "；".join(desc_parts)


func _get_resource_name() -> String:
	match resource_type:
		ResourceType.HP: return "生命"
		ResourceType.MP: return "魔力"
		ResourceType.FP: return "专注"
		ResourceType.SHIELD: return "护盾"
	return "资源"
