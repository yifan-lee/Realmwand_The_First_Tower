class_name ActorStatsContext
extends RefCounted

var current_atb: float = 0.0
var max_atb: float = 100.0
var effective_atk: float = -1.0
var effective_def: float = -1.0
var effective_spd: float = -1.0
var active_effects: Array[Dictionary] = []


func has_override_atk() -> bool:
	return effective_atk >= 0.0


func has_override_def() -> bool:
	return effective_def >= 0.0


func has_override_spd() -> bool:
	return effective_spd >= 0.0
