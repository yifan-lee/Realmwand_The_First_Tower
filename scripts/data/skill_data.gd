class_name SkillData
extends Resource

enum TargetType {
	ENEMY,
	SELF,
}

enum ActivationType {
	ACTIVE = 0, ## 主动
	PASSIVE = 1, ## 被动
}

enum SkillDomain {
	PHYSICAL = 0, ## 物理
	MIND = 1, ## 灵技 / 灵能
	TACTICAL = 2, ## 变化
}

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var exclusive_group: StringName = &""

@export_group("Progression")
@export_range(1, 99, 1) var unlock_level: int = 1

@export_group("Usage")
@export var activation_type: ActivationType = ActivationType.ACTIVE
@export var domain: SkillDomain = SkillDomain.PHYSICAL
@export var costs: Array[ActionCostData] = []
@export var target_type: TargetType = TargetType.ENEMY

@export_group("Effects")
@export var effects: Array[ActionEffectData] = []


func is_passive() -> bool:
	return activation_type == ActivationType.PASSIVE


func get_activation_name() -> String:
	return "主动" if activation_type == ActivationType.ACTIVE else "被动"


func get_domain_name() -> String:
	match domain:
		SkillDomain.MIND:
			return "灵技"
		SkillDomain.TACTICAL:
			return "变化"
		_:
			return "物理"


func get_type_name() -> String:
	return "%s / %s" % [get_activation_name(), get_domain_name()]


func get_cooldown() -> int:
	for cost: ActionCostData in costs:
		if cost != null and cost.cost_type == ActionCostData.CostType.COOLDOWN:
			return cost.get_cooldown()
	return 0


func get_concise_description() -> String:
	var effect_descs: Array[String] = []
	var eff_idx: int = 1
	for effect: ActionEffectData in effects:
		var d := effect.get_description()
		if not d.is_empty():
			effect_descs.append("%d. %s" % [eff_idx, d])
			eff_idx += 1
	var eff_str := "；".join(effect_descs) if not effect_descs.is_empty() else description
	return "【%s】：%s" % [display_name, eff_str]


func get_details() -> Array[String]:
	var result: Array[String] = []
	result.append("类别：%s" % get_type_name())
	if not exclusive_group.is_empty():
		result.append("专属类型：%s (同类限带1个)" % exclusive_group)
	if not description.is_empty():
		result.append("说明：%s" % description)
	
	var effect_lines: Array[String] = []
	var eff_idx: int = 1
	for effect: ActionEffectData in effects:
		var desc := effect.get_description()
		if not desc.is_empty():
			effect_lines.append("%d. %s" % [eff_idx, desc])
			eff_idx += 1
			
	if not effect_lines.is_empty():
		result.append("\n【效果】")
		result.append_array(effect_lines)
		
	var cost_lines: Array[String] = []
	var cost_idx: int = 1
	var cd := get_cooldown()
	if cd > 0:
		cost_lines.append("%d. 冷却：%d 次行动" % [cost_idx, cd])
		cost_idx += 1
		
	for cost: ActionCostData in costs:
		if cost == null or cost.cost_type == ActionCostData.CostType.COOLDOWN:
			continue
		var desc := cost.get_description()
		if not desc.is_empty():
			cost_lines.append("%d. %s" % [cost_idx, desc])
			cost_idx += 1
			
	if not cost_lines.is_empty():
		result.append("\n【消耗】")
		result.append_array(cost_lines)

	return result