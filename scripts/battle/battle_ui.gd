class_name BattleUI
extends CanvasLayer

signal skill_selected(skill: SkillData)
signal item_selected(item: ItemData)
signal escape_requested

@onready var battle_root: Control = $BattleRoot
@onready var player_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Stats/PlayerStats
@onready var enemy_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Stats/EnemyStats
@onready var player_atb: ProgressBar = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Gauges/PlayerAtb
@onready var enemy_atb: ProgressBar = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Gauges/EnemyAtb
@onready var skill_panel: SkillPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Actions/SkillPanel
@onready var inventory_panel: InventoryPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Actions/InventoryPanel
@onready var message_label: Label = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Message
@onready var escape_button: Button = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/EscapeButton

var _player: Player
var _enemy: Enemy


func _ready() -> void:
	skill_panel.skill_selected.connect(skill_selected.emit)
	inventory_panel.item_selected.connect(item_selected.emit)
	escape_button.pressed.connect(escape_requested.emit)


func open(player: Player, enemy: Enemy) -> void:
	_player = player
	_enemy = enemy
	skill_panel.display_skills(player.learned_skills)
	inventory_panel.bind_inventory(player.inventory)
	battle_root.visible = true
	set_action_available(false)
	refresh_stats()


func close() -> void:
	battle_root.visible = false
	inventory_panel.bind_inventory(null)
	_player = null
	_enemy = null


func set_action_available(available: bool) -> void:
	skill_panel.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	skill_panel.modulate.a = 1.0 if available else 0.55
	inventory_panel.modulate.a = 1.0 if available else 0.55


func set_atb(player_value: float, enemy_value: float) -> void:
	player_atb.value = player_value
	enemy_atb.value = enemy_value


func show_message(message: String) -> void:
	message_label.text = message


func refresh_stats() -> void:
	player_stats.display_stats(_build_player_view())
	enemy_stats.display_stats(_build_enemy_view())


func _build_player_view() -> ActorStatsViewData:
	if _player == null or _player.player_data == null:
		return null

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
	return view


func _build_enemy_view() -> ActorStatsViewData:
	if _enemy == null or _enemy.enemy_data == null:
		return null

	var view := ActorStatsViewData.new()
	view.display_name = _enemy.enemy_data.display_name
	view.portrait = _enemy.enemy_data.portrait
	view.current_hp = _enemy.current_hp
	view.max_hp = _enemy.enemy_data.max_hp
	view.current_mp = _enemy.current_mp
	view.max_mp = _enemy.enemy_data.max_mp
	view.atk = _enemy.enemy_data.atk
	view.def = _enemy.enemy_data.def
	view.spd = _enemy.enemy_data.spd
	return view
