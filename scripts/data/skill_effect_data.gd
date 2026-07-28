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

@export var effect_type: EffectType
@export var target_type: TargetType
@export var operation_type: OperationType = OperationType.ADD
@export var value: float = 0.0
@export var duration_actions: int = 0