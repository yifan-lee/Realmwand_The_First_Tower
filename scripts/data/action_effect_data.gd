class_name ActionEffectData
extends Resource

enum TargetType {
	SELF,
	OPPONENT,
	ALL,
}

enum EffectCategory {
	RESOURCE,
	STATUS,
	SPECIAL,
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

enum SpecialType {
	INTERRUPT,
	FREE_ACTION,
}

@export var category: EffectCategory = EffectCategory.RESOURCE
@export var target: TargetType = TargetType.OPPONENT

@export_group("Resource Details")
@export var resource_type: ResourceType = ResourceType.HP
@export var calc_method: CalcMethod = CalcMethod.SKILL_POWER
@export var value: float = 0.0

@export_group("Status Details")
@export var status_to_apply: StatusEffectData = null

@export_group("Special Details")
@export var special_type: SpecialType = SpecialType.INTERRUPT


func is_interrupt() -> bool:
	return category == EffectCategory.SPECIAL and special_type == SpecialType.INTERRUPT


func is_free_action() -> bool:
	return category == EffectCategory.SPECIAL and special_type == SpecialType.FREE_ACTION


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
	var target_prefix := get_target_prefix()
	match category:
		EffectCategory.SPECIAL:
			match special_type:
				SpecialType.INTERRUPT:
					return "%s打断吟唱" % target_prefix
				SpecialType.FREE_ACTION:
					return "自由动作（不消耗行动机会）"
			return ""
		EffectCategory.STATUS:
			if status_to_apply != null:
				var status_desc := status_to_apply.get_formatted_description()
				var status_name := status_to_apply.display_name if not status_to_apply.display_name.is_empty() else status_to_apply.get_stat_name()
				if not status_desc.is_empty():
					if status_desc.begins_with("【"):
						return status_desc
					else:
						return "%s施加【%s】：%s" % [target_prefix, status_name, status_desc]
			return ""
		EffectCategory.RESOURCE:
			if resource_type == ResourceType.NONE or is_zero_approx(value):
				return ""
			var res_name := _get_resource_name()
			match calc_method:
				CalcMethod.SKILL_POWER:
					if value > 0:
						return "%s造成伤害，技能威力 %.0f " % [target_prefix, value]
					else:
						return "%s恢复生命，技能威力 %.0f " % [target_prefix, absf(value)]
				CalcMethod.FIXED_AMOUNT:
					if value > 0:
						if resource_type == ResourceType.SHIELD:
							return "%s获得 %.0f 点护盾" % [target_prefix, value]
						else:
							return "%s恢复 %.0f 点%s" % [target_prefix, value, res_name]
					else:
						return "%s减少 %.0f 点%s" % [target_prefix, absf(value), res_name]
				CalcMethod.MAX_RATIO:
					if value > 0:
						if resource_type == ResourceType.SHIELD:
							return "%s获得最大生命值 %.0f%% 的护盾" % [target_prefix, value * 100.0]
						else:
							return "%s恢复最大%s %.0f%%" % [target_prefix, res_name, value * 100.0]
					else:
						return "%s减少最大%s %.0f%%" % [target_prefix, res_name, absf(value) * 100.0]
	return ""


func _get_resource_name() -> String:
	match resource_type:
		ResourceType.HP: return "生命"
		ResourceType.MP: return "灵能"
		ResourceType.FP: return "专注"
		ResourceType.SHIELD: return "护盾"
	return "资源"
