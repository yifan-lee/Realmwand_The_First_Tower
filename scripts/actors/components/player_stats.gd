class_name PlayerStats
extends ActorStats

var base_max_hp: float = 0.0
var base_max_mp: float = 0.0
var base_max_fp: float = 0.0
var base_start_fp: float = 0.0
var base_fp_recovery_spd: float = 0.0

var _equipment: EquipmentLoadout


func initialize(data: PlayerData, equipment: EquipmentLoadout) -> void:
	_equipment = equipment
	base_max_hp = data.max_hp
	base_max_mp = data.max_mp
	base_max_fp = data.max_fp
	base_start_fp = data.start_fp
	base_fp_recovery_spd = data.fp_recovery_spd
	base_atk = data.atk
	base_def = data.def
	base_spd = data.spd

	current_hp = get_max_hp()
	current_mp = get_max_mp()
	current_fp = clampf(base_start_fp, 0.0, get_max_fp())


func get_max_hp() -> float:
	var equip_bonus := _equipment.get_max_hp_bonus() if _equipment else 0.0
	return FORMULAS.resolve_base_max_hp(base_max_hp, base_def, base_spd) + equip_bonus


func get_max_mp() -> float:
	var equip_bonus := _equipment.get_max_mp_bonus() if _equipment else 0.0
	return FORMULAS.resolve_base_max_mp(base_max_mp, base_atk, base_spd) + equip_bonus


func get_max_fp() -> float:
	return base_max_fp


func get_start_fp() -> float:
	return base_start_fp


func get_fp_recovery_spd() -> float:
	return FORMULAS.resolve_base_fp_recovery(base_fp_recovery_spd, base_atk, base_def)


func get_atk() -> float:
	var equip_bonus := _equipment.get_atk_bonus() if _equipment else 0.0
	return base_atk + equip_bonus


func get_def() -> float:
	var equip_bonus := _equipment.get_def_bonus() if _equipment else 0.0
	return base_def + equip_bonus


func get_spd() -> float:
	var equip_bonus := _equipment.get_spd_bonus() if _equipment else 0.0
	return base_spd + equip_bonus
