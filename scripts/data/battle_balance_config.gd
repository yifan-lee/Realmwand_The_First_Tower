class_name BattleBalanceConfig
extends Resource

@export_group("Damage")
@export var basic_attack_power: float = 20.0
@export var attack_reference: float = 20.0
@export var defense_reference: float = 20.0
@export var minimum_damage: int = 1

@export_group("ATB")
@export var base_fill_time: float = 2.0
@export var speed_reference: float = 80.0

@export_group("Progression")
@export var experience_requirement_base: int = 50
@export var experience_requirement_per_level: int = 10
@export var enemy_experience_divisor: float = 5.0
@export var free_attribute_points_per_level: int = 5

@export_group("Attribute Point Value")
@export var hp_per_point: float = 10.0
@export var mp_per_point: float = 5.0
@export var atk_per_point: float = 1.0
@export var def_per_point: float = 2.0
@export var spd_per_point: float = 5.0


func calculate_damage(
	atk: float,
	def: float,
	skill_power: float
) -> int:
	if atk <= 0.0 or skill_power <= 0.0:
		return 0

	var safe_atk := maxf(atk, 0.0)
	var safe_def := maxf(def, 0.0)

	var attack_multiplier := (
		safe_atk / maxf(attack_reference, 0.01)
	)

	var defense_multiplier := (
		defense_reference
		/ (defense_reference + safe_def)
	)

	var raw_damage := (
		skill_power
		* attack_multiplier
		* defense_multiplier
	)

	return maxi(roundi(raw_damage), minimum_damage)


func get_atb_fill_time(spd: float) -> float:
	var safe_spd := maxf(spd, 0.0)
	var safe_reference := maxf(speed_reference, 0.01)

	return (
		base_fill_time
		* safe_reference
		/ (safe_reference + safe_spd)
	)


func get_atb_rate(
	spd: float,
	atb_max: float
) -> float:
	return atb_max / get_atb_fill_time(spd)


func get_experience_requirement(current_level: int) -> int:
	return (
		experience_requirement_base
		+ experience_requirement_per_level * current_level
	)


func calculate_combat_power(
	max_hp: float,
	max_mp: float,
	atk: float,
	def: float,
	spd: float
) -> float:
	return (
		max_hp / maxf(hp_per_point, 0.01)
		+ max_mp / maxf(mp_per_point, 0.01)
		+ atk / maxf(atk_per_point, 0.01)
		+ def / maxf(def_per_point, 0.01)
		+ spd / maxf(spd_per_point, 0.01)
	)


func calculate_enemy_experience(combat_power: float) -> int:
	return maxi(
		roundi(
			combat_power
			/ maxf(enemy_experience_divisor, 0.01)
		),
		1
	)
