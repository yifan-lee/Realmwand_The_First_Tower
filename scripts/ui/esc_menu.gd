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
@onready var skill_panel: SkillPanel = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SkillPage/SkillPanel
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
	skill_panel.skill_focused.connect(_on_skill_focused)
	system_page.save_loaded.connect(close)


func _process(_delta: float) -> void:
	if menu_root.visible:
		_refresh_focus_highlights()


func _input(event: InputEvent) -> void:
	if not menu_root.visible:
		return
	if _should_preserve_text_input(event):
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
	refresh_content()


func bind_save_manager(save_manager: SaveManager) -> void:
	system_page.bind_save_manager(save_manager)


func refresh_content() -> void:
	if _player == null:
		inventory_panel.bind_inventory(null)
		skill_panel.clear_skills()
		equipment_panel.bind_loadout(null)
		actor_stats_panel.clear_stats()
		return
	inventory_panel.set_battle_only(false)
	inventory_panel.bind_inventory(_player.inventory)
	skill_panel.display_skills(_player.learned_skills)
	equipment_panel.bind_loadout(_player.equipment)
	refresh_player_stats()


func open() -> void:
	if menu_root.visible:
		return
	refresh_content()
	menu_root.visible = true
	if _player != null:
		_player.set_input_enabled(false)
	_show_main_page(MainPage.INVENTORY, false)
	_show_category(0, false)
	call_deferred(&"_focus_main_tab")
	opened.emit()


func close() -> void:
	if not menu_root.visible:
		return
	menu_root.visible = false
	equipment_panel.clear_preview()
	entry_info_panel.clear_info()
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


func refresh_player_stats(view: ActorStatsViewData = null) -> void:
	if _player == null:
		actor_stats_panel.clear_stats()
		return
	actor_stats_panel.display_stats(view if view != null else _build_player_view())


func _show_main_page(page: MainPage, focus_content: bool) -> void:
	_current_page = page
	inventory_page.visible = page == MainPage.INVENTORY
	skill_page.visible = page == MainPage.SKILLS
	system_page.visible = page == MainPage.SYSTEM
	equipment_panel.visible = page != MainPage.SKILLS
	equipment_panel.clear_preview()
	entry_info_panel.clear_info()
	refresh_player_stats()
	if page == MainPage.SYSTEM:
		system_page.refresh_saves()
	if focus_content:
		_focus_current_page()


func _show_category(index: int, focus_items: bool) -> void:
	_current_category = posmod(index, CATEGORY_TYPES.size())
	inventory_panel.set_item_type_filter(CATEGORY_TYPES[_current_category])
	equipment_panel.clear_preview()
	entry_info_panel.clear_info()
	refresh_player_stats()
	if focus_items and not inventory_panel.focus_first_item():
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
			if inventory_panel.has_item_focus(focus):
				return true
		MainPage.SKILLS:
			if skill_panel.has_skill_focus(focus):
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
					inventory_panel.focus_first_item()
				return true
			if inventory_panel.has_item_focus(focus):
				if direction < 0 and inventory_panel.is_first_item_focused():
					category_buttons[_current_category].grab_focus()
					return true
				return inventory_panel.navigate_item_focus(direction)
		MainPage.SKILLS:
			if skill_panel.has_skill_focus(focus):
				if direction < 0 and skill_panel.is_first_skill_focused():
					_focus_main_tab()
					return true
				return skill_panel.navigate_skill_focus(direction)
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
			if not skill_panel.focus_first_skill():
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
	var view := _build_player_view()
	var details: Array[String] = []
	if item is EquipmentData:
		var equipment := item as EquipmentData
		_preview_target_slot = _choose_equipment_target(equipment)
		if _preview_target_slot >= 0:
			var displaced: Array[EquipmentData] = _player.equipment.get_displaced_items(equipment, _preview_target_slot)
			var delta: Dictionary[StringName, float] = FORMULAS.equipment_delta(equipment, displaced)
			view.max_hp_delta = delta[&"max_hp"]
			view.max_mp_delta = delta[&"max_mp"]
			view.atk_delta = delta[&"atk"]
			view.def_delta = delta[&"def"]
			view.spd_delta = delta[&"spd"]
			var affected: Array[int] = _player.equipment.get_affected_slots(equipment, _preview_target_slot)
			for displaced_item: EquipmentData in displaced:
				for slot: int in _player.equipment.get_slots_for_item(displaced_item):
					if not affected.has(slot):
						affected.append(slot)
			equipment_panel.preview_slots(affected)
			details.append("确认后装备；高亮槽位会被占用或替换")
	else:
		var hp_rec := 0.0
		var mp_rec := 0.0
		var fp_rec := 0.0
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
		view.current_hp_delta = FORMULAS.calculate_recovery_delta(_player.current_hp, _player.get_max_hp(), hp_rec)
		view.current_mp_delta = FORMULAS.calculate_recovery_delta(_player.current_mp, _player.get_max_mp(), mp_rec)
		view.current_fp_delta = FORMULAS.calculate_recovery_delta(_player.current_fp, _player.get_max_fp(), fp_rec)
	refresh_player_stats(view)
	_display_entry_info(item.display_name, item.icon, item.description, details)


func _on_item_selected(item: ItemData) -> void:
	if _player == null:
		return
	if item is EquipmentData:
		if _preview_target_slot >= 0:
			_player.equip_item(item.id, _preview_target_slot)
	else:
		if not item.usable_from_inventory:
			return
		for effect: ActionEffectData in item.effects:
			if effect.effect_type == ActionEffectData.EffectType.RESTORE_HP:
				_player.change_hp(effect.value)
			elif effect.effect_type == ActionEffectData.EffectType.RESTORE_MP:
				_player.change_mp(effect.value)
			elif effect.effect_type == ActionEffectData.EffectType.RESTORE_FP:
				_player.change_fp(effect.value)
		if item.consumed_on_use:
			_player.inventory.remove_item(item.id)
	refresh_content()
	_show_category(_current_category, true)


func _on_skill_focused(skill: SkillData) -> void:
	var view := _build_player_view()
	for effect: ActionEffectData in skill.effects:
		if effect.target_type != ActionEffectData.TargetType.SELF:
			continue
		match effect.effect_type:
			ActionEffectData.EffectType.ATK:
				view.atk_delta += FORMULAS.skill_effect_delta(view.atk, effect)
			ActionEffectData.EffectType.DEF:
				view.def_delta += FORMULAS.skill_effect_delta(view.def, effect)
			ActionEffectData.EffectType.SPD:
				view.spd_delta += FORMULAS.skill_effect_delta(view.spd, effect)
	refresh_player_stats(view)
	_display_entry_info(skill.display_name, skill.icon, skill.description, skill.get_details())


func _on_equipment_slot_focused(slot: int) -> void:
	equipment_panel.clear_preview()
	var slots: Array[int] = [slot] # 显式类型声明将数组转换/实例化为 Array[int]
	equipment_panel.preview_slots(slots)
	refresh_player_stats()

	var item: EquipmentData = _player.equipment.get_equipped(slot)
	if item == null:
		entry_info_panel.clear_info()
		return
	_display_entry_info(item.display_name, item.icon, item.description, ["确认后卸下装备"])


func _on_equipment_slot_selected(slot: int) -> void:
	if _player.unequip_item(slot):
		refresh_content()
		equipment_panel.focus_first_slot()


func _choose_equipment_target(item: EquipmentData) -> int:
	var slots: Array[int] = _player.equipment.get_compatible_slots(item)
	for slot: int in slots:
		if _player.equipment.get_equipped(slot) == null:
			return slot
	return -1 if slots.is_empty() else slots.front()


func _build_player_view() -> ActorStatsViewData:
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
	view.atk = _player.get_atk()
	view.def = _player.get_def()
	view.spd = _player.get_spd()
	return view


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
