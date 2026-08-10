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


func _process(_delta: float) -> void:
	if not battle_root.visible:
		return
	_refresh_action_tab_highlights()

	if _player != null:
		player_stats.refresh_runtime_resources(
			_player.current_hp,
			_player.current_mp,
			_player.current_fp
		)
		skill_panel.update_availability(_can_cast_skill)
	if _enemy != null:
		enemy_stats.refresh_runtime_resources(
			_enemy.current_hp,
			_enemy.current_mp,
			_enemy.current_fp
		)


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


func open(player: Player, enemy: Enemy) -> void:
	_player = player
	_enemy = enemy
	skill_panel.display_skills(player.learned_skills)
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
	refresh_stats()


func close() -> void:
	battle_root.visible = false
	inventory_panel.bind_inventory(null)
	entry_info_panel.clear_info()
	clear_message()
	_player = null
	_enemy = null


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
	player_stats.display_stats(_build_player_view())
	enemy_stats.display_stats(_build_enemy_view())
	_update_atb_markers(_player_atb_value, _enemy_atb_value)
	skill_panel.update_availability(_can_cast_skill)


func set_enemy_forecast(skill: SkillData) -> void:
	var forecast_panel = get_node_or_null("BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/RightColumn/EnemyForecastPanel")
	if forecast_panel != null and _enemy != null:
		forecast_panel.display_forecast(skill, _enemy.enemy_data.display_name)

func _can_cast_skill(skill: SkillData) -> bool:
	if _player == null:
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
			if not skill_panel.focus_first_skill():
				skills_tab.grab_focus()
		ActionPage.ITEMS:
			if not inventory_panel.focus_first_item():
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
	var player_view := _build_player_view()
	var enemy_view := _build_enemy_view()
	player_view.preview_skill_cost(skill.costs)
	var damage := 0.0
	for effect in skill.effects:
		if effect.effect_type == ActionEffectData.EffectType.REDUCE_HP:
			var target_def = _enemy.enemy_data.def
			if effect.target_type == ActionEffectData.TargetType.SELF:
				target_def = _player.get_def()
			var dmg = FORMULAS.calculate_skill_damage(
				_player.get_atk(),
				effect.value,
				target_def
			)
			if effect.target_type == ActionEffectData.TargetType.ENEMY:
				damage += dmg
			else:
				player_view.preview_damage(dmg)
	if damage > 0.0:
		enemy_view.preview_damage(damage)
	_apply_skill_effect_preview(skill, player_view, enemy_view)
	player_stats.display_stats(player_view)
	enemy_stats.display_stats(enemy_view)
	_update_atb_markers(
		player_view.get_atb_bar_value(),
		enemy_view.get_atb_bar_value()
	)
	var info := EntryInfoViewData.new()
	info.title = skill.display_name
	info.icon = skill.icon
	info.description = skill.description
	info.detail_lines = skill.get_details()
	entry_info_panel.display_info(info)


func _on_item_focused(item: ItemData) -> void:
	var player_view := _build_player_view()
	var enemy_view := _build_enemy_view()
	var hp_rec := 0.0
	var mp_rec := 0.0
	var fp_rec := 0.0
	var details: Array[String] = []
	for effect: ActionEffectData in item.effects:
		if effect.effect_type == ActionEffectData.EffectType.RESTORE_HP:
			hp_rec += effect.value
		elif effect.effect_type == ActionEffectData.EffectType.RESTORE_MP:
			mp_rec += effect.value
		elif effect.effect_type == ActionEffectData.EffectType.RESTORE_FP:
			fp_rec += effect.value
		var desc := effect.get_description()
		if desc != "":
			details.append(desc)
	player_view.current_hp_delta = FORMULAS.calculate_recovery_delta(
		_player.current_hp,
		_player.get_max_hp(),
		hp_rec
	)
	player_view.current_mp_delta = FORMULAS.calculate_recovery_delta(
		_player.current_mp,
		_player.get_max_mp(),
		mp_rec
	)
	player_view.current_fp_delta = FORMULAS.calculate_recovery_delta(
		_player.current_fp,
		_player.get_max_fp(),
		fp_rec
	)
	player_stats.display_stats(player_view)
	enemy_stats.display_stats(enemy_view)
	var info := EntryInfoViewData.new()
	info.title = item.display_name
	info.icon = item.icon
	info.description = item.description
	info.detail_lines = details
	entry_info_panel.display_info(info)


func _apply_skill_effect_preview(
	skill: SkillData,
	player_view: ActorStatsViewData,
	enemy_view: ActorStatsViewData
) -> void:
	for effect: ActionEffectData in skill.effects:
		var target := player_view
		if effect.target_type == ActionEffectData.TargetType.ENEMY:
			target = enemy_view
		match effect.effect_type:
			ActionEffectData.EffectType.ATK:
				target.atk_delta += FORMULAS.skill_effect_delta(target.atk, effect)
			ActionEffectData.EffectType.DEF:
				target.def_delta += FORMULAS.skill_effect_delta(target.def, effect)
			ActionEffectData.EffectType.SPD:
				target.spd_delta += FORMULAS.skill_effect_delta(target.spd, effect)


func _build_player_view() -> ActorStatsViewData:
	if _player == null or _player.player_data == null:
		return null
	var view := ActorStatsViewData.new()
	view.display_name = _player.player_data.display_name
	view.portrait = _player.get_ui_portrait()
	view.level = _player.level
	view.experience = _player.experience
	view.experience_to_next_level = _player.get_experience_for_next_level()
	view.current_hp = _player.current_hp
	view.max_hp = _player.get_max_hp()
	view.current_mp = _player.current_mp
	view.max_mp = _player.get_max_mp()
	view.current_fp = _player.current_fp
	view.max_fp = _player.get_max_fp()
	view.start_fp = _player.get_start_fp()
	view.fp_recovery_spd = _player.get_fp_recovery_spd()
	view.current_atb = _player_atb_value
	view.max_atb = FORMULAS.ATB_MAX
	view.atk = _player.get_atk()
	view.def = _player.get_def()
	view.spd = _player.get_spd()
	return view


func _build_enemy_view() -> ActorStatsViewData:
	if _enemy == null or _enemy.enemy_data == null:
		return null
	var view := ActorStatsViewData.new()
	view.display_name = _enemy.enemy_data.display_name
	view.portrait = _get_marker_texture(_enemy, _enemy.enemy_data.portrait)
	view.description = _enemy.enemy_data.description
	view.current_hp = _enemy.current_hp
	view.max_hp = _enemy.get_max_hp()
	view.current_mp = _enemy.current_mp
	view.max_mp = _enemy.get_max_mp()
	view.current_fp = _enemy.current_fp
	view.max_fp = _enemy.get_max_fp()
	view.start_fp = _enemy.enemy_data.start_fp
	view.fp_recovery_spd = _enemy.get_fp_recovery_spd()
	view.current_atb = _enemy_atb_value
	view.max_atb = FORMULAS.ATB_MAX
	view.atk = _enemy.enemy_data.atk
	view.def = _enemy.enemy_data.def
	view.spd = _enemy.enemy_data.spd
	return view


func _update_atb_markers(
	player_value: float,
	enemy_value: float
) -> void:
	if shared_atb_track == null:
		return

	_set_atb_marker(player_atb_marker, player_value, -0.5)
	_set_atb_marker(enemy_atb_marker, enemy_value, 0.5)


func _set_atb_marker(
	marker: TextureRect,
	value: float,
	lane_offset: float
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
		) + marker.size.x * lane_offset,
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
