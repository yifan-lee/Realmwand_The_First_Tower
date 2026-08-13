class_name GameHUD
extends CanvasLayer


@onready var actor_stats_panel: ActorStatsPanel = (
	$HudRoot/StatsColumn/Content/ActorStatsPanel
)
@onready var tracked_inventory_hud: TrackedInventoryHUD = (
	$HudRoot/StatsColumn/Content/TrackedInventoryHUD
)
@onready var game_message_panel: GameMessagePanel = (
	$HudRoot/MessageArea/GameMessagePanel
)
@onready var screen_fade: ColorRect = $HudRoot/ScreenFade
@onready var floor_info_hud: FloorInfoHUD = $HudRoot/FloorInfoHUD

var _player: Player
var _floor_info_original_pos: Vector2


func _ready() -> void:
	EventBus.screen_fade_out_started.connect(_on_screen_fade_out_started)
	EventBus.screen_fade_in_with_info_started.connect(_on_screen_fade_in_with_info_started)


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
		actor_stats_panel.clear_stats()
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


func show_message(message: String) -> void:
	game_message_panel.show_message(message)


func clear_message() -> void:
	game_message_panel.clear_message()


func _on_screen_fade_out_started() -> void:
	var tween := create_tween()
	tween.tween_property(screen_fade, "modulate:a", 1.0, 0.5)
	tween.finished.connect(func(): EventBus.screen_fade_out_finished.emit())


func _on_screen_fade_in_with_info_started(floor_name: String, floor_desc: String) -> void:
	floor_info_hud.set_info(floor_name, floor_desc)
	
	# Wait one frame for the PanelContainer to recalculate its height based on the new text
	await get_tree().process_frame
	
	_floor_info_original_pos = floor_info_hud.position
	
	# Initial scale and center position
	floor_info_hud.scale = Vector2(1.5, 1.5)
	var screen_size = get_viewport().get_visible_rect().size
	var target_center = (screen_size - floor_info_hud.size * floor_info_hud.scale) / 2.0
	floor_info_hud.position = target_center

	var tween := create_tween()
	
	# Wait in the center for 2 seconds
	tween.tween_interval(1.5)
	
	# Shrink and move
	tween.tween_property(floor_info_hud, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floor_info_hud, "position", _floor_info_original_pos, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Fade in screen (fade out the black rect)
	tween.parallel().tween_property(screen_fade, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(func(): EventBus.screen_fade_in_finished.emit())
