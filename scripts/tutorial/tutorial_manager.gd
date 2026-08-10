class_name TutorialManager
extends Node


enum TutorialState {
	WAITING_FOR_EQUIPMENT,
	WAITING_FOR_INVENTORY,
	COMPLETED,
}


var current_state: TutorialState = (
	TutorialState.WAITING_FOR_EQUIPMENT
)
var _player: Player
var _esc_menu: EscMenu


func setup(
	player: Player,
	esc_menu: EscMenu
) -> void:
	_player = player
	_esc_menu = esc_menu

	if _player == null:
		return

	_player.inventory.item_added.connect(
		_on_item_added
	)
	
	_esc_menu.opened.connect(
		_on_menu_opened
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

	print("Tutorial: equipment picked up")

func _on_menu_opened() -> void:
	if current_state != TutorialState.WAITING_FOR_INVENTORY:
		return

	current_state = TutorialState.COMPLETED

	print("Tutorial: inventory opened")
