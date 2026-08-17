class_name BattleUI
extends CanvasLayer

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal skill_selected(skill: SkillData)
signal item_selected(item: ItemData)
signal escape_requested

enum ActionPage {
	SKILLS,
	ITEMS,
	ESCAPE,
}

@onready var battle_root: Control = $BattleRoot
@onready var player_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/PlayerStats
@onready var enemy_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/RightColumn/EnemyStats
@onready var shared_atb_track: ProgressBar = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/SharedAtb/Track
@onready var player_atb_marker: TextureRect = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/SharedAtb/Track/PlayerMarker
@onready var enemy_atb_marker: TextureRect = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/SharedAtb/Track/EnemyMarker
@onready var player_atb_preview_marker: ColorRect = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/SharedAtb/Track/PlayerCastPreviewMarker
@onready var skills_tab: Button = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionTabs/SkillsTab
@onready var items_tab: Button = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionTabs/ItemsTab
@onready var escape_tab: Button = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionTabs/EscapeTab
@onready var skill_panel: SkillPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionBody/ListColumn/SkillPanel
@onready var inventory_panel: InventoryPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionBody/ListColumn/InventoryPanel
@onready var escape_page: Control = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionBody/ListColumn/EscapePage
@onready var entry_info_panel: EntryInfoPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/CenterColumn/ActionBody/EntryInfoPanel
@onready var message_label: Label = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Message

var _player: Player
var _enemy: Enemy
var _action_available := false
var _current_page: ActionPage = ActionPage.SKILLS
var _player_atb_value := 0.0
var _enemy_atb_value := 0.0
var _battle_manager: BattleManager
var _player_casting_label: Label
var _enemy_casting_label: Label


func _ready() -> void:
	skill_panel.skill_selected.connect(skill_selected.emit)
	skill_panel.skill_focused.connect(_on_skill_focused)
	inventory_panel.item_selected.connect(item_selected.emit)
	inventory_panel.item_focused.connect(_on_item_focused)
	skills_tab.pressed.connect(_show_action_page.bind(ActionPage.SKILLS, true))
	items_tab.pressed.connect(_show_action_page.bind(ActionPage.ITEMS, true))
	escape_tab.pressed.connect(_on_escape_tab_pressed)
	skills_tab.focus_entered.connect(_show_action_page.bind(ActionPage.SKILLS, false))
	items_tab.focus_entered.connect(_show_action_page.bind(ActionPage.ITEMS, false))
	escape_tab.focus_entered.connect(_show_action_page.bind(ActionPage.ESCAPE, false))
	
	_player_casting_label = player_atb_marker.get_node("PlayerCastingLabel")
	_enemy_casting_label = enemy_atb_marker.get_node("EnemyCastingLabel")



func _process(_delta: float) -> void:
	if not battle_root.visible:
		return
	_refresh_action_tab_highlights()

	if player_atb_preview_marker != null and player_atb_preview_marker.visible:
		var time_sec = Time.get_ticks_msec() / 1000.0
		player_atb_preview_marker.modulate.a = (sin(time_sec * 8.0) + 1.0) * 0.5 + 0.2

	if _battle_manager != null:
		var time_sec = Time.get_ticks_msec() / 1000.0
		
		var p_casting = _battle_manager.is_player_casting()
		_player_casting_label.visible = p_casting
		if p_casting:
			player_atb_marker.modulate = Color("#99CCFFFF")
			player_atb_marker.modulate.a = (sin(time_sec * 10.0) + 1.0) * 0.25 + 0.5
		else:
			player_atb_marker.modulate = Color("#FFFFFFFF")
			
		var e_casting = _battle_manager.is_enemy_casting()
		_enemy_casting_label.visible = e_casting
		if e_casting:
			enemy_atb_marker.modulate = Color("#FF6666FF")
			enemy_atb_marker.modulate.a = (sin(time_sec * 10.0) + 1.0) * 0.25 + 0.5
		else:
			enemy_atb_marker.modulate = Color("#FFFFFFFF")

	if _player != null:
		skill_panel.update_availability(_can_cast_skill, _get_skill_cd)


func _unhandled_input(event: InputEvent) -> void:
	if not battle_root.visible or not _action_available:
		return
	if event.is_action_pressed(&"ui_left"):
		_cycle_action_page(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right"):
		_cycle_action_page(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down") and _is_tab_focused():
		_focus_current_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		_focus_current_tab()
		get_viewport().set_input_as_handled()


func open(player: Player, enemy: Enemy, battle_manager: BattleManager = null) -> void:
	_player = player
	_enemy = enemy
	_battle_manager = battle_manager
	var active_skills: Array[SkillData] = []
	for skill: SkillData in player.learned_skills:
		if skill != null and skill.skill_type != SkillData.SkillType.PASSIVE:
			active_skills.append(skill)
	skill_panel.display_skills(active_skills)
	inventory_panel.bind_inventory(player.inventory)
	inventory_panel.set_battle_only(true)
	battle_root.visible = true
	clear_message()
	entry_info_panel.clear_info()
	player_atb_marker.texture = _get_marker_texture(player, player.player_data.portrait)
	enemy_atb_marker.texture = _get_marker_texture(enemy, enemy.enemy_data.portrait)
	player_atb_marker.visible = player_atb_marker.texture != null
	enemy_atb_marker.visible = enemy_atb_marker.texture != null
	_show_action_page(ActionPage.SKILLS, false)
	set_action_available(false)
	player_stats.bind_actor(_player, ActorStatsDisplayProfile.battle_player(), _create_actor_context(_player, _player_atb_value))
	enemy_stats.bind_actor(_enemy, ActorStatsDisplayProfile.battle_enemy(), _create_actor_context(_enemy, _enemy_atb_value))
	refresh_stats()


func close() -> void:
	battle_root.visible = false
	inventory_panel.bind_inventory(null)
	entry_info_panel.clear_info()
	clear_message()
	player_stats.unbind_actor()
	enemy_stats.unbind_actor()
	_player = null
	_enemy = null
	_battle_manager = null


func set_action_available(available: bool) -> void:
	_action_available = available
	skills_tab.disabled = not available
	items_tab.disabled = not available
	escape_tab.disabled = not available
	if available:
		_show_action_page(ActionPage.SKILLS, false)
		call_deferred(&"_focus_current_page")
	else:
		get_viewport().gui_release_focus()


func set_atb(player_value: float, enemy_value: float) -> void:
	_player_atb_value = clampf(player_value, 0.0, FORMULAS.ATB_MAX)
	_enemy_atb_value = clampf(enemy_value, 0.0, FORMULAS.ATB_MAX)
	_update_atb_markers(_player_atb_value, _enemy_atb_value)


func show_message(message: String) -> void:
	message_label.text = message
	message_label.visible = not message.is_empty()


func clear_message() -> void:
	message_label.text = ""
	message_label.visible = false


func refresh_stats() -> void:
	if _player != null:
		player_stats.clear_preview()
		player_stats.set_context(_create_actor_context(_player, _player_atb_value))
	if _enemy != null:
		enemy_stats.clear_preview()
		enemy_stats.set_context(_create_actor_context(_enemy, _enemy_atb_value))
	_update_atb_markers(_player_atb_value, _enemy_atb_value)
	skill_panel.update_availability(_can_cast_skill, _get_skill_cd)


func _create_actor_context(actor: Node, atb_val: float) -> ActorStatsContext:
	var ctx := ActorStatsContext.new()
	ctx.current_atb = atb_val
	ctx.max_atb = FORMULAS.ATB_MAX
	if _battle_manager != null and actor != null:
		ctx.active_effects = _battle_manager.get_actor_effects(actor)
		ctx.effective_atk = _battle_manager.get_actor_stat(actor, StatusEffectData.StatType.ATK)
		ctx.effective_def = _battle_manager.get_actor_stat(actor, StatusEffectData.StatType.DEF)
		ctx.effective_spd = _battle_manager.get_actor_stat(actor, StatusEffectData.StatType.SPD)
	return ctx


func set_enemy_forecast(skill: SkillData) -> void:
	var forecast_panel = get_node_or_null("BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/RightColumn/EnemyForecastPanel")
	if forecast_panel != null and _enemy != null:
		forecast_panel.display_forecast(skill, _enemy.enemy_data.display_name)

func _get_skill_cd(skill: SkillData) -> int:
	if _battle_manager != null:
		return _battle_manager.get_skill_cooldown(skill.id)
	return 0


func _can_cast_skill(skill: SkillData) -> bool:
	if _player == null:
		return false
	if _get_skill_cd(skill) > 0:
		return false
	for cost: ActionCostData in skill.costs:
		match cost.cost_type:
			ActionCostData.CostType.HP:
				if _player.current_hp <= cost.value: return false
			ActionCostData.CostType.MP:
				if _player.current_mp < cost.value: return false
			ActionCostData.CostType.FP:
				if _player.current_fp < cost.value: return false
	return true


func _show_action_page(page: ActionPage, focus_page: bool) -> void:
	_current_page = page
	skill_panel.visible = page == ActionPage.SKILLS
	inventory_panel.visible = page == ActionPage.ITEMS
	escape_page.visible = page == ActionPage.ESCAPE
	entry_info_panel.clear_info()
	refresh_stats()
	if focus_page:
		_focus_current_page()


func _cycle_action_page(direction: int) -> void:
	var next_page: int = posmod(
		int(_current_page) + direction,
		ActionPage.size()
	)
	_show_action_page(next_page, false)
	_focus_current_page()


func _focus_current_page() -> void:
	match _current_page:
		ActionPage.SKILLS:
			if not skill_panel.skill_rows.focus_first_row(0):
				skills_tab.grab_focus()
		ActionPage.ITEMS:
			if not inventory_panel.item_rows.focus_first_row(0):
				items_tab.grab_focus()
		ActionPage.ESCAPE:
			escape_tab.grab_focus()


func _focus_current_tab() -> void:
	match _current_page:
		ActionPage.SKILLS:
			skills_tab.grab_focus()
		ActionPage.ITEMS:
			items_tab.grab_focus()
		ActionPage.ESCAPE:
			escape_tab.grab_focus()


func _refresh_action_tab_highlights() -> void:
	var focused_control := get_viewport().gui_get_focus_owner()
	skills_tab.set_pressed_no_signal(focused_control == skills_tab)
	items_tab.set_pressed_no_signal(focused_control == items_tab)
	escape_tab.set_pressed_no_signal(focused_control == escape_tab)


func _is_tab_focused() -> bool:
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused in [skills_tab, items_tab, escape_tab]


func _on_escape_tab_pressed() -> void:
	if _current_page == ActionPage.ESCAPE:
		escape_requested.emit()
		return
	_show_action_page(ActionPage.ESCAPE, true)


func _on_skill_focused(skill: SkillData) -> void:
	var player_preview := ActorStatsPreviewData.new()
	var enemy_preview := ActorStatsPreviewData.new()
	
	if _battle_manager != null:
		var preview = BattleCalculator.evaluate_skill(skill, _player, [_enemy], _battle_manager)
		
		var player_delta = preview.actor_deltas.get(_player, null)
		if player_delta != null:
			player_preview.current_hp_delta = player_delta.hp_delta
			player_preview.current_shield_delta = player_delta.shield_delta
			player_preview.current_mp_delta = player_delta.mp_delta
			player_preview.current_fp_delta = player_delta.fp_delta
			player_preview.atk_delta = player_delta.atk_delta
			player_preview.def_delta = player_delta.def_delta
			player_preview.spd_delta = player_delta.spd_delta
			if player_delta.atb_delta < 0.0:
				player_preview.current_atb_delta = player_delta.atb_delta
				
		var enemy_delta = preview.actor_deltas.get(_enemy, null)
		if enemy_delta != null:
			enemy_preview.current_hp_delta = enemy_delta.hp_delta
			enemy_preview.current_shield_delta = enemy_delta.shield_delta
			enemy_preview.current_mp_delta = enemy_delta.mp_delta
			enemy_preview.current_fp_delta = enemy_delta.fp_delta
			enemy_preview.atk_delta = enemy_delta.atk_delta
			enemy_preview.def_delta = enemy_delta.def_delta
			enemy_preview.spd_delta = enemy_delta.spd_delta
	else:
		if _player != null:
			for cost: ActionCostData in skill.costs:
				match cost.cost_type:
					ActionCostData.CostType.HP:
						player_preview.current_hp_delta -= cost.value
					ActionCostData.CostType.MP:
						player_preview.current_mp_delta -= cost.value
					ActionCostData.CostType.FP:
						player_preview.current_fp_delta -= cost.value
					ActionCostData.CostType.CAST_TIME:
						if cost.value > 0.0:
							player_preview.current_atb_delta -= FORMULAS.ATB_MAX * cost.value

	player_stats.set_preview(player_preview)
	enemy_stats.set_preview(enemy_preview)
	_update_atb_markers(
		_player_atb_value,
		_enemy_atb_value,
		_player_atb_value + player_preview.current_atb_delta if player_preview.has_atb_change() else -1.0
	)
	var info := EntryInfoViewData.new()
	info.title = skill.display_name
	info.icon = skill.icon
	info.description = skill.description
	info.detail_lines = skill.get_details()
	entry_info_panel.display_info(info)


func _on_item_focused(item: ItemData) -> void:
	var player_preview := ActorStatsPreviewData.new()
	var enemy_preview := ActorStatsPreviewData.new()
	var details: Array[String] = []
	
	for effect: ActionEffectData in item.effects:
		var desc := effect.get_description()
		if desc != "":
			details.append(desc)
			
	if _battle_manager != null:
		var preview = BattleCalculator.evaluate_item(item, _player, [_enemy], _battle_manager)
		var player_delta = preview.actor_deltas.get(_player, null)
		if player_delta != null:
			player_preview.current_hp_delta = player_delta.hp_delta
			player_preview.current_mp_delta = player_delta.mp_delta
			player_preview.current_fp_delta = player_delta.fp_delta
			player_preview.atk_delta = player_delta.atk_delta
			player_preview.def_delta = player_delta.def_delta
			player_preview.spd_delta = player_delta.spd_delta

		var enemy_delta = preview.actor_deltas.get(_enemy, null)
		if enemy_delta != null:
			enemy_preview.current_hp_delta = enemy_delta.hp_delta
			enemy_preview.current_mp_delta = enemy_delta.mp_delta
			enemy_preview.current_fp_delta = enemy_delta.fp_delta
			enemy_preview.atk_delta = enemy_delta.atk_delta
			enemy_preview.def_delta = enemy_delta.def_delta
			enemy_preview.spd_delta = enemy_delta.spd_delta
			
	player_stats.set_preview(player_preview)
	enemy_stats.set_preview(enemy_preview)
	_update_atb_markers(
		_player_atb_value,
		_enemy_atb_value,
		-1.0
	)
	var info := EntryInfoViewData.new()
	info.title = item.display_name
	info.icon = item.icon
	info.description = item.description
	info.detail_lines = details
	entry_info_panel.display_info(info)


func _update_atb_markers(
	player_value: float,
	enemy_value: float,
	player_preview_value: float = -1.0
) -> void:
	if shared_atb_track == null:
		return

	_set_atb_marker(player_atb_marker, player_value)
	_set_atb_marker(enemy_atb_marker, enemy_value)

	if player_atb_preview_marker != null:
		if player_preview_value >= 0.0:
			player_atb_preview_marker.visible = true
			var travel_distance := maxf(
				0.0,
				shared_atb_track.size.x - player_atb_preview_marker.size.x
			)
			var marker_x := clampf(
				travel_distance * clampf(
					player_preview_value / FORMULAS.ATB_MAX,
					0.0,
					1.0
				),
				0.0,
				travel_distance
			)

			player_atb_preview_marker.offset_left = marker_x
			player_atb_preview_marker.offset_right = marker_x + 3.0
		else:
			player_atb_preview_marker.visible = false


func _set_atb_marker(
	marker: TextureRect,
	value: float
) -> void:
	if marker == null:
		return

	var travel_distance := maxf(
		0.0,
		shared_atb_track.size.x - marker.size.x
	)
	marker.position.x = clampf(
		travel_distance * clampf(
		value / FORMULAS.ATB_MAX,
		0.0,
		1.0
		),
		0.0,
		travel_distance
	)


func _get_marker_texture(
	actor: Node,
	portrait: Texture2D
) -> Texture2D:
	if portrait != null:
		return portrait

	var sprite := actor.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return null

	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
