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
@onready var system_page: Control = $MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Body/PageColumn/SystemPage
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


func _process(_delta: float) -> void:
	if menu_root.visible:
		_refresh_focus_highlights()


func _input(event: InputEvent) -> void:
	if not menu_root.visible:
		return
	if event.is_action_pressed(&"ui_left"):
		_navigate_horizontal(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_right"):
		_navigate_horizontal(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_up"):
		if _is_category_focused():
			_focus_main_tab()
			get_viewport().set_input_as_handled()
		elif _current_page == MainPage.INVENTORY and inventory_panel.is_first_item_focused():
			category_buttons[_current_category].grab_focus()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_down"):
		if _is_main_tab_focused():
			_focus_current_page()
			get_viewport().set_input_as_handled()
		elif _is_category_focused():
			inventory_panel.focus_first_item()
			get_viewport().set_input_as_handled()


func bind_player(player: Player) -> void:
	_player = player
	refresh_content()


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
	equipment_panel.clear_preview()
	entry_info_panel.clear_info()
	refresh_player_stats()
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


func _navigate_horizontal(direction: int) -> void:
	var focus: Control = get_viewport().gui_get_focus_owner()
	if _current_page == MainPage.INVENTORY and _is_in_control(focus, inventory_page):
		_show_category(_current_category + direction, true)
		return
	var next_page: int = posmod(int(_current_page) + direction, MainPage.size())
	_show_main_page(next_page, false)
	_focus_main_tab()


func _focus_current_page() -> void:
	match _current_page:
		MainPage.INVENTORY:
			category_buttons[_current_category].grab_focus()
		MainPage.SKILLS:
			if not skill_panel.focus_first_skill():
				skills_tab.grab_focus()
		MainPage.SYSTEM:
			system_tab.grab_focus()


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
	return get_viewport().gui_get_focus_owner() in category_buttons


func _is_in_control(focus: Control, ancestor: Control) -> bool:
	if focus == null:
		return false
	return focus == ancestor or ancestor.is_ancestor_of(focus)


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
		view.current_hp_delta = FORMULAS.calculate_recovery_delta(_player.current_hp, _player.get_max_hp(), item.hp_recovery)
		view.current_mp_delta = FORMULAS.calculate_recovery_delta(_player.current_mp, _player.get_max_mp(), item.mp_recovery)
		details.append("生命回复：%.0f" % item.hp_recovery)
		details.append("魔力回复：%.0f" % item.mp_recovery)
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
		_player.change_hp(item.hp_recovery)
		_player.change_mp(item.mp_recovery)
		if item.consumed_on_use:
			_player.inventory.remove_item(item.id)
	refresh_content()
	_show_category(_current_category, true)


func _on_skill_focused(skill: SkillData) -> void:
	var view := _build_player_view()
	for effect: SkillEffectData in skill.effects:
		if effect.target_type != SkillEffectData.TargetType.SELF:
			continue
		match effect.effect_type:
			SkillEffectData.EffectType.ATK:
				view.atk_delta += FORMULAS.skill_effect_delta(view.atk, effect)
			SkillEffectData.EffectType.DEF:
				view.def_delta += FORMULAS.skill_effect_delta(view.def, effect)
			SkillEffectData.EffectType.SPD:
				view.spd_delta += FORMULAS.skill_effect_delta(view.spd, effect)
	refresh_player_stats(view)
	_display_entry_info(skill.display_name, skill.icon, skill.description, [
		"类型：%s" % _skill_type_label(skill.skill_type),
		"魔力消耗：%.0f" % skill.mp_cost,
		"专注消耗：%.0f" % skill.fp_cost,
		"冷却：%.1f 秒" % skill.cooldown_seconds,
		"吟唱：行动条倒退 %.0f%%" % (skill.cast_time * 100.0),
	])


func _skill_type_label(skill_type: SkillData.SkillType) -> String:
	match skill_type:
		SkillData.SkillType.MAGICAL:
			return "魔法"
		SkillData.SkillType.TRANSFORM:
			return "变换"
		_:
			return "物理"


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
