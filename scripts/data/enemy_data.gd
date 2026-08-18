@tool
class_name EnemyData
extends ActorData

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")
const BASIC_ATTACK: SkillData = preload("res://resources/skills/basic_attack.tres")

@export_group("Battle")
@export var skills: Array[SkillData] = [BASIC_ATTACK]

@export_group("Rewards")
@export var experience_reward_override: int = -1
@export var credit_reward_override: int = -1


func get_credit_reward() -> int:
	if credit_reward_override >= 0:
		return credit_reward_override
	return maxi(1, roundi(FORMULAS.calculate_cp(atk, def, spd)))


@export_group("World Presentation")
@export var world_texture: Texture2D
## 额外视觉缩放倍数。统一由 EnemyData/BossData 控制，避免逐个场景调整。
@export_range(0.1, 5.0, 0.05) var visual_scale_multiplier: float = 1.0


func get_world_texture() -> Texture2D:
	return world_texture if world_texture != null else portrait
