class_name SaveManager
extends Node

signal saves_changed

const SAVE_VERSION := 1
const SAVE_DIRECTORY := "user://saves"
const SAVE_EXTENSION := ".json"

var _player: Player
var _floor_manager: FloorManager
var _tutorial_manager: TutorialManager


func setup(
	player: Player,
	floor_manager: FloorManager,
	tutorial_manager: TutorialManager
) -> void:
	_player = player
	_floor_manager = floor_manager
	_tutorial_manager = tutorial_manager
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(SAVE_DIRECTORY)
	)


func create_save(display_name: String) -> bool:
	var cleaned_name := display_name.strip_edges()
	if cleaned_name.is_empty() or _player == null or _floor_manager == null:
		return false
	var slot_id := "%d_%d" % [Time.get_unix_time_from_system(), randi()]
	return _write_save(slot_id, cleaned_name)


func overwrite_save(slot_id: String) -> bool:
	var existing := _read_save(slot_id)
	if existing.is_empty():
		return false
	return _write_save(slot_id, String(existing.get("display_name", "存档")))


func load_save(slot_id: String) -> bool:
	var data := _read_save(slot_id)
	if data.is_empty():
		return false
	return restore_save_data_dict(data)


func restore_save_data_dict(data: Dictionary) -> bool:
	if _player == null or _floor_manager == null:
		return false
	var player_data_value: Variant = data.get("player", {})
	var world_data_value: Variant = data.get("world", {})
	var tutorial_data_value: Variant = data.get("tutorial", {})
	if not (player_data_value is Dictionary):
		return false
	if world_data_value is Dictionary and not world_data_value.is_empty():
		if not _floor_manager.can_restore_save_data(world_data_value):
			return false
		_floor_manager.restore_save_data(world_data_value)
	
	if _tutorial_manager != null and tutorial_data_value is Dictionary:
		_tutorial_manager.restore_save_data(tutorial_data_value)
	_player.restore_save_data(player_data_value)
	_player.clear_all_movement_locks()
	return true


func capture_current_save_dict(display_name: String = "通关战报存档") -> Dictionary:
	if _player == null or _floor_manager == null:
		return {}
	_floor_manager.store_current_floor_state()
	var now_unix := int(Time.get_unix_time_from_system())
	return {
		"version": SAVE_VERSION,
		"slot_id": "clear_%d" % now_unix,
		"display_name": display_name,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"saved_at_unix": now_unix,
		"floor_id": String(_floor_manager.current_floor_id),
		"player": _player.capture_save_data(),
		"world": _floor_manager.capture_save_data(),
		"tutorial": (
			_tutorial_manager.capture_save_data()
			if _tutorial_manager != null
			else {}
		),
	}


func export_save_json_string(display_name: String = "通关战报存档") -> String:
	var data := capture_current_save_dict(display_name)
	return JSON.stringify(data)


func import_save_from_json_string(json_string: String) -> bool:
	var cleaned := json_string.strip_edges()
	if cleaned.is_empty():
		return false
	var parsed: Variant = JSON.parse_string(cleaned)
	if not (parsed is Dictionary):
		return false
	var save_dict: Dictionary = parsed as Dictionary
	var success := restore_save_data_dict(save_dict)
	if success:
		saves_changed.emit()
	return success


func generate_clear_summary_text() -> String:
	if _player == null:
		return "无玩家数据"
	
	var lines: Array[String] = []
	var p_name: String = _player.player_data.display_name if _player.player_data else "玩家"
	lines.append("【通关角色】%s | 等级: Lv.%d (经验: %d)" % [p_name, _player.level, _player.experience])
	lines.append("【最终属性】ATK: %.0f | DEF: %.0f | SPD: %.0f" % [
		_player.stats.get_atk(),
		_player.stats.get_def(),
		_player.stats.get_spd()
	])
	lines.append("【资源上限】MaxHP: %.0f | MaxMP: %.0f | FP回复: %.1f/s" % [
		_player.stats.get_max_hp(),
		_player.stats.get_max_mp(),
		_player.stats.get_fp_recovery_spd()
	])
	lines.append("【持有信用】%d Credits" % _player.credits)
	
	var skill_names: Array[String] = []
	for sk: SkillData in _player.get_skills():
		if sk != null:
			skill_names.append(sk.display_name)
	lines.append("【掌握技能】%s" % (", ".join(skill_names) if not skill_names.is_empty() else "无"))
	
	var equip_names: Array[String] = []
	if _player.equipment != null:
		for item: EquipmentData in _player.equipment.get_all_equipped_items():
			if item != null:
				equip_names.append(item.display_name)
	lines.append("【穿戴装备】%s" % (", ".join(equip_names) if not equip_names.is_empty() else "无"))
	
	return "\n".join(lines)



func delete_save(slot_id: String) -> bool:
	var path := _get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return false
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if error != OK:
		return false
	saves_changed.emit()
	return true


func list_saves() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var directory := DirAccess.open(SAVE_DIRECTORY)
	if directory == null:
		return result
	directory.list_dir_begin()
	var filename := directory.get_next()
	while not filename.is_empty():
		if not directory.current_is_dir() and filename.ends_with(SAVE_EXTENSION):
			var slot_id := filename.trim_suffix(SAVE_EXTENSION)
			var data := _read_save(slot_id)
			if not data.is_empty():
				result.append({
					"slot_id": slot_id,
					"display_name": String(data.get("display_name", "未命名存档")),
					"saved_at": String(data.get("saved_at", "")),
					"saved_at_unix": int(data.get("saved_at_unix", 0)),
					"floor_id": String(data.get("floor_id", "")),
				})
		filename = directory.get_next()
	directory.list_dir_end()
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("saved_at_unix", 0)) > int(b.get("saved_at_unix", 0))
	)
	return result


func _write_save(slot_id: String, display_name: String) -> bool:
	_floor_manager.store_current_floor_state()
	var now_unix := int(Time.get_unix_time_from_system())
	var data := {
		"version": SAVE_VERSION,
		"slot_id": slot_id,
		"display_name": display_name,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"saved_at_unix": now_unix,
		"floor_id": String(_floor_manager.current_floor_id),
		"player": _player.capture_save_data(),
		"world": _floor_manager.capture_save_data(),
		"tutorial": (
			_tutorial_manager.capture_save_data()
			if _tutorial_manager != null
			else {}
		),
	}
	var file := FileAccess.open(_get_save_path(slot_id), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	saves_changed.emit()
	return true


func _read_save(slot_id: String) -> Dictionary:
	var path := _get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		return {}
	if int(parsed.get("version", -1)) != SAVE_VERSION:
		return {}
	return parsed


func _get_save_path(slot_id: String) -> String:
	return "%s/%s%s" % [SAVE_DIRECTORY, slot_id, SAVE_EXTENSION]
