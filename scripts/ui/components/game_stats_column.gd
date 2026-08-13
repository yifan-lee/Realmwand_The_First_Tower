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
	if _player == null or _player.player_data == null:
		actor_stats_panel.clear_stats()
		return

	var view_data: ActorStatsViewData = ActorStatsViewData.new()

	view_data.display_name = _player.player_data.display_name
	view_data.portrait = _player.get_ui_portrait()
	view_data.level = _player.level
	view_data.experience = _player.experience
	view_data.experience_to_next_level = _player.get_experience_for_next_level()

	view_data.current_hp = _player.current_hp
	view_data.max_hp = _player.get_max_hp()
	view_data.current_mp = _player.current_mp
	view_data.max_mp = _player.get_max_mp()
	view_data.current_fp = _player.current_fp
	view_data.max_fp = _player.get_max_fp()
	view_data.start_fp = _player.get_start_fp()
	view_data.fp_recovery_spd = _player.get_fp_recovery_spd()
	view_data.atk = _player.get_atk()
	view_data.def = _player.get_def()
	view_data.spd = _player.get_spd()

	actor_stats_panel.display_stats(view_data)
