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
@export_range(0.0, 9999.0, 0.1) var mp_cost: float = 0.0
@export_range(0.0, 9999.0, 0.1) var fp_cost: float = 0.0
@export_range(0.0, 9999.0, 0.1) var cooldown_seconds: float = 0.0
@export_range(0.0, 1.0, 0.05) var cast_time: float = 0.0
@export var target_type: TargetType = TargetType.ENEMY


@export_group("Effects")
@export var effects: Array[ActionEffectData] = []


func get_type_name() -> String:
	match skill_type:
		SkillType.MAGICAL:
			return "魔法"
		SkillType.TRANSFORM:
			return "变化"
		_:
			return "物理"


func get_details() -> Array[String]:
	return [
		"类型：%s" % get_type_name(),

		"魔力消耗：%.0f" % mp_cost,
		"专注消耗：%.0f" % fp_cost,
		"冷却：%.1f 秒" % cooldown_seconds,
		"吟唱：行动条倒退 %.0f%%" % (cast_time * 100.0),
	]