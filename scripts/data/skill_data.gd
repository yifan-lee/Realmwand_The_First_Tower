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

@export_group("Damage")
@export_range(0.0, 99999.0, 0.1) var skill_power: float = 0.0

@export_group("Effects")
@export var effects: Array[SkillEffectData] = []