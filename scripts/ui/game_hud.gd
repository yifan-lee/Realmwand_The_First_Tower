class_name GameHUD
extends CanvasLayer


@onready var player_stat_hud: PlayerStatHUD = (
	$HudRoot/PlayerStatHUD
)
@onready var tracked_inventory_hud: TrackedInventoryHUD = (
	$HudRoot/TrackedInventoryHUD
)
@onready var game_message_panel: GameMessagePanel = (
	$HudRoot/MessageArea/GameMessagePanel
)

var _player: Player


func bind_player(player: Player) -> void:
	if (
		_player != null
		and _player.stats_changed.is_connected(
			refresh_player_stats
		)
	):
		_player.stats_changed.disconnect(
			refresh_player_stats
		)

	_player = player

	if _player == null:
		player_stat_hud.clear_stats()
		tracked_inventory_hud.bind_inventory(null)
		return

	_player.stats_changed.connect(
		refresh_player_stats
	)

	tracked_inventory_hud.bind_inventory(
		_player.inventory
	)
	refresh_player_stats()


func refresh_player_stats() -> void:
	if _player == null or _player.player_data == null:
		player_stat_hud.clear_stats()
		return

	var view_data: ActorStatsViewData = ActorStatsViewData.new()

	view_data.display_name = _player.player_data.display_name
	view_data.portrait = _player.player_data.portrait

	view_data.current_hp = _player.current_hp
	view_data.max_hp = _player.get_max_hp()
	view_data.current_mp = _player.current_mp
	view_data.max_mp = _player.get_max_mp()

	player_stat_hud.display_stats(view_data)


func show_message(message: String) -> void:
	game_message_panel.show_message(message)


func clear_message() -> void:
	game_message_panel.clear_message()