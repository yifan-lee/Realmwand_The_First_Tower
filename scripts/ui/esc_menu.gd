class_name EscMenu
extends CanvasLayer

signal opened
signal closed

@onready var inventory_panel: InventoryPanel = (
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Columns/InventoryPanel
)
@onready var skill_panel: SkillPanel = (
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Columns/SkillPanel
)
@onready var menu_root: Control = $MenuRoot

var _player: Player


func bind_player(player: Player) -> void:
	_player = player
	refresh_content()


func refresh_content() -> void:
	if _player == null:
		inventory_panel.bind_inventory(null)
		skill_panel.clear_skills()
		return

	inventory_panel.bind_inventory(_player.inventory)
	skill_panel.display_skills(_player.learned_skills)


func open() -> void:
	if menu_root.visible:
		return

	refresh_content()
	menu_root.visible = true

	if _player != null:
		_player.set_input_enabled(false)

	opened.emit()


func close() -> void:
	if not menu_root.visible:
		return

	menu_root.visible = false

	if _player != null:
		_player.set_input_enabled(true)

	closed.emit()


func toggle() -> void:
	if menu_root.visible:
		close()
		return

	open()


func is_open() -> bool:
	return menu_root.visible
