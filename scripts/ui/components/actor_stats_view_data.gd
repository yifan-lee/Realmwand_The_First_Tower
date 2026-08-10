class_name ActorStatsViewData
extends RefCounted

var display_name: String = ""
var description: String = ""
var portrait: Texture2D
var level: int = 0
var experience: int = 0
var experience_to_next_level: int = 0

var current_hp: float = 0.0
var max_hp: float = 0.0
var current_mp: float = 0.0
var max_mp: float = 0.0
var current_fp: float = 0.0
var max_fp: float = 0.0
var start_fp: float = 0.0
var fp_recovery_spd: float = 0.0

var current_atb: float = 0.0
var max_atb: float = 100.0

var current_hp_delta: float = 0.0
var current_mp_delta: float = 0.0
var current_fp_delta: float = 0.0
var current_atb_delta: float = 0.0

var atk: float = 0.0
var def: float = 0.0
var spd: float = 0.0

var max_hp_delta: float = 0.0
var max_mp_delta: float = 0.0
var atk_delta: float = 0.0
var def_delta: float = 0.0
var spd_delta: float = 0.0
var fp_recovery_spd_delta: float = 0.0

var active_effects: Array[Dictionary] = []


func has_progression() -> bool:
	return level > 0


func has_hp_change() -> bool:
	return not is_zero_approx(current_hp_delta)


func has_mp_change() -> bool:
	return not is_zero_approx(current_mp_delta)


func has_fp_change() -> bool:
	return not is_zero_approx(current_fp_delta)


func has_atb_change() -> bool:
	return not is_zero_approx(current_atb_delta)


func has_any_preview() -> bool:
	return (
		has_hp_change()
		or has_mp_change()
		or has_fp_change()
		or has_atb_change()
		or not is_zero_approx(max_hp_delta)
		or not is_zero_approx(max_mp_delta)
		or not is_zero_approx(fp_recovery_spd_delta)
	)


func get_preview_hp() -> float:
	return clampf(current_hp + current_hp_delta, 0.0, maxf(max_hp, 1.0))


func get_preview_max_hp() -> float:
	return maxf(1.0, max_hp + max_hp_delta)


func get_preview_mp() -> float:
	return clampf(current_mp + current_mp_delta, 0.0, maxf(max_mp, 1.0))


func get_preview_max_mp() -> float:
	return maxf(0.0, max_mp + max_mp_delta)


func get_preview_fp() -> float:
	return clampf(current_fp + current_fp_delta, 0.0, maxf(max_fp, 1.0))


func get_preview_atb() -> float:
	return clampf(current_atb + current_atb_delta, 0.0, maxf(max_atb, 1.0))


func get_flash_pulse(time_sec: float = -1.0, speed: float = 8.0) -> float:
	var t := time_sec
	if t < 0.0:
		t = Time.get_ticks_msec() / 1000.0
	return (sin(t * speed) + 1.0) * 0.5


func get_hp_bar_value(time_sec: float = -1.0) -> float:
	if not has_hp_change():
		return current_hp
	return lerpf(current_hp, get_preview_hp(), get_flash_pulse(time_sec))


func get_mp_bar_value(time_sec: float = -1.0) -> float:
	if not has_mp_change():
		return current_mp
	return lerpf(current_mp, get_preview_mp(), get_flash_pulse(time_sec))


func get_fp_bar_value(time_sec: float = -1.0) -> float:
	if not has_fp_change():
		return current_fp
	return lerpf(current_fp, get_preview_fp(), get_flash_pulse(time_sec))


func get_atb_bar_value(time_sec: float = -1.0) -> float:
	if not has_atb_change():
		return current_atb
	return lerpf(current_atb, get_preview_atb(), get_flash_pulse(time_sec))


func preview_skill_cost(costs: Array[ActionCostData]) -> void:
	current_hp_delta = 0.0
	current_mp_delta = 0.0
	current_fp_delta = 0.0
	current_atb_delta = 0.0
	for cost: ActionCostData in costs:
		match cost.cost_type:
			ActionCostData.CostType.HP:
				current_hp_delta -= cost.value
			ActionCostData.CostType.MP:
				current_mp_delta -= cost.value
			ActionCostData.CostType.FP:
				current_fp_delta -= cost.value
			ActionCostData.CostType.CAST_TIME:
				if cost.value > 0.0:
					current_atb_delta -= max_atb * cost.value


func preview_damage(damage: float) -> void:
	current_hp_delta = -damage


func clear_preview() -> void:
	current_hp_delta = 0.0
	current_mp_delta = 0.0
	current_fp_delta = 0.0
	current_atb_delta = 0.0
	max_hp_delta = 0.0
	max_mp_delta = 0.0
	atk_delta = 0.0
	def_delta = 0.0
	spd_delta = 0.0
