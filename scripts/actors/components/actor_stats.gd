class_name ActorStats
extends Node

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal stats_changed

var current_hp: float = 0.0
var current_mp: float = 0.0
var current_fp: float = 0.0
var current_shield: float = 0.0

var base_atk: float = 0.0
var base_def: float = 0.0
var base_spd: float = 0.0

# Virtual methods to be overridden by subclasses
func get_max_hp() -> float: return 0.0
func get_max_mp() -> float: return 0.0
func get_max_fp() -> float: return 0.0
func get_fp_recovery_spd() -> float: return 0.0
func get_atk() -> float: return base_atk
func get_def() -> float: return base_def
func get_spd() -> float: return base_spd


## 获得护盾（不叠加机制：刷新为当前与新值的最大值）
func add_shield(amount: float) -> void:
	if amount <= 0.0:
		return
	current_shield = maxf(current_shield, amount)
	stats_changed.emit()


## 清除护盾（战斗结束或破盾时调用）
func clear_shield() -> void:
	if current_shield > 0.0:
		current_shield = 0.0
		stats_changed.emit()


func take_damage(amount: float) -> float:
	if amount <= 0.0 or (current_hp <= 0.0 and current_shield <= 0.0):
		return 0.0

	var remaining := amount
	if current_shield > 0.0:
		var shield_absorbed := minf(remaining, current_shield)
		current_shield -= shield_absorbed
		remaining -= shield_absorbed

	var applied_hp_damage := 0.0
	if remaining > 0.0 and current_hp > 0.0:
		applied_hp_damage = minf(remaining, current_hp)
		current_hp -= applied_hp_damage

	stats_changed.emit()
	return (amount - remaining) + applied_hp_damage


func set_current_hp(value: float) -> void:
	var next_hp := clampf(value, 0.0, get_max_hp())
	if is_equal_approx(current_hp, next_hp):
		return
	current_hp = next_hp
	stats_changed.emit()


func change_hp(amount: float) -> void:
	if amount < 0.0:
		take_damage(-amount)
	else:
		set_current_hp(current_hp + amount)


func set_current_mp(value: float) -> void:
	var next_mp := clampf(value, 0.0, get_max_mp())
	if is_equal_approx(current_mp, next_mp):
		return
	current_mp = next_mp
	stats_changed.emit()


func change_mp(amount: float) -> void:
	set_current_mp(current_mp + amount)


func set_current_fp(value: float) -> void:
	var next_fp := clampf(value, 0.0, get_max_fp())
	if is_equal_approx(current_fp, next_fp):
		return
	current_fp = next_fp
	stats_changed.emit()


func change_fp(amount: float) -> void:
	set_current_fp(current_fp + amount)
