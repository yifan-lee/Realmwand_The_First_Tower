class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
@export var max_hp: float = 100.0
@export var cur_hp: float = 100.0
@export var max_mp: float = 100.0
@export var cur_mp: float = 100.0
@export var atk: float = 10.0
@export var def: float = 10.0
@export var spd: float = 10.0
@export_group("Rewards")
@export var experience_reward_override: int = -1
@export var gold_reward: int = 0
@export var portrait: Texture2D


func get_combat_power(
	balance: BattleBalanceConfig
) -> float:
	return balance.calculate_combat_power(
		max_hp,
		max_mp,
		atk,
		def,
		spd
	)


func get_experience_reward(
	balance: BattleBalanceConfig
) -> int:
	if experience_reward_override >= 0:
		return experience_reward_override

	return balance.calculate_enemy_experience(
		get_combat_power(balance)
	)
