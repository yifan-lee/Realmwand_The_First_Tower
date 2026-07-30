class_name EquipmentData
extends ItemData


enum EquipmentSlotType {
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	HAND,
	ACCESSORY,
}

enum HandRule {
	NONE,
	LEFT_ONLY,
	RIGHT_ONLY,
	EITHER_HAND,
	TWO_HANDED,
}

@export_group("Equipment")
@export var slot_type: EquipmentSlotType = EquipmentSlotType.HAND
@export var hand_rule: HandRule = HandRule.NONE


@export_group("Stat Bonuses")
@export var max_hp_bonus: float = 0.0
@export var max_mp_bonus: float = 0.0
@export var atk_bonus: float = 0.0
@export var def_bonus: float = 0.0
@export var spd_bonus: float = 0.0