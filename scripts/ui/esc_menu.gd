class_name EscMenu
extends CanvasLayer

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal opened
signal closed

enum MainPage {
	INVENTORY,
	SKILLS,
	SYSTEM,
}

const CATEGORY_TYPES: Array[int] = [
	ItemData.ItemType.EQUIPMENT,
	ItemData.ItemType.CONSUMABLE,
	ItemData.ItemType.MATERIAL,
	ItemData.ItemType.KEY_ITEM,
]

@onready var menu_root: Control = $MenuRoot
@onready var inventory_tab: Button = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/MainTabs/InventoryTab
@onready var skills_tab: Button = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/MainTabs/SkillsTab
@onready var system_tab: Button = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/MainTabs/SystemTab
@onready var actor_stats_panel: ActorStatsPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/CharacterColumn/ActorStatsPanel
@onready var equipment_panel: Node = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/CharacterColumn/EquipmentPanel
@onready var inventory_page: Control = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/InventoryPage
@onready var skill_page: Control = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SkillPage
@onready var system_page: SystemPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SystemPage
@onready var inventory_panel: InventoryPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/InventoryPage/InventoryPanel
@onready var all_skill_panel: SkillPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SkillPage/SkillPanelsContainer/AllSkillsColumn/AllSkillPanel
@onready var equipped_skill_panel: SkillPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SkillPage/SkillPanelsContainer/EquippedSkillsColumn/EquippedSkillPanel
@onready var equipped_skills_header: Label = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SkillPage/SkillPanelsContainer/EquippedSkillsColumn/EquippedSkillsHeader
@onready var entry_info_panel: EntryInfoPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/CharacterColumn/SelectionDetailPanel
@onready var category_buttons: Array[Button] = [
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/InventoryPage/CategoryTabs/EquipmentCategory,
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/InventoryPage/CategoryTabs/ConsumableCategory,
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/InventoryPage/CategoryTabs/MaterialCategory,
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/InventoryPage/CategoryTabs/OtherCategory,
]

var _player: Player
var _current_page: MainPage = MainPage.INVENTORY
var _current_category := 0
var _preview_target_slot := -1
var _pending_equip_item: EquipmentData = null
var _pending_assign_skill: SkillData = null
var _input_gate = preload("res://scripts/ui/components/ui_input_gate.gd").new()


func _ready() -> void:
	inventory_tab.pressed.connect(_show_main_page.bind(MainPage.INVENTORY, true))
	skills_tab.pressed.connect(_show_main_page.bind(MainPage.SKILLS, true))
	system_tab.pressed.connect(_show_main_page.bind(MainPage.SYSTEM, true))
	inventory_tab.focus_entered.connect(_show_main_page.bind(MainPage.INVENTORY, false))
	skills_tab.focus_entered.connect(_show_main_page.bind(MainPage.SKILLS, false))
	system_tab.focus_entered.connect(_show_main_page.bind(MainPage.SYSTEM, false))
	for index: int in category_buttons.size():
		category_buttons[index].pressed.connect(_show_category.bind(index, true))
		category_buttons[index].focus_entered.connect(_show_category.bind(index, false))
		category_buttons[index].mouse_entered.connect(category_buttons[index].grab_focus)
	inventory_panel.item_focused.connect(_on_item_focused)
	inventory_panel.item_selected.connect(_on_item_selected)
	equipment_panel.slot_focused.connect(_on_equipment_slot_focused)
	equipment_panel.slot_selected.connect(_on_equipment_slot_selected)
	equipment_panel.equip_slot_chosen.connect(_on_equip_slot_chosen)
	equipment_panel.equip_slot_previewed.connect(_on_equip_slot_previewed)
	if equipment_panel.equip_popup != null:
		equipment_panel.equip_popup.popup_hide.connect(_on_equip_popup_hide)
	all_skill_panel.skill_focused.connect(_on_all_skill_focused)
	all_skill_panel.skill_selected.connect(_on_all_skill_selected)
	equipped_skill_panel.slot_focused.connect(_on_equipped_slot_focused)
	equipped_skill_panel.slot_selected.connect(_on_equipped_slot_selected)
	system_page.save_loaded.connect(close)


func _process(_delta: float) -> void:
	if menu_root.visible:
		_refresh_focus_highlights()


func _input(event: InputEvent) -> void:
	if not menu_root.visible:
		return
	if not _input_gate.filter_event(event):
		get_viewport().set_input_as_handled()
		return
	if _should_preserve_text_input(event):
		return

	if event.is_action_pressed(&"ui_cancel"):
		if _current_page == MainPage.SKILLS and _pending_assign_skill != null:
			_pending_assign_skill = null
			all_skill_panel.clear_highlight()
			all_skill_panel.focus_first_row()
			get_viewport().set_input_as_handled()
			return

	var direction := Vector2i.ZERO
	if event.is_action_pressed(&"ui_left"):
		direction = Vector2i.LEFT
	elif event.is_action_pressed(&"ui_right"):
		direction = Vector2i.RIGHT
	elif event.is_action_pressed(&"ui_up"):
		direction = Vector2i.UP
	elif event.is_action_pressed(&"ui_down"):
		direction = Vector2i.DOWN

	if direction != Vector2i.ZERO and _navigate_focus(direction):
		get_viewport().set_input_as_handled()


func bind_player(player: Player) -> void:
	_player = player
	if _player != null:
		actor_stats_panel.bind_actor(_player, ActorStatsDisplayProfile.menu())
	else:
		actor_stats_panel.unbind_actor()
	refresh_content()


func bind_save_manager(save_manager: SaveManager) -> void:
	system_page.bind_save_manager(save_manager)


func refresh_content() -> void:
	if _player == null:
		inventory_panel.bind_inventory(null)
		all_skill_panel.clear_skills()
		equipped_skill_panel.clear_skills()
		equipment_panel.bind_loadout(null)
		actor_stats_panel.unbind_actor()
		return
	inventory_panel.set_battle_only(false)
	inventory_panel.bind_inventory(_player.inventory)
	
	var badges: Dictionary = {}
	for skill: SkillData in _player.learned_skills:
		if skill != null and _player.is_skill_equipped(skill.id):
			badges[skill.id] = "已携带"
	all_skill_panel.display_skills(_player.learned_skills, badges)
	equipped_skill_panel.display_slots(_player.equipped_skills, PlayerProgression.MAX_EQUIPPED_SKILLS)
	var active_count: int = _player.get_skills().size()
	equipped_skills_header.text = "当前携带技能 (%d/%d)" % [active_count, PlayerProgression.MAX_EQUIPPED_SKILLS]
	
	if _pending_assign_skill != null:
		all_skill_panel.set_highlighted_skill(_pending_assign_skill.id)
	else:
		all_skill_panel.clear_highlight()

	equipment_panel.bind_loadout(_player.equipment)
	actor_stats_panel.clear_preview()
	actor_stats_panel.refresh()


func open() -> void:
	if menu_root.visible:
		return
	_input_gate.reset_gate()
	refresh_content()
	menu_root.visible = true
	if _player != null:
		_player.lock_movement(&"esc_menu")
	_show_main_page(MainPage.INVENTORY, false)
	_show_category(0, false)
	call_deferred(&"_focus_main_tab")
	opened.emit()


func close() -> void:
	if not menu_root.visible:
		return
	menu_root.visible = false
	_pending_assign_skill = null
	all_skill_panel.clear_highlight()
	equipment_panel.clear_preview()
	actor_stats_panel.clear_preview()
	entry_info_panel.clear_info()
	if _player != null:
		_player.unlock_movement(&"esc_menu")
	closed.emit()


func toggle() -> void:
	if menu_root.visible:
		close()
		return
	open()


func is_open() -> bool:
	return menu_root.visible


func refresh_player_stats() -> void:
	if _player == null:
		actor_stats_panel.unbind_actor()
		return
	actor_stats_panel.clear_preview()
	actor_stats_panel.refresh()


func _show_main_page(page: MainPage, focus_content: bool) -> void:
	_current_page = page
	inventory_page.visible = page == MainPage.INVENTORY
	skill_page.visible = page == MainPage.SKILLS
	system_page.visible = page == MainPage.SYSTEM
	equipment_panel.visible = page != MainPage.SKILLS
	_pending_equip_item = null
	_pending_assign_skill = null
	all_skill_panel.clear_highlight()
	entry_info_panel.clear_info()
	refresh_player_stats()
	if page == MainPage.SYSTEM:
		system_page.refresh_saves()
	if focus_content:
		_focus_current_page()


func _show_category(index: int, focus_items: bool) -> void:
	_current_category = posmod(index, CATEGORY_TYPES.size())
	inventory_panel.set_item_type_filter(CATEGORY_TYPES[_current_category])
	_pending_equip_item = null
	entry_info_panel.clear_info()
	refresh_player_stats()
	if focus_items and not inventory_panel.item_rows.focus_first_row():
		category_buttons[_current_category].grab_focus()


func _navigate_focus(direction: Vector2i) -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	if direction.x != 0:
		return _navigate_horizontal_focus(direction.x, focus)
	return _navigate_vertical_focus(direction.y, focus)


func _navigate_horizontal_focus(
	direction: int,
	focus: Control
) -> bool:
	if _is_main_tab_focused():
		var next_page: int = posmod(
			int(_current_page) + direction,
			MainPage.size()
		)
		_show_main_page(next_page, false)
		_focus_main_tab()
		return true

	match _current_page:
		MainPage.INVENTORY:
			if _is_category_focused():
				_show_category(_current_category + direction, false)
				category_buttons[_current_category].grab_focus()
				return true
			if inventory_panel.item_rows.has_row_focus(focus):
				if direction > 0 and equipment_panel.focus_first_slot():
					return true
				return true
			if equipment_panel.has_slot_focus(focus):
				if direction < 0 and equipment_panel.is_first_column_focused(focus):
					inventory_panel.item_rows.focus_first_row()
					return true
				return false
		MainPage.SKILLS:
			if all_skill_panel.has_row_focus(focus):
				if direction > 0:
					var cur_idx := all_skill_panel.get_focused_row_index()
					if equipped_skill_panel.focus_row_at(cur_idx):
						return true
				return true
			if equipped_skill_panel.has_row_focus(focus):
				if direction < 0:
					var cur_idx := equipped_skill_panel.get_focused_row_index()
					if all_skill_panel.focus_row_at(cur_idx):
						return true
				return true
		MainPage.SYSTEM:
			return system_page.navigate_focus(Vector2i(direction, 0))

	return false


func _navigate_vertical_focus(
	direction: int,
	focus: Control
) -> bool:
	if _is_main_tab_focused():
		if direction > 0:
			_focus_current_page()
		return true

	match _current_page:
		MainPage.INVENTORY:
			if _is_category_focused():
				if direction < 0:
					_focus_main_tab()
				else:
					inventory_panel.item_rows.focus_first_row()
				return true
			if inventory_panel.item_rows.has_row_focus(focus):
				if direction < 0 and inventory_panel.item_rows.is_first_row_focused():
					category_buttons[_current_category].grab_focus()
					return true
				return inventory_panel.item_rows.navigate_focus(Vector2i(0, direction))
			if equipment_panel.has_slot_focus(focus):
				return false
		MainPage.SKILLS:
			if all_skill_panel.has_row_focus(focus):
				if direction < 0 and all_skill_panel.skill_rows.is_first_row_focused():
					_focus_main_tab()
					return true
				return all_skill_panel.skill_rows.navigate_focus(Vector2i(0, direction))
			if equipped_skill_panel.has_row_focus(focus):
				if direction < 0 and equipped_skill_panel.skill_rows.is_first_row_focused():
					_focus_main_tab()
					return true
				return equipped_skill_panel.skill_rows.navigate_focus(Vector2i(0, direction))
		MainPage.SYSTEM:
			if system_page.navigate_focus(Vector2i(0, direction)):
				return true
			if direction < 0 and system_page.has_control_focus(focus):
				_focus_main_tab()
				return true

	return false


func _focus_current_page() -> void:
	match _current_page:
		MainPage.INVENTORY:
			category_buttons[_current_category].grab_focus()
		MainPage.SKILLS:
			if not all_skill_panel.focus_first_row():
				if not equipped_skill_panel.focus_first_row():
					skills_tab.grab_focus()
		MainPage.SYSTEM:
			system_page.focus_first_control()


func _focus_main_tab() -> void:
	match _current_page:
		MainPage.INVENTORY:
			inventory_tab.grab_focus()
		MainPage.SKILLS:
			skills_tab.grab_focus()
		MainPage.SYSTEM:
			system_tab.grab_focus()


func _refresh_focus_highlights() -> void:
	var focused_control := get_viewport().gui_get_focus_owner()
	for tab in [inventory_tab, skills_tab, system_tab]:
		tab.set_pressed_no_signal(focused_control == tab)
	for category_button in category_buttons:
		category_button.set_pressed_no_signal(focused_control == category_button)


func _is_main_tab_focused() -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	return focus in [inventory_tab, skills_tab, system_tab]


func _is_category_focused() -> bool:
	var focused_button := (
		get_viewport().gui_get_focus_owner() as Button
	)
	return (
		focused_button != null
		and category_buttons.has(focused_button)
	)


func _is_text_input_focused() -> bool:
	var focused_control := get_viewport().gui_get_focus_owner()
	return (
		focused_control is LineEdit
		or focused_control is TextEdit
	)


func _should_preserve_text_input(event: InputEvent) -> bool:
	if not _is_text_input_focused():
		return false
	var key_event := event as InputEventKey
	if key_event == null:
		return false
	if key_event.unicode > 0:
		return true
	if key_event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		return true
	if key_event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		return true
	return key_event.keycode in [
		KEY_LEFT,
		KEY_RIGHT,
		KEY_HOME,
		KEY_END,
		KEY_BACKSPACE,
		KEY_DELETE,
	]


func _on_item_focused(item: ItemData) -> void:
	equipment_panel.clear_preview()
	_preview_target_slot = -1

	if item is EquipmentData:
		var equipment := item as EquipmentData
		_preview_target_slot = _choose_equipment_target(equipment)
		if _preview_target_slot >= 0:
			_preview_equipment(equipment, _preview_target_slot)
		else:
			actor_stats_panel.set_preview(null)
	else:
		actor_stats_panel.set_preview(item)

	entry_info_panel.display_item(item)


func _on_item_selected(item: ItemData) -> void:
	if _player == null:
		return
	var was_focused := inventory_panel.item_rows.has_row_focus()
	if item is EquipmentData:
		var equipment := item as EquipmentData
		var compatible_slots := _player.equipment.get_compatible_slots(equipment)
		if compatible_slots.size() > 1:
			_pending_equip_item = equipment
			equipment_panel.popup_slot_selection(compatible_slots)
			return
		elif _preview_target_slot >= 0:
			_player.equip_item(item.id, _preview_target_slot)
	else:
		if not item.usable_from_inventory:
			return
		for effect: ActionEffectData in item.effects:
			var val := effect.value
			if effect.calc_method == ActionEffectData.CalcMethod.MAX_RATIO:
				if effect.resource_type == ActionEffectData.ResourceType.HP: val = _player.get_max_hp() * effect.value
				elif effect.resource_type == ActionEffectData.ResourceType.MP: val = _player.get_max_mp() * effect.value
				elif effect.resource_type == ActionEffectData.ResourceType.FP: val = _player.get_max_fp() * effect.value
			if effect.resource_type == ActionEffectData.ResourceType.HP:
				_player.change_hp(val)
			elif effect.resource_type == ActionEffectData.ResourceType.MP:
				_player.change_mp(val)
			elif effect.resource_type == ActionEffectData.ResourceType.FP:
				_player.change_fp(val)
		if item.consumed_on_use:
			_player.inventory.remove_item(item.id)
	refresh_content()
	
	if was_focused and not inventory_panel.item_rows.has_row_focus():
		category_buttons[_current_category].grab_focus()


func _on_all_skill_focused(skill: SkillData) -> void:
	if skill != null:
		actor_stats_panel.set_preview(skill)
		entry_info_panel.display_skill(skill)
	else:
		actor_stats_panel.clear_preview()
		entry_info_panel.clear_info()


func _on_all_skill_selected(skill: SkillData) -> void:
	if skill == null or _player == null:
		return
	_pending_assign_skill = skill
	all_skill_panel.set_highlighted_skill(skill.id)
	
	var cur_slot := _player.get_equipped_slot(skill.id)
	if cur_slot >= 0:
		equipped_skill_panel.focus_row_at(cur_slot)
	else:
		var target_focus := 0
		for i in range(_player.equipped_skills.size()):
			if _player.equipped_skills[i] == null:
				target_focus = i
				break
		equipped_skill_panel.focus_row_at(target_focus)


func _on_equipped_slot_focused(_slot_index: int, skill: SkillData) -> void:
	if skill != null:
		actor_stats_panel.set_preview(skill)
		entry_info_panel.display_skill(skill)
	elif _pending_assign_skill != null:
		actor_stats_panel.set_preview(_pending_assign_skill)
		entry_info_panel.display_skill(_pending_assign_skill)
	else:
		actor_stats_panel.clear_preview()
		entry_info_panel.clear_info()


func _on_equipped_slot_selected(slot_index: int, skill: SkillData) -> void:
	if _player == null:
		return
	if _pending_assign_skill != null:
		var check := _player.can_equip_skill(_pending_assign_skill, slot_index)
		if check.get("allowed", false):
			var assigned_name := _pending_assign_skill.display_name
			_player.equip_skill(_pending_assign_skill, slot_index)
			EventBus.system_message_requested.emit("已将【%s】装备至槽位 %d！" % [assigned_name, slot_index + 1])
			_pending_assign_skill = null
			all_skill_panel.clear_highlight()
			refresh_content()
			equipped_skill_panel.focus_row_at(slot_index)
		else:
			var reason: String = check.get("reason", "无法装备该技能")
			EventBus.system_message_requested.emit(reason)
	else:
		if skill != null:
			var skill_name := skill.display_name
			_player.unequip_skill(slot_index)
			EventBus.system_message_requested.emit("已卸下槽位 %d 的技能【%s】！" % [slot_index + 1, skill_name])
			refresh_content()
			equipped_skill_panel.focus_row_at(slot_index)


func _on_equipment_slot_focused(slot: int) -> void:
	equipment_panel.clear_preview()
	_preview_target_slot = -1
	var slots: Array[int] = [slot]
	equipment_panel.preview_slots(slots)
	actor_stats_panel.clear_preview()

	var item := _player.equipment.get_equipped(slot) if _player != null else null
	entry_info_panel.display_item(item)


func _on_equipment_slot_selected(slot: int) -> void:
	if _player != null and _player.unequip_item(slot):
		refresh_content()
		equipment_panel.focus_first_slot()


func _on_equip_slot_chosen(slot: int) -> void:
	if _pending_equip_item != null and _player != null and _player.equipment.can_equip(_pending_equip_item, slot):
		_player.equip_item(_pending_equip_item.id, slot)
	_pending_equip_item = null
	_preview_target_slot = -1
	refresh_content()
	if not inventory_panel.item_rows.focus_first_row():
		if is_open() and _current_page == MainPage.INVENTORY:
			category_buttons[_current_category].grab_focus()


func _on_equip_slot_previewed(slot: int) -> void:
	if _pending_equip_item == null or _player == null:
		return
	_preview_target_slot = slot
	var preview := ActorStatsPreviewData.new()
	_preview_equipment(_pending_equip_item, slot, preview)
	actor_stats_panel.set_preview(preview)


func _preview_equipment(equipment: EquipmentData, target_slot: int, preview: ActorStatsPreviewData = null) -> void:
	var displaced: Array[EquipmentData] = _player.equipment.get_displaced_items(equipment, target_slot)
	var delta: Dictionary[StringName, float] = FORMULAS.equipment_delta(equipment, displaced)
	var preview_data := preview if preview != null else ActorStatsPreviewData.new()
	preview_data.max_hp_delta = delta[&"max_hp"]
	preview_data.max_mp_delta = delta[&"max_mp"]
	preview_data.atk_delta = delta[&"atk"]
	preview_data.def_delta = delta[&"def"]
	preview_data.spd_delta = delta[&"spd"]
	
	var affected: Array[int] = _player.equipment.get_affected_slots(equipment, target_slot)
	for displaced_item: EquipmentData in displaced:
		for s: int in _player.equipment.get_slots_for_item(displaced_item):
			if not affected.has(s):
				affected.append(s)
	equipment_panel.preview_slots(affected)
	actor_stats_panel.set_preview(preview_data)


func _on_equip_popup_hide() -> void:
	call_deferred("_handle_popup_hide")


func _handle_popup_hide() -> void:
	if _pending_equip_item != null:
		_pending_equip_item = null
		_preview_target_slot = -1
		if is_open() and _current_page == MainPage.INVENTORY:
			inventory_panel.item_rows.focus_first_row()
			actor_stats_panel.clear_preview()


func _choose_equipment_target(item: EquipmentData) -> int:
	if _player == null:
		return -1
	var slots: Array[int] = _player.equipment.get_compatible_slots(item)
	for slot: int in slots:
		if _player.equipment.get_equipped(slot) == null:
			return slot
	return -1 if slots.is_empty() else slots.front()


func _display_entry_info(
	title: String,
	icon: Texture2D,
	description: String,
	details: Array[String]
) -> void:
	var info := EntryInfoViewData.new()
	info.title = title
	info.icon = icon
	info.description = description
	info.detail_lines = details
	entry_info_panel.display_info(info)
