class_name GameStatsColumn
extends PanelContainer

@onready var actor_stats_panel: ActorStatsPanel = $Content/ActorStatsPanel
@onready var tracked_inventory_hud: TrackedInventoryHUD = $Content/TrackedInventoryHUD

var _player: Player


func bind_player(player: Player) -> void:
	_player = player

	if _player == null:
		actor_stats_panel.unbind_actor()
		tracked_inventory_hud.bind_inventory(null)
		return

	actor_stats_panel.bind_actor(_player, ActorStatsDisplayProfile.hud())
	tracked_inventory_hud.bind_inventory(_player.inventory)


func refresh_player_stats() -> void:
	actor_stats_panel.refresh()
