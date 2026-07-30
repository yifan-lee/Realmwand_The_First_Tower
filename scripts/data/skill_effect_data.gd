class_name SkillEffectData
extends Resource

enum EffectType {
	ATK,
	DEF,
	SPD,
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
@export_range(0.1, 999.0, 0.1) var duration_seconds: float = 5.0