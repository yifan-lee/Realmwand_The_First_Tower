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
@export_range(0.0, 999.0, 0.1) var duration_seconds: float = 0.0

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
		EffectType.ATK:
			return _get_stat_desc("攻击力")
		EffectType.DEF:
			return _get_stat_desc("防御力")
		EffectType.SPD:
			return _get_stat_desc("速度")
	return ""

func _get_stat_desc(stat_name: String) -> String:
	var prefix = "提升" if operation_type == OperationType.ADD and value > 0 else "降低"
	if operation_type == OperationType.MULTIPLY:
		prefix = "提升" if value > 1.0 else "降低"
		var pct = absf(value - 1.0) * 100.0
		return "%s %s %.0f%% (持续 %.1f 秒)" % [prefix, stat_name, pct, duration_seconds]
	else:
		return "%s %s %.0f (持续 %.1f 秒)" % [prefix, stat_name, absf(value), duration_seconds]