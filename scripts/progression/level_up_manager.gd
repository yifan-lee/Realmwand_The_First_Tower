class_name LevelUpManager
extends Node

signal level_up_finished

var _player: Player
var _level_up_ui: LevelUpUI


func setup(player: Player, level_up_ui: LevelUpUI) -> void:
	_player = player
	_level_up_ui = level_up_ui
	player.level_up_available.connect(_on_level_up_available)
	level_up_ui.allocation_confirmed.connect(_on_allocation_confirmed)


func is_active() -> bool:
	return _level_up_ui != null and _level_up_ui.level_root.visible


func _on_level_up_available() -> void:
	_player.set_input_enabled(false)
	_level_up_ui.open(_player)


func _on_allocation_confirmed(allocation: Dictionary[StringName, int]) -> void:
	if not _player.apply_stat_allocation(allocation):
		return
	_level_up_ui.close()
	_player.set_input_enabled(true)
	
	if not _player.progression.pending_learned_skills.is_empty():
		var skill: SkillData = _player.progression.pending_learned_skills.pop_front()
		_player.progression.pending_learned_skills.clear()
		EventBus.system_message_requested.emit(
			"学会了新技能：【%s】" % skill.display_name
		)
		
	level_up_finished.emit()
