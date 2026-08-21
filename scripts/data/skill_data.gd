class_name SkillData
extends Resource

enum TargetType {
	ENEMY,
	SELF,
}

enum SkillType {
	PHYSICAL,
	MIND,
	TRANSFORM,
	PASSIVE,
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
@export var skill_type: SkillType = SkillType.PHYSICAL
@export_range(0, 99, 1) var cooldown: int = 0
@export var costs: Array[ActionCostData] = []
@export var target_type: TargetType = TargetType.ENEMY

@export_group("Effects")
@export var effects: Array[ActionEffectData] = []


func get_type_name() -> String:
	match skill_type:
		SkillType.MIND:
			return "灵技"
		SkillType.TRANSFORM:
			return "变化"
		SkillType.PASSIVE:
			return "被动"
		_:
			return "物理"


func get_cooldown() -> int:
	if cooldown > 0:
		return cooldown
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