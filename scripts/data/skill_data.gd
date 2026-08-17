class_name SkillData
extends Resource

enum TargetType {
	ENEMY,
	SELF,
}

enum SkillType {
	PHYSICAL,
	MAGICAL,
	TRANSFORM,
	PASSIVE,
}

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Progression")
@export_range(1, 99, 1) var unlock_level: int = 1

@export_group("Usage")
@export var skill_type: SkillType = SkillType.PHYSICAL
@export var costs: Array[ActionCostData] = []
@export var target_type: TargetType = TargetType.ENEMY

@export_group("Effects")
@export var effects: Array[ActionEffectData] = []


func get_type_name() -> String:
	match skill_type:
		SkillType.MAGICAL:
			return "魔法"
		SkillType.TRANSFORM:
			return "变化"
		SkillType.PASSIVE:
			return "被动"
		_:
			return "物理"


func get_details() -> Array[String]:
	var result: Array[String] = []
	result.append("类别：%s" % get_type_name())
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
	for cost: ActionCostData in costs:
		var desc := cost.get_description()
		if not desc.is_empty():
			cost_lines.append("%d. %s" % [cost_idx, desc])
			cost_idx += 1
			
	if not cost_lines.is_empty():
		result.append("\n【消耗】")
		result.append_array(cost_lines)
	elif skill_type != SkillType.PASSIVE:
		result.append("\n【消耗】")
		result.append("1. 无消耗")

	return result