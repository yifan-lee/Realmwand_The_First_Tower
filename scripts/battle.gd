class_name Battle
extends Control

signal battle_finished(
	victory: bool,
	experience_reward: int,
	gold_reward: int,
)

@onready var atb_track: ProgressBar = $SharedATB/Track
@onready var player_point: TextureRect = $SharedATB/PlayerPoint
@onready var enemy_point: TextureRect = $SharedATB/EnemyPoint
@onready var attack_button: Button = $ActionPanel/Actions/AttackButton
@onready var battle_message: Label = $BattleMessage
@onready var item_button: Button = $ActionPanel/Actions/ItemButton
@onready var action_panel: PanelContainer = $ActionPanel
@onready var skill_menu: SkillMenu = $SkillMenu
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var equipment_slot_picker: EquipmentSlotPicker = (
	$EquipmentSlotPicker
)
@onready var player_status_panel: CombatantStatusPanel = (
	$PlayerStatusPanel
)
@onready var enemy_status_panel: CombatantStatusPanel = (
	$EnemyStatusPanel
)
@onready var selection_detail_panel: SelectionDetailPanel = (
	$SelectionDetailPanel
)
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_title: Label = (
	$ResultPanel/MarginContainer/Content/TitleLabel
)
@onready var result_detail: Label = (
	$ResultPanel/MarginContainer/Content/DetailLabel
)
@onready var result_close_timer: Timer = (
	$ResultCloseTimer
)

const BATTLE_BALANCE: BattleBalanceConfig = preload(
	"res://resources/battle/battle_balance.tres"
)

var player_data: Player
var enemy_data: EnemyData

var battle_active: bool = true
var waiting_for_player_action: bool = false

var player_skill_cooldowns: Dictionary = {}

const ATB_MAX: float = 100.0
var player_atb: float = 0.0
var enemy_atb: float = 0.0

var result_pending: bool = false
var result_victory: bool = false

var enemy_current_hp: float
var enemy_current_mp: float
var enemy_minimum_hp: float = 0.0
var pending_equipment: EquipmentData

func _ready() -> void:
	if player_data == null:
		push_error("Battle.setup() 没有收到 Player")
		set_process(false)
		return

	if enemy_data == null:
		push_error("Battle.setup() 没有收到 Enemy")
		set_process(false)
		return

	battle_message.text = (
		"%s appeared!" % enemy_data.display_name
	)

	attack_button.disabled = true
	item_button.disabled = true
	attack_button.pressed.connect(_on_attack_button_pressed)
	attack_button.focus_entered.connect(_on_attack_button_focused)
	attack_button.mouse_entered.connect(_on_attack_button_focused)
	item_button.focus_entered.connect(_on_item_button_focused)
	item_button.mouse_entered.connect(_on_item_button_focused)
	item_button.pressed.connect(_on_item_button_pressed)
	result_close_timer.timeout.connect(
		_finish_battle_result
	)

	skill_menu.skill_selected.connect(
		_on_skill_selected
	)

	skill_menu.cancelled.connect(
		_on_skill_menu_cancelled
	)

	player_atb = 0.0
	enemy_atb = 0.0
	_update_atb_points()

	enemy_current_hp = enemy_data.max_hp
	enemy_current_mp = enemy_data.max_mp

	_refresh_status_panels()

	skill_menu.skill_focused.connect(
		_on_skill_focused
	)
	skill_menu.skill_focus_cleared.connect(
		_clear_selection_preview
	)
	inventory_menu.item_selected.connect(
		_on_item_selected
	)
	inventory_menu.cancelled.connect(
		_on_inventory_menu_cancelled
	)
	inventory_menu.item_focused.connect(
		_on_item_focused
	)
	inventory_menu.item_focus_cleared.connect(
		_clear_selection_preview
	)
	equipment_slot_picker.slot_selected.connect(
		_on_equipment_slot_selected
	)
	equipment_slot_picker.slot_focused.connect(
		_on_equipment_slot_focused
	)
	equipment_slot_picker.cancelled.connect(
		_on_equipment_slot_cancelled
	)


func _input(event: InputEvent) -> void:
	if not result_pending:
		return

	var key_event := event as InputEventKey
	var controller_event := (
		event as InputEventJoypadButton
	)
	var pressed_key := (
		key_event != null
		and key_event.is_pressed()
		and not key_event.is_echo()
	)
	var pressed_controller_button := (
		controller_event != null
		and controller_event.is_pressed()
	)

	if not pressed_key and not pressed_controller_button:
		return

	_finish_battle_result()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not battle_active:
		return

	if waiting_for_player_action:
		return

	_update_player_skill_cooldowns(delta)

	player_atb = min(
		player_atb
		+ BATTLE_BALANCE.get_atb_rate(player_data.total_spd, ATB_MAX) * delta,
		ATB_MAX
	)

	enemy_atb = min(
		enemy_atb
		+ BATTLE_BALANCE.get_atb_rate(enemy_data.spd, ATB_MAX) * delta,
		ATB_MAX
	)

	_update_atb_points()

	if player_atb >= ATB_MAX:
		_enable_player_actions()
		return

	if enemy_atb >= ATB_MAX:
		_enemy_attack()

func setup(
	player: Player,
	enemy: EnemyData
) -> void:
	player_data = player
	enemy_data = enemy

func _update_atb_point(
	point: TextureRect,
	atb_value: float
) -> void:
	var progress := clampf(atb_value / ATB_MAX, 0.0, 1.0)
	var start_x := (atb_track.position.x - point.size.x / 2.0)
	var end_x := (atb_track.position.x + atb_track.size.x - point.size.x / 2.0)
	point.position.x = lerpf(start_x, end_x, progress)


func _update_atb_points() -> void:
	_update_atb_point(player_point, player_atb)
	_update_atb_point(enemy_point, enemy_atb)

func _enable_player_actions() -> void:
	waiting_for_player_action = true
	attack_button.disabled = false
	item_button.disabled = false
	attack_button.grab_focus()

func _on_attack_button_pressed() -> void:
	if not battle_active:
		return

	if not waiting_for_player_action:
		return

	if not skill_menu.visible:
		_show_skill_menu(false)

	inventory_menu.close()
	equipment_slot_picker.close()
	pending_equipment = null
	action_panel.visible = false
	skill_menu.grab_first_skill_focus()


func _on_attack_button_focused() -> void:
	if not battle_active or not waiting_for_player_action:
		return

	inventory_menu.close()
	equipment_slot_picker.close()
	pending_equipment = null
	_show_skill_menu(false)


func _on_item_button_focused() -> void:
	if not battle_active or not waiting_for_player_action:
		return

	skill_menu.close()
	equipment_slot_picker.close()
	pending_equipment = null
	_clear_selection_preview()
	_show_inventory_menu(false)


func _on_item_button_pressed() -> void:
	if not battle_active or not waiting_for_player_action:
		return

	skill_menu.close()

	if not inventory_menu.visible:
		_show_inventory_menu(false)

	action_panel.visible = false
	inventory_menu.grab_first_category_focus()


func _show_skill_menu(focus_first_skill: bool) -> void:
	skill_menu.open(
		player_data.learned_skills,
		player_data.current_mp,
		player_skill_cooldowns,
		focus_first_skill
	)


func _show_inventory_menu(
	focus_first_category: bool
) -> void:
	inventory_menu.open(
		player_data.inventory,
		focus_first_category,
		player_data.equipment_manager
	)

func _on_skill_menu_cancelled() -> void:
	_clear_selection_preview()

	skill_menu.close()
	action_panel.visible = true
	attack_button.grab_focus()


func _on_inventory_menu_cancelled() -> void:
	_clear_selection_preview()
	inventory_menu.close()
	action_panel.visible = true
	item_button.grab_focus()

func _on_skill_selected(
	skill: SkillData
) -> void:
	if not waiting_for_player_action:
		return

	var remaining_cd := float(
		player_skill_cooldowns.get(skill.id, 0.0)
	)

	if remaining_cd > 0:
		return

	if player_data.current_mp < skill.mp_cost:
		return

	_clear_selection_preview()

	player_data.current_mp -= skill.mp_cost

	var damage := BATTLE_BALANCE.calculate_damage(
		player_data.total_atk,
		enemy_data.def,
		skill.skill_power
	)

	enemy_current_hp = max(
		enemy_current_hp - damage,
		enemy_minimum_hp
	)

	battle_message.text = (
		"Hero uses %s and deals %d damage!"
		% [
			skill.display_name,
			damage,
		]
	)

	_commit_player_action(skill)

	_refresh_status_panels()

	if enemy_current_hp <= enemy_minimum_hp:
		_end_battle_victory()


func _on_item_selected(item: ItemData) -> void:
	if not waiting_for_player_action:
		return

	if item is EquipmentData:
		var equipment := item as EquipmentData

		if (
			player_data.equipment_manager
			.requires_hand_selection(equipment)
		):
			pending_equipment = equipment
			action_panel.visible = false
			inventory_menu.visible = false
			equipment_slot_picker.open(equipment)
			return

	_use_item(item)


func _use_item(
	item: ItemData,
	target_slot: int = EquipmentManager.INVALID_SLOT
) -> bool:
	if not ItemUseService.use(
		item,
		player_data,
		true,
		target_slot
	):
		inventory_menu.visible = true
		inventory_menu.grab_first_item_focus()
		return false

	battle_message.text = (
		"%s uses %s!"
		% [
			player_data.display_name,
			item.display_name,
		]
	)

	_clear_selection_preview()
	_commit_player_action()
	_refresh_status_panels()
	return true


func _on_equipment_slot_selected(slot: int) -> void:
	if pending_equipment == null:
		return

	var equipment := pending_equipment
	pending_equipment = null
	equipment_slot_picker.close()
	_use_item(equipment, slot)


func _on_equipment_slot_focused(slot: int) -> void:
	if pending_equipment == null:
		return

	_show_item_preview(pending_equipment, slot)


func _on_equipment_slot_cancelled() -> void:
	pending_equipment = null
	equipment_slot_picker.close()
	_clear_selection_preview()
	inventory_menu.visible = true
	inventory_menu.grab_first_item_focus()



func _commit_player_action(
	used_skill: SkillData = null
) -> void:
	if (
		used_skill != null
		and used_skill.cooldown_seconds > 0.0
	):
		player_skill_cooldowns[used_skill.id] = (
			used_skill.cooldown_seconds
		)

	skill_menu.close()
	inventory_menu.close()
	equipment_slot_picker.close()
	pending_equipment = null
	action_panel.visible = true
	_finish_player_action()

func _finish_player_action() -> void:
	waiting_for_player_action = false
	player_atb = 0.0
	attack_button.disabled = true
	item_button.disabled = true
	_update_atb_points()

	attack_button.release_focus()
	item_button.release_focus()






func _enemy_attack() -> void:
	if not battle_active:
		return
	enemy_atb = 0.0
	_update_atb_points()

	var damage := BATTLE_BALANCE.calculate_damage(
		enemy_data.atk,
		player_data.total_def,
		BATTLE_BALANCE.basic_attack_power
	)

	player_data.take_damage(damage)
	_refresh_status_panels()
	battle_message.text = (
		"%s deals %.0f damage!" 
		% [
			enemy_data.display_name,
			damage,
		]
	)

	if player_data.current_hp <= 0:
		_end_battle_defeated()


func _end_battle_victory() -> void:
	var experience_reward := (
		enemy_data.get_experience_reward(
			BATTLE_BALANCE
		)
	)
	var gold_reward := enemy_data.gold_reward
	var detail_text := (
		"%s defeated!\n\nRewards\nEXP: %d\nGold: %d"
		% [
			enemy_data.display_name.strip_edges(),
			experience_reward,
			gold_reward,
		]
	)

	_show_battle_result(
		true,
		"Victory",
		detail_text
	)


func _end_battle_defeated() -> void:
	_show_battle_result(
		false,
		"Defeat",
		"Your party was defeated.\n\n"
		+ "Battle changes will be restored."
	)


func _show_battle_result(
	victory: bool,
	title: String,
	detail: String
) -> void:
	battle_active = false
	waiting_for_player_action = false
	result_pending = true
	result_victory = victory
	attack_button.disabled = true
	item_button.disabled = true
	player_atb = 0.0
	enemy_atb = 0.0
	_update_atb_points()

	skill_menu.close()
	inventory_menu.close()
	equipment_slot_picker.close()
	action_panel.visible = false
	$SharedATB.visible = false
	player_status_panel.visible = false
	enemy_status_panel.visible = false
	selection_detail_panel.visible = false
	battle_message.visible = false
	_clear_selection_preview()

	result_title.text = title
	result_detail.text = detail
	result_panel.visible = true
	result_close_timer.start()


func _finish_battle_result() -> void:
	if not result_pending:
		return

	result_pending = false
	result_close_timer.stop()

	if result_victory:
		battle_finished.emit(
			true,
			enemy_data.get_experience_reward(
				BATTLE_BALANCE
			),
			enemy_data.gold_reward,
		)
	else:
		battle_finished.emit(
			false,
			0,
			0,
		)

func _update_player_skill_cooldowns(
	delta: float
) -> void:
	for skill_id in player_skill_cooldowns.keys():
		var remaining := float(
			player_skill_cooldowns[skill_id]
		)

		remaining = maxf(remaining - delta, 0.0)

		if remaining <= 0.0:
			player_skill_cooldowns.erase(skill_id)
		else:
			player_skill_cooldowns[skill_id] = remaining


func _create_player_status_data() -> CombatantStatusViewData:
	return CombatantStatusViewData.from_player(player_data)

func _create_enemy_status_data() -> CombatantStatusViewData:
	return CombatantStatusViewData.from_enemy(
		enemy_data,
		enemy_current_hp,
		enemy_current_mp
	)

func _refresh_status_panels() -> void:
	player_status_panel.set_data(
		_create_player_status_data()
	)

	enemy_status_panel.set_data(
		_create_enemy_status_data()
	)

func _on_skill_focused(
	skill: SkillData
) -> void:
	var remaining_cd := float(
		player_skill_cooldowns.get(skill.id, 0.0)
	)
	var detail := SelectionDetailBuilder.from_skill(
		skill,
		player_data.current_mp,
		remaining_cd
	)

	selection_detail_panel.show_detail(detail)

	var previews := SkillPreviewBuilder.build(
		skill,
		player_data,
		enemy_data,
		BATTLE_BALANCE
	)
	var player_preview := (
		previews["player"] as CombatantPreviewData
	)
	var enemy_preview := (
		previews["enemy"] as CombatantPreviewData
	)

	player_status_panel.show_preview(player_preview)
	enemy_status_panel.show_preview(enemy_preview)


func _on_item_focused(item: ItemData) -> void:
	_show_item_preview(item)


func _show_item_preview(
	item: ItemData,
	target_slot: int = EquipmentManager.INVALID_SLOT
) -> void:
	var detail := SelectionDetailBuilder.from_item(
		item,
		player_data,
		true
	)
	var player_preview := ItemPreviewBuilder.for_player(
		item,
		player_data,
		target_slot
	)

	selection_detail_panel.show_detail(detail)
	player_status_panel.show_preview(player_preview)
	enemy_status_panel.clear_preview()
func _clear_selection_preview() -> void:
	selection_detail_panel.clear_detail()
	player_status_panel.clear_preview()
	enemy_status_panel.clear_preview()
