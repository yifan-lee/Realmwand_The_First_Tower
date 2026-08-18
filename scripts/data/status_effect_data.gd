@tool
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
	ON_TAKE_PHYSICAL_DAMAGE,
	ON_TAKE_MAGICAL_DAMAGE,
	ON_DEAL_DAMAGE,
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
## 是否在战斗界面的 Buff 栏位中显示
@export var show_in_buff_bar: bool = true

@export_group("Effect")
@export var affected_stat: StatType = StatType.ATK
@export var operation: OpType = OpType.MULTIPLY
@export var value: float = 1.2
@export var restrict_skill_type: bool = false
@export var target_skill_type: SkillType = SkillType.PHYSICAL
## 反伤：受到伤害时对攻击者造成的固定伤害值
@export var counter_damage_fixed: float = 0.0
## 反伤：受到伤害时对攻击者造成的百分比伤害（例如 0.1 代表 10%）
@export var counter_damage_ratio: float = 0.0

@export_group("Expiry & Stacking")
@export var end_condition: EndCondition = EndCondition.OWNER_ACTIONS
## 持续次数。为 0 表示永不结束（直到战斗结束或被清除）。
@export var duration_count: int = 1
@export var trigger_type: TriggerType = TriggerType.ON_ANY_ACTION
## 循环触发周期。例如为 4 时表示每第 4 次触发该效果（用于如每4次攻击增伤等被动）。为 1 时表示每次都生效。
@export_range(1, 99, 1) var trigger_interval: int = 1
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


func get_formatted_description(remaining: int = -1, stacks: int = 1, remaining_to_interval: int = 0) -> String:
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
			"remaining_to_interval": str(remaining_to_interval),
			"trigger_interval": str(trigger_interval),
			"counter_damage_fixed": "%.0f" % counter_damage_fixed,
			"counter_damage_ratio": "%.0f%%" % (counter_damage_ratio * 100.0),
		})

	# 反伤逻辑文本生成
	if counter_damage_fixed > 0.0 or counter_damage_ratio > 0.0:
		var target_type_str := "物理" if trigger_type == TriggerType.ON_TAKE_PHYSICAL_DAMAGE else ("魔法" if trigger_type == TriggerType.ON_TAKE_MAGICAL_DAMAGE else "")
		var counter_desc := ""
		if counter_damage_fixed > 0.0 and counter_damage_ratio > 0.0:
			counter_desc = "受到%s攻击时，对攻击者反弹 %.0f 点固定伤害与 %.0f%% 受到的伤害" % [target_type_str, counter_damage_fixed, counter_damage_ratio * 100.0]
		elif counter_damage_fixed > 0.0:
			counter_desc = "受到%s攻击时，对攻击者反弹 %.0f 点伤害" % [target_type_str, counter_damage_fixed]
		else:
			counter_desc = "受到%s攻击时，对攻击者反弹 %.0f%% 受到的伤害" % [target_type_str, counter_damage_ratio * 100.0]
		return "【%s】：1. %s。" % [name_to_use, counter_desc]

	# 周期触发逻辑文本生成
	if trigger_interval > 1:
		var prefix := "提升" if (operation == OpType.MULTIPLY and value >= 1.0) or (operation == OpType.ADD and value >= 0.0) else "降低"
		if remaining_to_interval == 1:
			return "【%s】：准备就绪！下次攻击造成伤害%s" % [name_to_use, value_str]
		var rem := remaining_to_interval if remaining_to_interval > 0 else trigger_interval
		return "【%s】：第%d次攻击造成的伤害增加%s。还剩%d次。" % [name_to_use, trigger_interval, pct_str, rem]

	# 默认文案生成
	var prefix := "提升" if (operation == OpType.MULTIPLY and value >= 1.0) or (operation == OpType.ADD and value >= 0.0) else "降低"
	var desc := "%s%s %s%s" % [prefix, skill_type_str, stat_name, value_str]
	if stacks > 1:
		desc += " (%d层)" % stacks
	if not duration_str.is_empty():
		desc += " (%s)" % duration_str
	return desc
