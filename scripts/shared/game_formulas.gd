class_name GameFormulas
extends RefCounted

const ATB_MAX: float = 200.0
const MIN_DAMAGE: float = 1.0
const EXPERIENCE_PER_LEVEL: int = 10
const BASE_EXPERIENCE: int = 50
const ATK_CONSTANT: float = 20.0
const DEF_CONSTANT: float = 20.0
const SPD_CONSTANT: float = 40.0
const AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL: float = 2.0
const FREE_STAT_POINTS_PER_LEVEL: int = 6
const STAT_INCREASE_PER_ALLOCATED_POINT: float = 1.0
const BASE_MAX_HP_COEFFICIENT: float = 5.0
const BASE_MAX_MP_COEFFICIENT: float = 3.0
const BASE_FP_RECOVERY_COEFFICIENT: float = 0.1
const CP_DIVISOR: float = 10.0
## 为 true 时，因加点提升的最大生命/魔力会同步恢复等量当前值。
const RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE: bool = true


static func calculate_atb_gain(
	speed: float,
	delta: float
) -> float:
	return maxf(0.0, speed + SPD_CONSTANT) * maxf(0.0, delta)


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
		(attack + ATK_CONSTANT) * skill_power / (defense + DEF_CONSTANT)
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
	return STAT_INCREASE_PER_ALLOCATED_POINT


static func status_effect_delta(
	base_value: float,
	status: StatusEffectData
) -> float:
	if status == null:
		return 0.0
	if status.operation == StatusEffectData.OpType.MULTIPLY:
		return base_value * (status.value - 1.0)
	return status.value


static func calculate_effective_stat(
	base_value: float,
	statuses: Array[ActiveStatus],
	stat_type: StatusEffectData.StatType
) -> float:
	var added_value := 0.0
	var multiplier := 1.0
	for status: ActiveStatus in statuses:
		if status.data == null or status.data.affected_stat != stat_type:
			continue
		var stacks := float(status.current_stacks)
		if status.data.operation == StatusEffectData.OpType.MULTIPLY:
			multiplier *= (1.0 + (status.data.value - 1.0) * stacks)
		else:
			added_value += status.data.value * stacks
	return maxf(0.0, (base_value + added_value) * multiplier)


static func calculate_skill_power_modifier(
	base_power: float,
	statuses: Array[ActiveStatus],
	skill_type: int
) -> float:
	var added_value := 0.0
	var multiplier := 1.0
	for status: ActiveStatus in statuses:
		if status.data == null or status.data.affected_stat != StatusEffectData.StatType.SKILL_POWER:
			continue
		if status.data.restrict_skill_type and status.data.target_skill_type != skill_type:
			continue
		var stacks := float(status.current_stacks)
		if status.data.operation == StatusEffectData.OpType.MULTIPLY:
			multiplier *= (1.0 + (status.data.value - 1.0) * stacks)
		else:
			added_value += status.data.value * stacks
	return maxf(0.0, (base_power + added_value) * multiplier)


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
