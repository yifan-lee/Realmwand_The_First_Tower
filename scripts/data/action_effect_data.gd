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

@export_group("Applied Status")
@export var status_to_apply: StatusEffectData = null


func get_description() -> String:
	var desc_parts: Array[String] = []

	if is_interrupt:
		desc_parts.append("打断目标吟唱")

	if resource_type != ResourceType.NONE and not is_zero_approx(value):
		var res_name := _get_resource_name()
		match calc_method:
			CalcMethod.SKILL_POWER:
				if value > 0:
					desc_parts.append("造成 %.0f 点技能威力伤害" % value)
				else:
					desc_parts.append("恢复 %.0f 点技能威力生命" % absf(value))
			CalcMethod.FIXED_AMOUNT:
				if value > 0:
					if resource_type == ResourceType.SHIELD:
						desc_parts.append("获得 %.0f 点护盾" % value)
					else:
						desc_parts.append("恢复 %.0f 点%s" % [value, res_name])
				else:
					desc_parts.append("扣除 %.0f 点%s" % [absf(value), res_name])
			CalcMethod.MAX_RATIO:
				if value > 0:
					if resource_type == ResourceType.SHIELD:
						desc_parts.append("获得最大生命值 %.0f%% 的护盾" % (value * 100.0))
					else:
						desc_parts.append("恢复最大%s %.0f%%" % [res_name, value * 100.0])
				else:
					desc_parts.append("扣除最大%s %.0f%%" % [res_name, absf(value) * 100.0])

	if status_to_apply != null:
		var status_desc := status_to_apply.get_formatted_description()
		if not status_desc.is_empty():
			desc_parts.append(status_desc)

	return "；".join(desc_parts)


func _get_resource_name() -> String:
	match resource_type:
		ResourceType.HP: return "生命"
		ResourceType.MP: return "魔力"
		ResourceType.FP: return "专注"
		ResourceType.SHIELD: return "护盾"
	return "资源"
