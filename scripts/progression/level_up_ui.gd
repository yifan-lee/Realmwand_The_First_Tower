class_name LevelUpUI
extends CanvasLayer

signal stat_selected(stat_id: StringName)
signal close_requested

@onready var level_root: Control = $LevelRoot
@onready var stats_panel: ActorStatsPanel = $LevelRoot/Backdrop/Center/Panel/Margin/Content/StatsPanel
@onready var points_label: Label = $LevelRoot/Backdrop/Center/Panel/Margin/Content/PointsLabel
@onready var close_button: Button = $LevelRoot/Backdrop/Center/Panel/Margin/Content/CloseButton

var _player: Player


func _ready() -> void:
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/MaxHp.pressed.connect(stat_selected.emit.bind(&"max_hp"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/MaxMp.pressed.connect(stat_selected.emit.bind(&"max_mp"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/Atk.pressed.connect(stat_selected.emit.bind(&"atk"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/Def.pressed.connect(stat_selected.emit.bind(&"def"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/Spd.pressed.connect(stat_selected.emit.bind(&"spd"))
	close_button.pressed.connect(close_requested.emit)


func open(player: Player) -> void:
	_player = player
	level_root.visible = true
	refresh()
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/MaxHp.grab_focus()


func close() -> void:
	level_root.visible = false
	_player = null


func refresh() -> void:
	if _player == null:
		return
	points_label.text = "等级 %d    剩余属性点：%d" % [_player.level, _player.unspent_stat_points]
	var view := ActorStatsViewData.new()
	view.display_name = _player.player_data.display_name
	view.portrait = _player.player_data.portrait
	view.current_hp = _player.current_hp
	view.max_hp = _player.get_max_hp()
	view.current_mp = _player.current_mp
	view.max_mp = _player.get_max_mp()
	view.atk = _player.get_atk()
	view.def = _player.get_def()
	view.spd = _player.get_spd()
	stats_panel.display_stats(view)
	close_button.disabled = _player.unspent_stat_points > 0
