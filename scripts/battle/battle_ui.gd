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
@onready var player_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/LeftColumn/PlayerStats
@onready var player_action_info: EntryInfoPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/LeftColumn/PlayerActionInfo
@onready var enemy_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/RightColumn/EnemyStats
@onready var enemy_action_info: EntryInfoPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/BattleBody/RightColumn/EnemyActionInfo
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
@onready var message_label: Label = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/MessagePanel/Message

var _player: Player
var _enemy: Enemy
var _enemy_current_forecast_skill: SkillData = null
var _action_available := false
var _current_page: ActionPage = ActionPage.SKILLS
var _player_atb_value := 0.0
var _enemy_atb_value := 0.0
var _battle_manager: BattleManager
var _player_casting_label: Label
var _enemy_casting_label: Label
var _current_preview_entry: Resource = null
var _input_ready_time: int = 0


func _ready() -> void:
	skill_panel.skill_selected.connect(_on_skill_selected)
	skill_panel.skill_focused.connect(_on_skill_focused)
	inventory_panel.item_selected.connect(_on_item_selected)
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
			player_atb_marker.modulate = Color("#80CCFFFF")
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
	if not battle_root.visible:
		return
	if Time.get_ticks_msec() < _input_ready_time:
		get_viewport().set_input_as_handled()
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
	Input.flush_buffered_events()
	_input_ready_time = Time.get_ticks_msec() + 180
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
	player_stats.bind_actor(_player, ActorStatsDisplayProfile.battle_player(), _create_actor_context(_player, _player_atb_value))
	enemy_stats.bind_actor(_enemy, ActorStatsDisplayProfile.battle_enemy(), _create_actor_context(_enemy, _enemy_atb_value))
	clear_message()
	player_action_info.clear_info()
	# enemy_action_info.clear_info()
	enemy_action_info.display_skill(null, true)
	player_atb_marker.texture = _get_marker_texture(player, player.player_data.portrait)
	enemy_atb_marker.texture = _get_marker_texture(enemy, enemy.enemy_data.portrait)
	player_atb_marker.visible = player_atb_marker.texture != null
	enemy_atb_marker.visible = enemy_atb_marker.texture != null
	_show_action_page(ActionPage.SKILLS, false)
	set_action_available(false)
	refresh_stats()
	call_deferred(&"_focus_current_page")


func close() -> void:
	battle_root.visible = false
	inventory_panel.bind_inventory(null)
	clear_preview_entry()
	enemy_action_info.clear_info()
	clear_message()
	player_stats.unbind_actor()
	enemy_stats.unbind_actor()
	_enemy_current_forecast_skill = null
	_player = null
	_enemy = null
	_battle_manager = null


func set_action_available(available: bool) -> void:
	_action_available = available


func set_atb(player_value: float, enemy_value: float) -> void:
	_player_atb_value = clampf(player_value, 0.0, FORMULAS.ATB_MAX)
	_enemy_atb_value = clampf(enemy_value, 0.0, FORMULAS.ATB_MAX)
	_update_atb_markers(_player_atb_value, _enemy_atb_value)


func show_message(message: String) -> void:
	message_label.text = message.replace("\n", " ； ")


func clear_message() -> void:
	message_label.text = ""


func refresh_base_battle_ui() -> void:
	if _player != null:
		player_stats.set_context(_create_actor_context(_player, _player_atb_value))
	if _enemy != null:
		enemy_stats.set_context(_create_actor_context(_enemy, _enemy_atb_value))
	_update_atb_markers(_player_atb_value, _enemy_atb_value)
	skill_panel.update_availability(_can_cast_skill, _get_skill_cd)
	_update_enemy_forecast()


func set_preview_entry(entry: Resource) -> void:
	_current_preview_entry = entry
	apply_current_preview()


func clear_preview_entry() -> void:
	_current_preview_entry = null
	if player_stats != null:
		player_stats.clear_preview()
	if enemy_stats != null:
		enemy_stats.clear_preview()
	if player_action_info != null:
		player_action_info.clear_info()
	_update_atb_markers(_player_atb_value, _enemy_atb_value, -1.0)


func apply_current_preview() -> void:
	if _current_preview_entry == null:
		clear_preview_entry()
		return
	if _current_preview_entry is SkillData:
		_apply_skill_preview(_current_preview_entry as SkillData)
	elif _current_preview_entry is ItemData:
		_apply_item_preview(_current_preview_entry as ItemData)
	else:
		clear_preview_entry()


func refresh_stats() -> void:
	refresh_base_battle_ui()
	if _current_preview_entry != null:
		apply_current_preview()
	else:
		clear_preview_entry()


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
	_enemy_current_forecast_skill = skill
	_update_enemy_forecast()


func _update_enemy_forecast() -> void:
	if enemy_action_info != null and _enemy != null:
		enemy_action_info.display_skill(_enemy_current_forecast_skill, true)


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
	_refresh_default_preview_for_current_page()
	refresh_stats()
	if focus_page:
		_focus_current_page()


func _refresh_default_preview_for_current_page() -> void:
	match _current_page:
		ActionPage.SKILLS:
			var rows = skill_panel.skill_rows.get_rows()
			if not rows.is_empty() and rows[0] is SelectableListRow:
				var first_row = rows[0] as SelectableListRow
				if first_row.entry is SkillData:
					set_preview_entry(first_row.entry as SkillData)
					return
			clear_preview_entry()
		ActionPage.ITEMS:
			var rows = inventory_panel.item_rows.get_rows()
			if not rows.is_empty() and rows[0] is SelectableListRow:
				var first_row = rows[0] as SelectableListRow
				if first_row.entry is ItemData:
					set_preview_entry(first_row.entry as ItemData)
					return
			clear_preview_entry()
			var empty_info := EntryInfoViewData.new()
			empty_info.title = "道具为空"
			empty_info.description = "背包中没有可在战斗中使用的道具。"
			player_action_info.display_info(empty_info)
		ActionPage.ESCAPE:
			clear_preview_entry()
			var esc_info := EntryInfoViewData.new()
			esc_info.title = "撤退"
			esc_info.description = "尝试脱离当前的战斗。按确认键执行撤退。"
			player_action_info.display_info(esc_info)


func _on_skill_selected(skill: SkillData) -> void:
	if not _action_available:
		show_message("行动准备中，请等待行动槽就绪……")
		return
	if not _can_cast_skill(skill):
		show_message("无法使用该技能：资源不足或正在冷却。")
		return
	skill_selected.emit(skill)


func _on_item_selected(item: ItemData) -> void:
	if not _action_available:
		show_message("行动准备中，请等待行动槽就绪……")
		return
	item_selected.emit(item)


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
		if not _action_available:
			show_message("行动准备中，请等待行动槽就绪……")
			return
		escape_requested.emit()
		return
	_show_action_page(ActionPage.ESCAPE, true)


func _on_skill_focused(skill: SkillData) -> void:
	set_preview_entry(skill)


func _on_item_focused(item: ItemData) -> void:
	set_preview_entry(item)


func _apply_skill_preview(skill: SkillData) -> void:
	if skill == null:
		clear_preview_entry()
		return
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

	if player_stats != null:
		player_stats.set_preview(player_preview)
	if enemy_stats != null:
		enemy_stats.set_preview(enemy_preview)
	_update_atb_markers(
		_player_atb_value,
		_enemy_atb_value,
		_player_atb_value + player_preview.current_atb_delta if player_preview.has_atb_change() else -1.0
	)
	if player_action_info != null:
		player_action_info.display_skill(skill)


func _apply_item_preview(item: ItemData) -> void:
	if item == null:
		clear_preview_entry()
		return
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
			
	if player_stats != null:
		player_stats.set_preview(player_preview)
	if enemy_stats != null:
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
	if player_action_info != null:
		player_action_info.display_info(info)


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
