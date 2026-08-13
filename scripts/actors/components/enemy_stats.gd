class_name EnemyStats
extends ActorStats

var _enemy_data: EnemyData


func initialize(data: EnemyData) -> void:
	_enemy_data = data
	base_atk = _enemy_data.atk
	base_def = _enemy_data.def
	base_spd = _enemy_data.spd
	
	current_hp = get_max_hp()
	current_mp = get_max_mp()
	current_fp = clampf(_enemy_data.start_fp, 0.0, get_max_fp())


func get_max_hp() -> float:
	if _enemy_data == null: return 0.0
	return FORMULAS.resolve_base_max_hp(_enemy_data.max_hp, _enemy_data.def, _enemy_data.spd)


func get_max_mp() -> float:
	if _enemy_data == null: return 0.0
	return FORMULAS.resolve_base_max_mp(_enemy_data.max_mp, _enemy_data.atk, _enemy_data.spd)


func get_max_fp() -> float:
	if _enemy_data == null: return 0.0
	return _enemy_data.max_fp


func get_fp_recovery_spd() -> float:
	if _enemy_data == null: return 0.0
	return FORMULAS.resolve_base_fp_recovery(_enemy_data.fp_recovery_spd, _enemy_data.atk, _enemy_data.def)


func get_cp() -> float:
	if _enemy_data == null: return 0.0
	return FORMULAS.calculate_cp(_enemy_data.atk, _enemy_data.def, _enemy_data.spd)
