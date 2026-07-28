class_name SkillData
extends Resource

enum TargetType {
	ENEMY,
	SELF,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D

@export_group("Usage")
@export var mp_cost: float = 0.0
@export var cooldown_seconds: float = 0.0
@export var target_type: TargetType = TargetType.ENEMY

@export_group("Damage")
@export var skill_power: float = 20.0

@export_group("Extra Effects")
@export var effects: Array[SkillEffectData] = []