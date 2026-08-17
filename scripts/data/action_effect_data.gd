class_name ActionEffectData
extends Resource

enum EffectType {
	ATK,
	DEF,
	SPD,
	RESTORE_HP,
	RESTORE_MP,
	RESTORE_FP,
	FREE_ACTION,
	REDUCE_HP,
	REDUCE_MP,
	REDUCE_FP,
	SKILL_POWER,
	INTERRUPT,
	SHIELD,
	THORNS_REFLECT,
}

enum TargetType {
	SELF,
	ENEMY,
}

enum OperationType {
	ADD,
	MULTIPLY,
}

@export_group("Effect")
@export var effect_type: EffectType = EffectType.ATK
@export var target_type: TargetType = TargetType.SELF
@export var operation_type: OperationType = OperationType.ADD

@export_group("Value")
@export var value: float = 0.0
@export_range(0, 100, 1) var duration_count: int = 1

@export_group("Skill Restriction")
@export var restrict_skill_type: bool = false
@export var target_skill_type: SkillData.SkillType = SkillData.SkillType.PHYSICAL

func get_description() -> String:
	match effect_type:
		EffectType.RESTORE_HP:
			return "生命回复：%.0f" % value
		EffectType.RESTORE_MP:
			return "魔力回复：%.0f" % value
		EffectType.RESTORE_FP:
			return "专注回复：%.0f" % value
		EffectType.FREE_ACTION:
			return "特性：使用后可立刻再次行动"
		EffectType.REDUCE_HP:
			return "造成 %.0f 点技能威力伤害" % value
		EffectType.REDUCE_MP:
			return "扣除 %.0f 点魔力" % value
		EffectType.REDUCE_FP:
			return "扣除 %.0f 点专注" % value
		EffectType.SHIELD:
			if operation_type == OperationType.MULTIPLY:
				return "获得最大生命值 %.0f%% 的护盾" % (value * 100.0)
			else:
				return "获得 %.0f 点护盾" % value
		EffectType.THORNS_REFLECT:
			var type_str = "物理" if restrict_skill_type and target_skill_type == SkillData.SkillType.PHYSICAL else ""
			return "护盾存在时，受%s攻击反弹自身防御力 %.0f%% 的伤害" % [type_str, value * 100.0]
		EffectType.ATK:
			return _get_stat_desc("攻击力")
		EffectType.DEF:
			return _get_stat_desc("防御力")
		EffectType.SPD:
			return _get_stat_desc("速度")
		EffectType.SKILL_POWER:
			return _get_stat_desc("技能威力")
	return ""

func _get_stat_desc(stat_name: String) -> String:
	var prefix = "提升" if operation_type == OperationType.ADD and value > 0 else "降低"
	var type_prefix = ""
	if restrict_skill_type:
		match target_skill_type:
			SkillData.SkillType.PHYSICAL: type_prefix = "物理"
			SkillData.SkillType.MAGICAL: type_prefix = "魔法"
			SkillData.SkillType.TRANSFORM: type_prefix = "变化"
			
	if operation_type == OperationType.MULTIPLY:
		prefix = "提升" if value > 1.0 else "降低"
		var pct = absf(value - 1.0) * 100.0
		return "%s %s%s %.0f%% (剩余 %d 次)" % [prefix, type_prefix, stat_name, pct, duration_count]
	else:
		return "%s %s%s %.0f (剩余 %d 次)" % [prefix, type_prefix, stat_name, absf(value), duration_count]