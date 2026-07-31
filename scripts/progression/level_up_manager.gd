class_name LevelUpManager
extends Node

var _player: Player
var _level_up_ui: LevelUpUI


func setup(player: Player, level_up_ui: LevelUpUI) -> void:
	_player = player
	_level_up_ui = level_up_ui
	player.level_up_available.connect(_on_level_up_available)
	level_up_ui.stat_selected.connect(_on_stat_selected)
	level_up_ui.close_requested.connect(_on_close_requested)


func is_active() -> bool:
	return _level_up_ui != null and _level_up_ui.level_root.visible


func _on_level_up_available() -> void:
	_player.set_input_enabled(false)
	_level_up_ui.open(_player)


func _on_stat_selected(stat_id: StringName) -> void:
	if _player.spend_stat_point(stat_id):
		_level_up_ui.refresh()


func _on_close_requested() -> void:
	if _player.unspent_stat_points > 0:
		return
	_level_up_ui.close()
	_player.set_input_enabled(true)
