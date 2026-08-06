class_name EquipmentPanel
extends PanelContainer

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

@onready var _slot_labels: Dictionary[int, Label] = {
	EquipmentLoadout.Slot.HEAD: $Margin/Content/Slots/Head,
	EquipmentLoadout.Slot.CHEST: $Margin/Content/Slots/Chest,
	EquipmentLoadout.Slot.HANDS: $Margin/Content/Slots/Hands,
	EquipmentLoadout.Slot.LEGS: $Margin/Content/Slots/Legs,
	EquipmentLoadout.Slot.FEET: $Margin/Content/Slots/Feet,
	EquipmentLoadout.Slot.LEFT_HAND: $Margin/Content/Slots/LeftHand,
	EquipmentLoadout.Slot.RIGHT_HAND: $Margin/Content/Slots/RightHand,
	EquipmentLoadout.Slot.ACCESSORY_1: $Margin/Content/Slots/Accessory1,
	EquipmentLoadout.Slot.ACCESSORY_2: $Margin/Content/Slots/Accessory2,
}
@onready var _slot_icons: Dictionary[int, TextureRect] = {
	EquipmentLoadout.Slot.HEAD: $Margin/Content/Slots/Head/Icon,
	EquipmentLoadout.Slot.CHEST: $Margin/Content/Slots/Chest/Icon,
	EquipmentLoadout.Slot.HANDS: $Margin/Content/Slots/Hands/Icon,
	EquipmentLoadout.Slot.LEGS: $Margin/Content/Slots/Legs/Icon,
	EquipmentLoadout.Slot.FEET: $Margin/Content/Slots/Feet/Icon,
	EquipmentLoadout.Slot.LEFT_HAND: $Margin/Content/Slots/LeftHand/Icon,
	EquipmentLoadout.Slot.RIGHT_HAND: $Margin/Content/Slots/RightHand/Icon,
	EquipmentLoadout.Slot.ACCESSORY_1: $Margin/Content/Slots/Accessory1/Icon,
	EquipmentLoadout.Slot.ACCESSORY_2: $Margin/Content/Slots/Accessory2/Icon,
}

var _loadout: EquipmentLoadout


func _ready() -> void:
	pass


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
		var icon: TextureRect = _slot_icons[slot]
		var item: EquipmentData = null
		if _loadout != null:
			item = _loadout.get_equipped(slot)
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


func focus_first_slot() -> void:
	pass
