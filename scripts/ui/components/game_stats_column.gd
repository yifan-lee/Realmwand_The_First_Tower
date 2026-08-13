class_name GameStatsColumn
extends PanelContainer

@onready var actor_stats_panel: ActorStatsPanel = $Content/ActorStatsPanel
@onready var tracked_inventory_hud: TrackedInventoryHUD = $Content/TrackedInventoryHUD

var _player: Player


func bind_player(player: Player) -> void:
	if _player != null and _player.stats_changed.is_connected(refresh_player_stats):
		_player.stats_changed.disconnect(refresh_player_stats)

	_player = player

	if _player == null:
		actor_stats_panel.clear_stats()
		tracked_inventory_hud.bind_inventory(null)
		return

	_player.stats_changed.connect(refresh_player_stats)
	tracked_inventory_hud.bind_inventory(_player.inventory)
	refresh_player_stats()


func refresh_player_stats() -> void:
	var view_data := ActorStatsViewData.from_player(_player)
	if view_data == null:
		actor_stats_panel.clear_stats()
	else:
		actor_stats_panel.display_stats(view_data)
