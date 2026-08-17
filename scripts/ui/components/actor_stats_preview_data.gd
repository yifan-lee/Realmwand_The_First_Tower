class_name ActorStatsPreviewData
extends RefCounted

var current_hp_delta: float = 0.0
var current_shield_delta: float = 0.0
var current_mp_delta: float = 0.0
var current_fp_delta: float = 0.0
var current_atb_delta: float = 0.0

var max_hp_delta: float = 0.0
var max_mp_delta: float = 0.0
var max_fp_delta: float = 0.0
var start_fp_delta: float = 0.0
var atk_delta: float = 0.0
var def_delta: float = 0.0
var spd_delta: float = 0.0
var fp_recovery_spd_delta: float = 0.0
var cp_delta: float = 0.0


func has_hp_change() -> bool:
	return not is_zero_approx(current_hp_delta) or not is_zero_approx(max_hp_delta)


func has_shield_change() -> bool:
	return not is_zero_approx(current_shield_delta)


func has_mp_change() -> bool:
	return not is_zero_approx(current_mp_delta) or not is_zero_approx(max_mp_delta)


func has_fp_change() -> bool:
	return (
		not is_zero_approx(current_fp_delta)
		or not is_zero_approx(max_fp_delta)
		or not is_zero_approx(start_fp_delta)
		or not is_zero_approx(fp_recovery_spd_delta)
	)


func has_atb_change() -> bool:
	return not is_zero_approx(current_atb_delta)


func has_combat_stat_change() -> bool:
	return not is_zero_approx(atk_delta) or not is_zero_approx(def_delta) or not is_zero_approx(spd_delta)


func has_any_preview() -> bool:
	return (
		has_hp_change()
		or has_shield_change()
		or has_mp_change()
		or has_fp_change()
		or has_atb_change()
		or has_combat_stat_change()
		or not is_zero_approx(cp_delta)
	)


func clear() -> void:
	current_hp_delta = 0.0
	current_shield_delta = 0.0
	current_mp_delta = 0.0
	current_fp_delta = 0.0
	current_atb_delta = 0.0
	max_hp_delta = 0.0
	max_mp_delta = 0.0
	max_fp_delta = 0.0
	start_fp_delta = 0.0
	atk_delta = 0.0
	def_delta = 0.0
	spd_delta = 0.0
	fp_recovery_spd_delta = 0.0
	cp_delta = 0.0
