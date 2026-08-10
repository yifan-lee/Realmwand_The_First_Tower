class_name TutorialManager
extends Node


enum TutorialState {
	WAITING_FOR_EQUIPMENT,
	WAITING_FOR_INVENTORY,
	WAITING_FOR_EQUIPMENT_FOCUS,
	COMPLETED,
}


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

	if _player == null:
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


func _on_item_added(
	item: ItemData,
	_amount: int
) -> void:
	if current_state != TutorialState.WAITING_FOR_EQUIPMENT:
		return

	if item == null:
		return

	if item.item_type != ItemData.ItemType.EQUIPMENT:
		return

	current_state = TutorialState.WAITING_FOR_INVENTORY

	if _tutorial_ui != null:
		_tutorial_ui.show_prompt(
            "获得了装备。\n按 ESC 打开背包。"
		)

func _on_menu_opened() -> void:
	if current_state != TutorialState.WAITING_FOR_INVENTORY:
		return

	current_state = (
		TutorialState.WAITING_FOR_EQUIPMENT_FOCUS
	)

	if _tutorial_ui != null:
		_tutorial_ui.show_prompt(
            "移动光标，选择刚才获得的装备。"
		)


func _on_item_focused(item: ItemData) -> void:
	if current_state != (
		TutorialState.WAITING_FOR_EQUIPMENT_FOCUS
	):
		return

	if item == null:
		return

	if item.item_type != ItemData.ItemType.EQUIPMENT:
		return

	current_state = TutorialState.COMPLETED

	if _tutorial_ui != null:
		_tutorial_ui.hide_prompt()

	print("Tutorial: equipment focused")
