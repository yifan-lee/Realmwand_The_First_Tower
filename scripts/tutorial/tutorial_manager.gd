class_name TutorialManager
extends Node

@export var equipment_tutorial: TutorialSequenceData
@export var battle_tutorial: TutorialSequenceData
@export var mp_tutorial: TutorialSequenceData
@export var fp_tutorial: TutorialSequenceData
@export var fp_recovery_tutorial: TutorialSequenceData
@export var hp_recovery_tutorial: TutorialSequenceData
enum TutorialState {
	WAITING_FOR_EQUIPMENT,
	WAITING_FOR_INVENTORY,
	WAITING_FOR_EQUIPMENT_FOCUS,
	WAITING_FOR_EQUIPMENT_CONFIRM,
	COMPLETED,
	WAITING_FOR_BATTLE_CONFIRM,
	WAITING_FOR_SKILL_CONFIRM,
	WAITING_FOR_ITEM_TUTORIAL,
	WAITING_FOR_ITEM_CONFIRM,
}

var current_step_index: int = 0
var current_state: TutorialState = TutorialState.WAITING_FOR_EQUIPMENT
var _player: Player
var _esc_menu: EscMenu
var _tutorial_ui: TutorialUI
var _feature_unlock_state: FeatureUnlockState
var _active_tutorial: TutorialSequenceData
var _battle_manager: BattleManager
var _equipment_tutorial_completed: bool = false
var _battle_tutorial_completed: bool = false
var _fp_recovery_tutorial_completed: bool = false
var _hp_recovery_tutorial_completed: bool = false


func setup(
	player: Player,
	esc_menu: EscMenu,
	tutorial_ui: TutorialUI,
	feature_unlock_state: FeatureUnlockState,
	battle_manager: BattleManager
) -> void:
	_player = player
	_esc_menu = esc_menu
	_tutorial_ui = tutorial_ui
	_feature_unlock_state = feature_unlock_state
	_battle_manager = battle_manager


	if (
		_player == null
		or _esc_menu == null
		or _tutorial_ui == null
	):
		return

	_player.inventory.item_added.connect(
		_on_item_added
	)
	
	_esc_menu.opened.connect(
		_on_menu_opened
	)

	_esc_menu.inventory_panel.item_focused.connect(
		_on_item_focused
	)


	_player.equipment.item_equipped.connect(
		_on_item_equipped
	)

	_battle_manager.battle_started.connect(
		_on_battle_started
	)

	_tutorial_ui.confirmed.connect(
		_on_tutorial_confirmed
	)

	_player.skill_learned.connect(
		_on_skill_learned
	)

	_esc_menu.inventory_panel.item_selected.connect(
		_on_item_selected
	)


func _on_item_added(
	item: ItemData,
	_amount: int
) -> void:
	if item == null:
		return

	if (
		hp_recovery_tutorial != null
		and hp_recovery_tutorial.trigger_event
			== TutorialSequenceData.TriggerEvent.ITEM_ADDED
		and item.id == hp_recovery_tutorial.trigger_item_id
		and (_active_tutorial == null or current_state == TutorialState.COMPLETED)
		and not _hp_recovery_tutorial_completed
	):
		_active_tutorial = hp_recovery_tutorial
		current_step_index = 0
		current_state = TutorialState.WAITING_FOR_ITEM_TUTORIAL
		_show_current_step()
		return

	if (
		fp_recovery_tutorial != null
		and fp_recovery_tutorial.trigger_event
			== TutorialSequenceData.TriggerEvent.ITEM_ADDED
		and item.id == fp_recovery_tutorial.trigger_item_id
		and (_active_tutorial == null or current_state == TutorialState.COMPLETED)
		and not _fp_recovery_tutorial_completed
	):
		_active_tutorial = fp_recovery_tutorial
		current_step_index = 0
		current_state = TutorialState.WAITING_FOR_ITEM_TUTORIAL
		_show_current_step()
		return

	if (
		current_state != TutorialState.WAITING_FOR_EQUIPMENT
		or _equipment_tutorial_completed
	):
		return

	if equipment_tutorial == null:
		return

	if equipment_tutorial.trigger_event != TutorialSequenceData.TriggerEvent.ITEM_ADDED:
		return

	if item.item_type != equipment_tutorial.trigger_item_type:
		return

	_active_tutorial = equipment_tutorial
	current_state = TutorialState.WAITING_FOR_INVENTORY

	current_step_index = 0
	_show_current_step()


func _on_menu_opened() -> void:
	if current_state == TutorialState.WAITING_FOR_ITEM_TUTORIAL:
		var step := _active_tutorial.steps[current_step_index]

		if (
			step.completion_event == TutorialStepData.CompletionEvent.MENU_OPENED
		):
			_advance_step()
			_show_current_step()

			return

	if current_state != TutorialState.WAITING_FOR_INVENTORY:
		return

	current_state = (
		TutorialState.WAITING_FOR_EQUIPMENT_FOCUS
	)

	_advance_step()
	_show_current_step()
	

func _on_item_focused(item: ItemData) -> void:
	if current_state == TutorialState.WAITING_FOR_ITEM_TUTORIAL:
		if item == null:
			return

		var step := _active_tutorial.steps[current_step_index]

		if (
			step.completion_event != TutorialStepData.CompletionEvent.ITEM_FOCUSED
		):
			return

		if (
			not step.target_item_id.is_empty()
			and item.id != step.target_item_id
		):
			return

		_advance_step()
		_show_current_step()
		return

	if current_state != (
		TutorialState.WAITING_FOR_EQUIPMENT_FOCUS
	):
		return

	if item == null:
		return

	if item.item_type != ItemData.ItemType.EQUIPMENT:
		return

	current_state = (
		TutorialState.WAITING_FOR_EQUIPMENT_CONFIRM
	)

	_advance_step()
	_show_current_step()


func _on_item_equipped(
	_slot: int,
	item: EquipmentData
) -> void:
	if current_state != (
		TutorialState.WAITING_FOR_EQUIPMENT_CONFIRM
	):
		return

	if item == null:
		return


	current_state = TutorialState.COMPLETED
	_equipment_tutorial_completed = true

	if _tutorial_ui != null:
		_tutorial_ui.hide_prompt()

	print("Tutorial: equipment confirmed")


func _show_current_step() -> void:
	if _active_tutorial == null:
		return

	if current_step_index < 0:
		return

	if current_step_index >= _active_tutorial.steps.size():
		return

	var step: TutorialStepData = (
		_active_tutorial.steps[current_step_index]
	)

	if step == null:
		return

	if (
		_feature_unlock_state != null
		and not step.unlock_feature_id.is_empty()
	):
		_feature_unlock_state.unlock(
			step.unlock_feature_id
		)

	if _tutorial_ui != null:
		_tutorial_ui.show_prompt(
			step.prompt_text,
			step.wait_for_confirmation
		)


func _advance_step() -> void:
	if _active_tutorial == null:
		return

	if current_step_index >= _active_tutorial.steps.size():
		return

	current_step_index += 1


func _on_battle_started(_enemy: Enemy) -> void:
	if _battle_tutorial_completed:
		return

	if battle_tutorial == null:
		return

	if (
		_active_tutorial != null
		and current_state != TutorialState.COMPLETED
	):
		return

	_active_tutorial = battle_tutorial
	current_step_index = 0
	current_state = (
		TutorialState.WAITING_FOR_BATTLE_CONFIRM
	)

	_show_current_step()


func _on_tutorial_confirmed() -> void:
	var confirmed_state := current_state

	if (
		confirmed_state != TutorialState.WAITING_FOR_BATTLE_CONFIRM
		and confirmed_state != TutorialState.WAITING_FOR_SKILL_CONFIRM
		and confirmed_state != TutorialState.WAITING_FOR_ITEM_CONFIRM
	):
		return

	if _active_tutorial == null:
		return

	if current_step_index >= _active_tutorial.steps.size() - 1:
		current_state = TutorialState.COMPLETED

		if confirmed_state == TutorialState.WAITING_FOR_BATTLE_CONFIRM:
			_battle_tutorial_completed = true
		elif confirmed_state == TutorialState.WAITING_FOR_ITEM_CONFIRM:
			if _active_tutorial == fp_recovery_tutorial:
				_fp_recovery_tutorial_completed = true
			elif _active_tutorial == hp_recovery_tutorial:
				_hp_recovery_tutorial_completed = true

		if _tutorial_ui != null:
			_tutorial_ui.hide_prompt()

		return

	_advance_step()
	_show_current_step()


func _on_skill_learned(skill: SkillData) -> void:
	if skill == null:
		return

	if (
		_active_tutorial != null
		and current_state != TutorialState.COMPLETED
	):
		return

	var needs_mp := false
	var needs_fp := false

	for cost: ActionCostData in skill.costs:
		if cost.value <= 0.0:
			continue

		match cost.cost_type:
			ActionCostData.CostType.MP:
				needs_mp = true
			ActionCostData.CostType.FP:
				needs_fp = true

	var selected_tutorial: TutorialSequenceData = null

	if (
		needs_mp
		and mp_tutorial != null
		and not _feature_unlock_state.is_unlocked(&"mp")
	):
		selected_tutorial = mp_tutorial
	elif (
		needs_fp
		and fp_tutorial != null
		and not _feature_unlock_state.is_unlocked(&"fp")
	):
		selected_tutorial = fp_tutorial

	if selected_tutorial == null:
		return

	_active_tutorial = selected_tutorial
	current_step_index = 0
	current_state = TutorialState.WAITING_FOR_SKILL_CONFIRM
	_show_current_step()


func _on_item_selected(item: ItemData) -> void:
	if current_state != TutorialState.WAITING_FOR_ITEM_TUTORIAL:
		return

	if item == null:
		return

	var step := _active_tutorial.steps[current_step_index]

	if (
		step.completion_event
		!= TutorialStepData.CompletionEvent.ITEM_SELECTED
	):
		return

	if (
		not step.target_item_id.is_empty()
		and item.id != step.target_item_id
	):
		return

	current_state = TutorialState.WAITING_FOR_ITEM_CONFIRM
	_show_current_step()


func capture_save_data() -> Dictionary:
	return {
		"equipment_tutorial_completed": _equipment_tutorial_completed,
		"battle_tutorial_completed": _battle_tutorial_completed,
		"fp_recovery_tutorial_completed": _fp_recovery_tutorial_completed,
		"hp_recovery_tutorial_completed": _hp_recovery_tutorial_completed,
		"feature_unlocks": (
			_feature_unlock_state.capture_save_data()
			if _feature_unlock_state != null
			else []
		),
	}


func restore_save_data(data: Variant) -> void:
	_equipment_tutorial_completed = false
	_battle_tutorial_completed = false
	_fp_recovery_tutorial_completed = false
	_hp_recovery_tutorial_completed = false

	if data is Dictionary:
		_equipment_tutorial_completed = bool(
			data.get("equipment_tutorial_completed", false)
		)
		_battle_tutorial_completed = bool(
			data.get("battle_tutorial_completed", false)
		)
		_fp_recovery_tutorial_completed = bool(
			data.get("fp_recovery_tutorial_completed", false)
		)
		_hp_recovery_tutorial_completed = bool(
			data.get("hp_recovery_tutorial_completed", false)
		)

		if _feature_unlock_state != null:
			_feature_unlock_state.restore_save_data(
				data.get("feature_unlocks", [])
			)

	if _equipment_tutorial_completed:
		current_state = TutorialState.COMPLETED
