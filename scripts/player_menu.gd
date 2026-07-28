class_name PlayerMenu
extends Control

signal closed

@onready var action_panel: PanelContainer = $ActionPanel
@onready var skills_button: Button = (
	$ActionPanel/Actions/SkillsButton
)
@onready var inventory_button: Button = (
	$ActionPanel/Actions/InventoryButton
)
@onready var system_button: Button = (
	$ActionPanel/Actions/SystemButton
)
@onready var skill_menu: SkillMenu = $SkillMenu
@onready var inventory_menu: InventoryMenu = $InventoryMenu
@onready var detail_panel: SelectionDetailPanel = (
	$SelectionDetailPanel
)
@onready var status_panel: CombatantStatusPanel = (
	$PlayerStatusPanel
)

var player_data: Player


func _ready() -> void:
	skills_button.focus_entered.connect(
		_on_skills_button_focused
	)
	skills_button.mouse_entered.connect(
		_on_skills_button_focused
	)
	skills_button.pressed.connect(
		_on_skills_button_pressed
	)

	inventory_button.focus_entered.connect(
		_on_inventory_button_focused
	)
	inventory_button.mouse_entered.connect(
		_on_inventory_button_focused
	)
	inventory_button.pressed.connect(
		_on_inventory_button_pressed
	)

	system_button.focus_entered.connect(
		_on_system_button_focused
	)
	system_button.mouse_entered.connect(
		_on_system_button_focused
	)
	system_button.pressed.connect(
		_on_system_button_focused
	)

	skill_menu.skill_focused.connect(
		_on_skill_focused
	)
	skill_menu.skill_focus_cleared.connect(
		_clear_selection_preview
	)
	skill_menu.cancelled.connect(
		_on_skill_menu_cancelled
	)

	inventory_menu.item_focused.connect(
		_on_item_focused
	)
	inventory_menu.item_focus_cleared.connect(
		_clear_selection_preview
	)
	inventory_menu.item_selected.connect(
		_on_item_selected
	)
	inventory_menu.cancelled.connect(
		_on_inventory_menu_cancelled
	)


func open(player: Player) -> void:
	player_data = player
	visible = true
	action_panel.visible = true
	_refresh_status()
	_clear_selection_preview()
	skills_button.call_deferred("grab_focus")


func close() -> void:
	if not visible:
		return

	skill_menu.close()
	inventory_menu.close()
	_clear_selection_preview()
	action_panel.visible = true
	visible = false
	closed.emit()


func _on_skills_button_focused() -> void:
	if not visible:
		return

	inventory_menu.close()
	_show_skill_menu(false)


func _on_skills_button_pressed() -> void:
	if not visible:
		return

	inventory_menu.close()
	_show_skill_menu(false)
	action_panel.visible = false
	skill_menu.grab_first_skill_focus()


func _show_skill_menu(focus_first_skill: bool) -> void:
	skill_menu.open(
		player_data.learned_skills,
		player_data.current_mp,
		{},
		focus_first_skill
	)


func _on_inventory_button_focused() -> void:
	if not visible:
		return

	skill_menu.close()
	_clear_selection_preview()
	_show_inventory_menu(false)


func _on_inventory_button_pressed() -> void:
	if not visible:
		return

	skill_menu.close()
	_show_inventory_menu(false)
	action_panel.visible = false
	inventory_menu.grab_first_category_focus()


func _show_inventory_menu(
	focus_first_category: bool
) -> void:
	inventory_menu.open(
		player_data.inventory,
		focus_first_category
	)


func _on_system_button_focused() -> void:
	if not visible:
		return

	skill_menu.close()
	inventory_menu.close()
	_clear_selection_preview()

	var detail := SelectionDetailData.new()
	detail.title = "System"
	detail.description = (
		"System options will be added here later."
	)
	detail_panel.show_detail(detail)


func _on_skill_menu_cancelled() -> void:
	_clear_selection_preview()
	skill_menu.close()
	action_panel.visible = true
	skills_button.grab_focus()


func _on_inventory_menu_cancelled() -> void:
	_clear_selection_preview()
	inventory_menu.close()
	action_panel.visible = true
	inventory_button.grab_focus()


func _on_skill_focused(skill: SkillData) -> void:
	var detail := SelectionDetailBuilder.from_skill(
		skill,
		player_data.current_mp,
		0.0
	)
	var previews := SkillPreviewBuilder.build(
		skill,
		player_data
	)
	var preview := (
		previews["player"] as CombatantPreviewData
	)

	detail_panel.show_detail(detail)
	status_panel.show_preview(preview)


func _on_item_focused(item: ItemData) -> void:
	var detail := SelectionDetailBuilder.from_item(
		item,
		player_data,
		false
	)
	var preview := ItemPreviewBuilder.for_player(
		item,
		player_data
	)

	detail_panel.show_detail(detail)
	status_panel.show_preview(preview)


func _on_item_selected(item: ItemData) -> void:
	if not ItemUseService.use(item, player_data, false):
		return

	_refresh_status()
	_clear_selection_preview()
	_show_inventory_menu(true)


func _refresh_status() -> void:
	if player_data == null:
		return

	status_panel.set_data(
		CombatantStatusViewData.from_player(player_data)
	)


func _clear_selection_preview() -> void:
	detail_panel.clear_detail()
	status_panel.clear_preview()


func _unhandled_key_input(event: InputEvent) -> void:
	if (
		not visible
		or not action_panel.visible
		or not event.is_action_pressed("ui_cancel")
	):
		return

	close()
	get_viewport().set_input_as_handled()
