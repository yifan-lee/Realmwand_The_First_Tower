class_name PlayerProgression
extends Node

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal level_up_available
signal skill_learned(skill: SkillData)

var level: int = 1
var experience: int = 0
var gold: int = 0
var unspent_stat_points: int = 0

var learned_skills: Array[SkillData] = []
var pending_learned_skills: Array[SkillData] = []

var _player_data: PlayerData
var _stats: PlayerStats


func initialize(data: PlayerData, stats: PlayerStats) -> void:
	_player_data = data
	_stats = stats
	
	level = _player_data.starting_level
	experience = _player_data.starting_experience
	gold = _player_data.starting_gold
	learned_skills = _player_data.starting_skills.duplicate()


func get_experience_for_next_level() -> int:
	return FORMULAS.experience_for_next_level(level)


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	var leveled_up := false

	while experience >= get_experience_for_next_level():
		experience -= get_experience_for_next_level()
		level += 1
		
		# Auto stat increases
		_stats.base_atk += FORMULAS.AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL
		_stats.base_def += FORMULAS.AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL
		_stats.base_spd += FORMULAS.AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL
		unspent_stat_points += FORMULAS.FREE_STAT_POINTS_PER_LEVEL
		leveled_up = true

		if _player_data.level_skills.has(level):
			var new_skill: SkillData = _player_data.level_skills[level]
			if not learned_skills.has(new_skill):
				learned_skills.append(new_skill)
				pending_learned_skills.append(new_skill)
				skill_learned.emit(new_skill)

	_stats.stats_changed.emit()

	if leveled_up:
		level_up_available.emit()


func spend_stat_point(stat_id: StringName) -> bool:
	if unspent_stat_points <= 0:
		return false

	match stat_id:
		&"atk":
			_stats.base_atk += FORMULAS.stat_point_increase(stat_id)
		&"def":
			_stats.base_def += FORMULAS.stat_point_increase(stat_id)
		&"spd":
			_stats.base_spd += FORMULAS.stat_point_increase(stat_id)
		_:
			return false

	unspent_stat_points -= 1
	_stats.stats_changed.emit()
	return true


func apply_stat_allocation(allocation: Dictionary[StringName, int]) -> bool:
	var total_points := 0
	for stat_id: StringName in [&"atk", &"def", &"spd"]:
		var points: int = int(allocation.get(stat_id, 0))
		if points < 0:
			return false
		total_points += points
		
	if total_points <= 0 or total_points > unspent_stat_points:
		return false

	var previous_max_hp: float = _stats.get_max_hp()
	var previous_max_mp: float = _stats.get_max_mp()
	var increase: float = FORMULAS.stat_point_increase(&"atk")
	
	_stats.base_atk += int(allocation.get(&"atk", 0)) * increase
	_stats.base_def += int(allocation.get(&"def", 0)) * increase
	_stats.base_spd += int(allocation.get(&"spd", 0)) * increase
	unspent_stat_points -= total_points
	
	if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE:
		_stats.current_hp = clampf(_stats.current_hp + _stats.get_max_hp() - previous_max_hp, 0.0, _stats.get_max_hp())
		_stats.current_mp = clampf(_stats.current_mp + _stats.get_max_mp() - previous_max_mp, 0.0, _stats.get_max_mp())
	else:
		_stats.current_hp = minf(_stats.current_hp, _stats.get_max_hp())
		_stats.current_mp = minf(_stats.current_mp, _stats.get_max_mp())
		
	_stats.stats_changed.emit()
	return true


func apply_permanent_stat_increase(stat_id: StringName, amount: float) -> bool:
	if amount <= 0.0 or stat_id not in [&"atk", &"def", &"spd"]:
		return false
		
	var previous_max_hp := _stats.get_max_hp()
	var previous_max_mp := _stats.get_max_mp()
	
	match stat_id:
		&"atk": _stats.base_atk += amount
		&"def": _stats.base_def += amount
		&"spd": _stats.base_spd += amount
		
	if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE:
		_stats.current_hp = clampf(_stats.current_hp + _stats.get_max_hp() - previous_max_hp, 0.0, _stats.get_max_hp())
		_stats.current_mp = clampf(_stats.current_mp + _stats.get_max_mp() - previous_max_mp, 0.0, _stats.get_max_mp())
	else:
		_stats.current_hp = minf(_stats.current_hp, _stats.get_max_hp())
		_stats.current_mp = minf(_stats.current_mp, _stats.get_max_mp())
		
	_stats.stats_changed.emit()
	return true


func get_stat_allocation_preview(allocation: Dictionary[StringName, int]) -> Dictionary[StringName, float]:
	var atk_points: int = int(allocation.get(&"atk", 0))
	var def_points: int = int(allocation.get(&"def", 0))
	var spd_points: int = int(allocation.get(&"spd", 0))
	var increase: float = FORMULAS.stat_point_increase(&"atk")
	
	var next_base_atk: float = _stats.base_atk + atk_points * increase
	var next_base_def: float = _stats.base_def + def_points * increase
	var next_base_spd: float = _stats.base_spd + spd_points * increase
	
	var equip_max_hp := _stats._equipment.get_max_hp_bonus() if _stats._equipment else 0.0
	var equip_max_mp := _stats._equipment.get_max_mp_bonus() if _stats._equipment else 0.0
	
	var next_max_hp: float = FORMULAS.resolve_base_max_hp(_stats.base_max_hp, next_base_def, next_base_spd) + equip_max_hp
	var next_max_mp: float = FORMULAS.resolve_base_max_mp(_stats.base_max_mp, next_base_atk, next_base_spd) + equip_max_mp

	var hp_increase := next_max_hp - _stats.get_max_hp()
	var mp_increase := next_max_mp - _stats.get_max_mp()
	
	var equip_atk := _stats._equipment.get_atk_bonus() if _stats._equipment else 0.0
	var equip_def := _stats._equipment.get_def_bonus() if _stats._equipment else 0.0
	var equip_spd := _stats._equipment.get_spd_bonus() if _stats._equipment else 0.0
	
	return {
		&"current_hp": _stats.current_hp + hp_increase if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE else _stats.current_hp,
		&"max_hp": next_max_hp,
		&"current_mp": _stats.current_mp + mp_increase if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE else _stats.current_mp,
		&"max_mp": next_max_mp,
		&"fp_recovery": FORMULAS.resolve_base_fp_recovery(_stats.base_fp_recovery_spd, next_base_atk, next_base_def),
		&"atk": next_base_atk + equip_atk,
		&"def": next_base_def + equip_def,
		&"spd": next_base_spd + equip_spd,
	}


func get_permanent_stat_increase_preview(stat_id: StringName, amount: float) -> Dictionary[StringName, float]:
	var next_base_atk := _stats.base_atk
	var next_base_def := _stats.base_def
	var next_base_spd := _stats.base_spd
	
	if amount > 0.0:
		match stat_id:
			&"atk": next_base_atk += amount
			&"def": next_base_def += amount
			&"spd": next_base_spd += amount

	var equip_max_hp := _stats._equipment.get_max_hp_bonus() if _stats._equipment else 0.0
	var equip_max_mp := _stats._equipment.get_max_mp_bonus() if _stats._equipment else 0.0
	
	var next_max_hp: float = FORMULAS.resolve_base_max_hp(_stats.base_max_hp, next_base_def, next_base_spd) + equip_max_hp
	var next_max_mp: float = FORMULAS.resolve_base_max_mp(_stats.base_max_mp, next_base_atk, next_base_spd) + equip_max_mp
	var hp_increase := next_max_hp - _stats.get_max_hp()
	var mp_increase := next_max_mp - _stats.get_max_mp()
	
	var equip_atk := _stats._equipment.get_atk_bonus() if _stats._equipment else 0.0
	var equip_def := _stats._equipment.get_def_bonus() if _stats._equipment else 0.0
	var equip_spd := _stats._equipment.get_spd_bonus() if _stats._equipment else 0.0
	
	return {
		&"current_hp": _stats.current_hp + hp_increase if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE else _stats.current_hp,
		&"max_hp": next_max_hp,
		&"current_mp": _stats.current_mp + mp_increase if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE else _stats.current_mp,
		&"max_mp": next_max_mp,
		&"fp_recovery": FORMULAS.resolve_base_fp_recovery(_stats.base_fp_recovery_spd, next_base_atk, next_base_def),
		&"atk": next_base_atk + equip_atk,
		&"def": next_base_def + equip_def,
		&"spd": next_base_spd + equip_spd,
	}


func get_stat_upgrade_preview(stat_id: StringName) -> Dictionary[StringName, float]:
	var next_atk := _stats.base_atk
	var next_def := _stats.base_def
	var next_spd := _stats.base_spd
	var increase := FORMULAS.stat_point_increase(stat_id)
	match stat_id:
		&"atk": next_atk += increase
		&"def": next_def += increase
		&"spd": next_spd += increase
		_: return {}
		
	return {
		&"max_hp": FORMULAS.resolve_base_max_hp(_stats.base_max_hp, next_def, next_spd) - _stats.get_max_hp(),
		&"max_mp": FORMULAS.resolve_base_max_mp(_stats.base_max_mp, next_atk, next_spd) - _stats.get_max_mp(),
		&"fp_recovery": FORMULAS.resolve_base_fp_recovery(_stats.base_fp_recovery_spd, next_atk, next_def) - _stats.get_fp_recovery_spd(),
	}
