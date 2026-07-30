class_name EnemyData
extends ActorData

@export_group("Battle")
@export var skills: Array[SkillData] = []

@export_group("Rewards")
@export var experience_reward_override: int = -1
@export_range(0, 999999, 1) var gold_reward: int = 0