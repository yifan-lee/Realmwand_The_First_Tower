class_name StatusEffectData
extends Resource

enum Polarity {
	BUFF,
	DEBUFF,
	NEUTRAL,
}

enum StatType {
	ATK,
	DEF,
	SPD,
	SKILL_POWER,
	MAX_HP,
	MAX_MP,
}

enum OpType {
	ADD,
	MULTIPLY,
}

enum EndCondition {
	PERMANENT,
	OWNER_ACTIONS,
	SHIELD_DEPLETED,
	TRIGGER_COUNT,
}

enum TriggerType {
	ON_ANY_ACTION,
	ON_PHYSICAL_ATTACK,
	ON_MAGICAL_ATTACK,
}

enum StackPolicy {
	REFRESH,
	ADD_STACK,
	EXTEND,
	INDEPENDENT,
	REPLACE,
}

enum SkillType {
	PHYSICAL,
	MAGICAL,
	TRANSFORM,
	PASSIVE,
}

@export_group("Identity & UI")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var display_template: String = ""
@export var icon: Texture2D
@export var polarity: Polarity = Polarity.BUFF

@export_group("Effect")
@export var affected_stat: StatType = StatType.ATK
@export var operation: OpType = OpType.MULTIPLY
@export var value: float = 1.2
@export var restrict_skill_type: bool = false
@export var target_skill_type: SkillType = SkillType.PHYSICAL

@export_group("Expiry & Stacking")
@export var end_condition: EndCondition = EndCondition.OWNER_ACTIONS
## 持续次数。为 0 表示永不结束（直到战斗结束或被清除）。
@export var duration_count: int = 1
@export var trigger_type: TriggerType = TriggerType.ON_ANY_ACTION
@export var stack_policy: StackPolicy = StackPolicy.REFRESH
@export var max_stacks: int = 1


func get_stat_name() -> String:
	match affected_stat:
		StatType.ATK: return "攻击力"
		StatType.DEF: return "防御力"
		StatType.SPD: return "速度"
		StatType.SKILL_POWER: return "技能威力"
		StatType.MAX_HP: return "最大生命"
		StatType.MAX_MP: return "最大魔力"
	return "属性"


func get_skill_type_name() -> String:
	if not restrict_skill_type:
		return ""
	match target_skill_type:
		SkillType.PHYSICAL: return "物理"
		SkillType.MAGICAL: return "魔法"
		SkillType.TRANSFORM: return "变化"
		SkillType.PASSIVE: return "被动"
	return ""


func get_formatted_description(remaining: int = -1, stacks: int = 1) -> String:
	var name_to_use: String = display_name if not display_name.is_empty() else get_stat_name()
	var stat_name := get_stat_name()
	var skill_type_str := get_skill_type_name()

	var value_str := ""
	var pct_str := ""
	if operation == OpType.MULTIPLY:
		var pct := absf(value - 1.0) * 100.0 * stacks
		pct_str = "%.0f%%" % pct
		value_str = "%+.0f%%" % ((value - 1.0) * 100.0 * stacks)
	else:
		var total_val := value * stacks
		value_str = "%+.0f" % total_val
		pct_str = "%.0f" % absf(total_val)

	var duration_str := ""
	if end_condition == EndCondition.PERMANENT or duration_count == 0:
		duration_str = "常驻"
	elif remaining >= 0:
		duration_str = "剩 %d 次" % remaining
	elif duration_count > 0:
		duration_str = "持续 %d 次" % duration_count

	if not display_template.is_empty():
		return display_template.format({
			"name": name_to_use,
			"stat_name": stat_name,
			"skill_type": skill_type_str,
			"value": value_str,
			"pct": pct_str,
			"remaining": str(remaining) if remaining >= 0 else str(duration_count),
			"owner_actions": str(remaining) if remaining >= 0 else str(duration_count),
			"stacks": str(stacks),
			"duration": duration_str,
		})

	# 默认文案生成
	var prefix := "提升" if (operation == OpType.MULTIPLY and value >= 1.0) or (operation == OpType.ADD and value >= 0.0) else "降低"
	var desc := "%s%s %s%s" % [prefix, skill_type_str, stat_name, value_str]
	if stacks > 1:
		desc += " (%d层)" % stacks
	if not duration_str.is_empty():
		desc += " (%s)" % duration_str
	return desc
