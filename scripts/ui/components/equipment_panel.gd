class_name EquipmentPanel
extends PanelContainer

signal slot_focused(slot: int)
signal slot_selected(slot: int)
signal equip_slot_chosen(slot: int)
signal equip_slot_previewed(slot: int)

const SLOT_NAMES: Dictionary[int, String] = {
	EquipmentLoadout.Slot.HEAD: "头部",
	EquipmentLoadout.Slot.CHEST: "胸甲",
	EquipmentLoadout.Slot.ARMS: "手臂",
	EquipmentLoadout.Slot.HANDS: "手部",
	EquipmentLoadout.Slot.LEGS: "腿部",
	EquipmentLoadout.Slot.FEET: "脚部",
	EquipmentLoadout.Slot.MAIN_WEAPON: "主武器",
	EquipmentLoadout.Slot.SUB_WEAPON: "副武器",
	EquipmentLoadout.Slot.ACCESSORY_1: "饰品 1",
	EquipmentLoadout.Slot.ACCESSORY_2: "饰品 2",
}

@onready var _slot_labels: Dictionary[int, Label] = {
	EquipmentLoadout.Slot.HEAD: $Margin/Content/Slots/Head,
	EquipmentLoadout.Slot.CHEST: $Margin/Content/Slots/Chest,
	EquipmentLoadout.Slot.ARMS: $Margin/Content/Slots/Arms,
	EquipmentLoadout.Slot.HANDS: $Margin/Content/Slots/Hands,
	EquipmentLoadout.Slot.LEGS: $Margin/Content/Slots/Legs,
	EquipmentLoadout.Slot.FEET: $Margin/Content/Slots/Feet,
	EquipmentLoadout.Slot.MAIN_WEAPON: $Margin/Content/Slots/MainWeapon,
	EquipmentLoadout.Slot.SUB_WEAPON: $Margin/Content/Slots/SubWeapon,
	EquipmentLoadout.Slot.ACCESSORY_1: $Margin/Content/Slots/Accessory1,
	EquipmentLoadout.Slot.ACCESSORY_2: $Margin/Content/Slots/Accessory2,
}
@onready var _slot_icons: Dictionary[int, TextureRect] = {
	EquipmentLoadout.Slot.HEAD: $Margin/Content/Slots/Head/Icon,
	EquipmentLoadout.Slot.CHEST: $Margin/Content/Slots/Chest/Icon,
	EquipmentLoadout.Slot.ARMS: $Margin/Content/Slots/Arms/Icon,
	EquipmentLoadout.Slot.HANDS: $Margin/Content/Slots/Hands/Icon,
	EquipmentLoadout.Slot.LEGS: $Margin/Content/Slots/Legs/Icon,
	EquipmentLoadout.Slot.FEET: $Margin/Content/Slots/Feet/Icon,
	EquipmentLoadout.Slot.MAIN_WEAPON: $Margin/Content/Slots/MainWeapon/Icon,
	EquipmentLoadout.Slot.SUB_WEAPON: $Margin/Content/Slots/SubWeapon/Icon,
	EquipmentLoadout.Slot.ACCESSORY_1: $Margin/Content/Slots/Accessory1/Icon,
	EquipmentLoadout.Slot.ACCESSORY_2: $Margin/Content/Slots/Accessory2/Icon,
}

@onready var equip_popup: PopupMenu = $EquipPopupMenu
var _loadout: EquipmentLoadout


func _ready() -> void:
	for slot: int in _slot_labels:
		var label: Label = _slot_labels[slot]
		label.focus_mode = Control.FOCUS_ALL
		label.focus_entered.connect(_on_slot_focus_entered.bind(slot))
		label.gui_input.connect(_on_slot_gui_input.bind(slot))
		
	if equip_popup != null:
		equip_popup.id_pressed.connect(_on_equip_popup_id_pressed)
		equip_popup.id_focused.connect(_on_equip_popup_id_focused)


func _on_slot_focus_entered(slot: int) -> void:
	slot_focused.emit(slot)


func _on_slot_gui_input(event: InputEvent, slot: int) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		slot_selected.emit(slot)
		get_viewport().set_input_as_handled()


func bind_loadout(loadout: EquipmentLoadout) -> void:
	if _loadout != null and _loadout.equipment_changed.is_connected(refresh):
		_loadout.equipment_changed.disconnect(refresh)

	_loadout = loadout

	if _loadout != null:
		_loadout.equipment_changed.connect(refresh)

	refresh()


func refresh() -> void:
	clear_preview()
	for slot: int in _slot_labels:
		var label: Label = _slot_labels[slot]
		var icon: TextureRect = _slot_icons.get(slot)
		var item: EquipmentData = null
		if _loadout != null:
			item = _loadout.get_equipped(slot)
		if icon != null:
			icon.texture = item.icon if item != null else null
			icon.visible = icon.texture != null
		label.text = "%s：%s" % [
			SLOT_NAMES[slot],
			"—" if item == null else item.display_name,
		]


func preview_slots(slots: Array[int]) -> void:
	clear_preview()
	for slot: int in slots:
		if _slot_labels.has(slot):
			_slot_labels[slot].theme_type_variation = &"EquipmentSlotPreviewLabel"


func clear_preview() -> void:
	for label: Label in _slot_labels.values():
		label.theme_type_variation = &"SectionLabel"


func popup_slot_selection(slots: Array[int]) -> void:
	if equip_popup == null:
		return
	equip_popup.clear()
	for slot: int in slots:
		if SLOT_NAMES.has(slot):
			equip_popup.add_item(SLOT_NAMES[slot], slot)
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and focus_owner is Control:
		var rect := focus_owner.get_global_rect()
		equip_popup.position = Vector2i(rect.position.x + rect.size.x + 8, rect.position.y)
		equip_popup.popup()
		equip_popup.set_focused_item(0)
	else:
		equip_popup.popup_centered()
		equip_popup.set_focused_item(0)


func _on_equip_popup_id_pressed(id: int) -> void:
	equip_slot_chosen.emit(id)


func _on_equip_popup_id_focused(id: int) -> void:
	equip_slot_previewed.emit(id)


func focus_first_slot() -> bool:
	if _slot_labels.has(EquipmentLoadout.Slot.HEAD):
		_slot_labels[EquipmentLoadout.Slot.HEAD].grab_focus()
		return true
	return false


func focus_compatible_slot(slots: Array[int]) -> bool:
	if slots.is_empty():
		return false
	if _slot_labels.has(slots[0]):
		_slot_labels[slots[0]].grab_focus()
		return true
	return false


func has_slot_focus(focus: Control = null) -> bool:
	var resolved_focus := focus
	if resolved_focus == null:
		resolved_focus = get_viewport().gui_get_focus_owner()
	return _slot_labels.values().has(resolved_focus)


func is_first_column_focused(focus: Control = null) -> bool:
	var resolved_focus := focus
	if resolved_focus == null:
		resolved_focus = get_viewport().gui_get_focus_owner()
	if resolved_focus != null and _slot_labels.values().has(resolved_focus):
		return resolved_focus.get_index() % 2 == 0
	return false
