class_name GameFormulas
extends RefCounted

const ATB_MAX: float = 100.0
const MIN_DAMAGE: float = 1.0
const EXPERIENCE_PER_LEVEL: int = 10
const BASE_EXPERIENCE: int = 50
const AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL: float = 1.0
const FREE_STAT_POINTS_PER_LEVEL: int = 6
const BASE_MAX_HP_COEFFICIENT: float = 4.0
const BASE_MAX_MP_COEFFICIENT: float = 2.0
const BASE_FP_RECOVERY_COEFFICIENT: float = 0.1
const CP_DIVISOR: float = 10.0


static func calculate_atb_gain(
	speed: float,
	delta: float
) -> float:
	return maxf(0.0, speed) * maxf(0.0, delta)


static func calculate_fp_recovery(
	recovery_spd: float,
	delta: float
) -> float:
	return maxf(0.0, recovery_spd) * maxf(0.0, delta)


static func calculate_atb_after_cast(
	cast_time: float
) -> float:
	return ATB_MAX * (1.0 - clampf(cast_time, 0.0, 1.0))


static func calculate_skill_damage(
	attack: float,
	skill_power: float,
	defense: float
) -> float:
	return maxf(
		MIN_DAMAGE,
		attack * skill_power / defense
	)


static func calculate_recovery_delta(
	current_value: float,
	maximum_value: float,
	recovery: float
) -> float:
	return clampf(
		recovery,
		0.0,
		maxf(0.0, maximum_value - current_value)
	)


static func experience_for_next_level(
	current_level: int
) -> int:
	return maxi(1, current_level) * EXPERIENCE_PER_LEVEL + BASE_EXPERIENCE


static func calculate_default_max_hp(
	defense: float,
	speed: float
) -> float:
	return maxf(1.0, (defense + speed) * BASE_MAX_HP_COEFFICIENT)


static func calculate_default_max_mp(
	attack: float,
	speed: float
) -> float:
	return maxf(0.0, (attack + speed) * BASE_MAX_MP_COEFFICIENT)


static func calculate_default_fp_recovery(
	attack: float,
	defense: float
) -> float:
	return maxf(0.0, (attack + defense) * BASE_FP_RECOVERY_COEFFICIENT)


static func resolve_base_max_hp(
	override_value: float,
	defense: float,
	speed: float
) -> float:
	return override_value if override_value > 0.0 else calculate_default_max_hp(defense, speed)


static func resolve_base_max_mp(
	override_value: float,
	attack: float,
	speed: float
) -> float:
	return override_value if override_value > 0.0 else calculate_default_max_mp(attack, speed)


static func resolve_base_fp_recovery(
	override_value: float,
	attack: float,
	defense: float
) -> float:
	return override_value if override_value > 0.0 else calculate_default_fp_recovery(attack, defense)


static func calculate_cp(
	attack: float,
	defense: float,
	speed: float
) -> float:
	return maxf(0.0, (attack + defense + speed) / CP_DIVISOR)


static func default_enemy_experience(
	attack: float,
	defense: float,
	speed: float
) -> int:
	return maxi(1, roundi(calculate_cp(attack, defense, speed)))


static func stat_point_increase(_stat_id: StringName) -> float:
	return AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL


static func skill_effect_delta(
	base_value: float,
	effect: SkillEffectData
) -> float:
	if effect == null:
		return 0.0
	if effect.operation_type == SkillEffectData.OperationType.MULTIPLY:
		return base_value * (effect.value - 1.0)
	return effect.value


static func calculate_effective_stat(
	base_value: float,
	active_effects: Array[Dictionary],
	effect_type: int
) -> float:
	var added_value := 0.0
	var multiplier := 1.0
	for active: Dictionary in active_effects:
		var effect: SkillEffectData = active.get(&"effect") as SkillEffectData
		if effect == null or effect.effect_type != effect_type:
			continue
		if effect.operation_type == SkillEffectData.OperationType.MULTIPLY:
			multiplier *= effect.value
		else:
			added_value += effect.value
	return maxf(0.0, (base_value + added_value) * multiplier)


static func equipment_delta(
	candidate: EquipmentData,
	displaced_items: Array[EquipmentData]
) -> Dictionary[StringName, float]:
	var result: Dictionary[StringName, float] = {
		&"max_hp": candidate.max_hp_bonus,
		&"max_mp": candidate.max_mp_bonus,
		&"atk": candidate.atk_bonus,
		&"def": candidate.def_bonus,
		&"spd": candidate.spd_bonus,
	}

	for item: EquipmentData in displaced_items:
		result[&"max_hp"] -= item.max_hp_bonus
		result[&"max_mp"] -= item.max_mp_bonus
		result[&"atk"] -= item.atk_bonus
		result[&"def"] -= item.def_bonus
		result[&"spd"] -= item.spd_bonus

	return result
