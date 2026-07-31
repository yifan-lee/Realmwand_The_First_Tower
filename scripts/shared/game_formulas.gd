class_name GameFormulas
extends RefCounted

const ATB_MAX: float = 100.0
const MIN_DAMAGE: float = 1.0
const EXPERIENCE_PER_LEVEL: int = 100
const STAT_POINTS_PER_LEVEL: int = 5


static func calculate_atb_gain(
	speed: float,
	delta: float
) -> float:
	return maxf(0.0, speed) * maxf(0.0, delta)


static func calculate_skill_damage(
	attack: float,
	skill_power: float,
	defense: float
) -> float:
	return maxf(
		MIN_DAMAGE,
		attack + skill_power - defense
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
	return maxi(1, current_level) * EXPERIENCE_PER_LEVEL


static func default_enemy_experience(
	enemy_max_hp: float
) -> int:
	return maxi(1, roundi(enemy_max_hp * 0.25))


static func stat_point_increase(
	stat_id: StringName
) -> float:
	match stat_id:
		&"max_hp":
			return 10.0
		&"max_mp":
			return 5.0
		&"atk", &"def", &"spd":
			return 1.0
		_:
			return 0.0


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
