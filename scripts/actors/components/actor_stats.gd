class_name ActorStats
extends Node

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal stats_changed

var current_hp: float = 0.0
var current_mp: float = 0.0
var current_fp: float = 0.0

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


func take_damage(amount: float) -> float:
	if amount <= 0.0 or current_hp <= 0.0:
		return 0.0

	var applied_damage: float = minf(amount, current_hp)
	current_hp -= applied_damage
	stats_changed.emit()

	return applied_damage


func set_current_hp(value: float) -> void:
	var next_hp := clampf(value, 0.0, get_max_hp())
	if is_equal_approx(current_hp, next_hp):
		return
	current_hp = next_hp
	stats_changed.emit()


func change_hp(amount: float) -> void:
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
