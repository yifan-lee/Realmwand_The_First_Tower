class_name EquipmentPanel
extends PanelContainer

signal slot_focused(slot: int)
signal slot_selected(slot: int)

const SLOT_NAMES: Dictionary[int, String] = {
	EquipmentLoadout.Slot.HEAD: "头部",
	EquipmentLoadout.Slot.CHEST: "胸甲",
	EquipmentLoadout.Slot.HANDS: "手部",
	EquipmentLoadout.Slot.LEGS: "腿部",
	EquipmentLoadout.Slot.FEET: "脚部",
	EquipmentLoadout.Slot.LEFT_HAND: "左手",
	EquipmentLoadout.Slot.RIGHT_HAND: "右手",
	EquipmentLoadout.Slot.ACCESSORY_1: "饰品 1",
	EquipmentLoadout.Slot.ACCESSORY_2: "饰品 2",
}

@onready var _slot_buttons: Dictionary[int, Button] = {
	EquipmentLoadout.Slot.HEAD: $Margin/Content/SlotScroll/Slots/Head,
	EquipmentLoadout.Slot.CHEST: $Margin/Content/SlotScroll/Slots/Chest,
	EquipmentLoadout.Slot.HANDS: $Margin/Content/SlotScroll/Slots/Hands,
	EquipmentLoadout.Slot.LEGS: $Margin/Content/SlotScroll/Slots/Legs,
	EquipmentLoadout.Slot.FEET: $Margin/Content/SlotScroll/Slots/Feet,
	EquipmentLoadout.Slot.LEFT_HAND: $Margin/Content/SlotScroll/Slots/LeftHand,
	EquipmentLoadout.Slot.RIGHT_HAND: $Margin/Content/SlotScroll/Slots/RightHand,
	EquipmentLoadout.Slot.ACCESSORY_1: $Margin/Content/SlotScroll/Slots/Accessory1,
	EquipmentLoadout.Slot.ACCESSORY_2: $Margin/Content/SlotScroll/Slots/Accessory2,
}

var _loadout: EquipmentLoadout


func _ready() -> void:
	for slot: int in _slot_buttons:
		var button: Button = _slot_buttons[slot]
		button.focus_entered.connect(
			slot_focused.emit.bind(slot)
		)
		button.mouse_entered.connect(button.grab_focus)
		button.pressed.connect(slot_selected.emit.bind(slot))


func bind_loadout(loadout: EquipmentLoadout) -> void:
	if _loadout != null and _loadout.equipment_changed.is_connected(refresh):
		_loadout.equipment_changed.disconnect(refresh)

	_loadout = loadout

	if _loadout != null:
		_loadout.equipment_changed.connect(refresh)

	refresh()


func refresh() -> void:
	clear_preview()
	for slot: int in _slot_buttons:
		var button: Button = _slot_buttons[slot]
		var item: EquipmentData = null
		if _loadout != null:
			item = _loadout.get_equipped(slot)
		button.text = "%s：%s" % [
			SLOT_NAMES[slot],
			"—" if item == null else item.display_name,
		]


func preview_slots(slots: Array[int]) -> void:
	clear_preview()
	for slot: int in slots:
		if _slot_buttons.has(slot):
			_slot_buttons[slot].set_pressed_no_signal(true)
			_slot_buttons[slot].self_modulate = Color("#FFD54AFF")


func clear_preview() -> void:
	for button: Button in _slot_buttons.values():
		button.set_pressed_no_signal(false)
		button.self_modulate = Color("#FFFFFFFF")


func focus_first_slot() -> void:
	_slot_buttons[EquipmentLoadout.Slot.HEAD].grab_focus()
