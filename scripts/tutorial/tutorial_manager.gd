class_name TutorialManager
extends Node

@export var equipment_tutorial: TutorialSequenceData
enum TutorialState {
	WAITING_FOR_EQUIPMENT,
	WAITING_FOR_INVENTORY,
	WAITING_FOR_EQUIPMENT_FOCUS,
	WAITING_FOR_EQUIPMENT_CONFIRM,
	COMPLETED,
}

var current_step_index: int = 0
var current_state: TutorialState = TutorialState.WAITING_FOR_EQUIPMENT
var _player: Player
var _esc_menu: EscMenu
var _tutorial_ui: TutorialUI


func setup(
	player: Player,
	esc_menu: EscMenu,
	tutorial_ui: TutorialUI
) -> void:
	_player = player
	_esc_menu = esc_menu
	_tutorial_ui = tutorial_ui


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


func _on_item_added(
	item: ItemData,
	_amount: int
) -> void:
	if current_state != TutorialState.WAITING_FOR_EQUIPMENT:
		return

	if equipment_tutorial == null:
		return

	if equipment_tutorial.trigger_event != TutorialSequenceData.TriggerEvent.ITEM_ADDED:
		return

	if item == null:
		return

	if item.item_type != equipment_tutorial.trigger_item_type:
		return

	current_state = TutorialState.WAITING_FOR_INVENTORY

	current_step_index = 0
	_show_current_step()


func _on_menu_opened() -> void:
	if current_state != TutorialState.WAITING_FOR_INVENTORY:
		return

	current_state = (
		TutorialState.WAITING_FOR_EQUIPMENT_FOCUS
	)

	_advance_step()
	_show_current_step()
	

func _on_item_focused(item: ItemData) -> void:
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

	if _tutorial_ui != null:
		_tutorial_ui.hide_prompt()

	print("Tutorial: equipment confirmed")


func _show_current_step() -> void:
	if equipment_tutorial == null:
		return

	if current_step_index < 0:
		return

	if current_step_index >= equipment_tutorial.steps.size():
		return

	var step: TutorialStepData = (
		equipment_tutorial.steps[current_step_index]
	)

	if step == null:
		return

	if _tutorial_ui != null:
		_tutorial_ui.show_prompt(
			step.prompt_text
		)


func _advance_step() -> void:
	if equipment_tutorial == null:
		return

	if current_step_index >= equipment_tutorial.steps.size():
		return

	current_step_index += 1
