class_name EquipmentData
extends ItemData


enum EquipmentSlotType {
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	WEAPON,
	ACCESSORY,
	ARMS,
}

enum WeaponRule {
	NONE,
	MAIN_ONLY,
	SUB_ONLY,
	EITHER_WEAPON,
	TWO_HANDED,
}

@export_group("Equipment")
@export var slot_type: EquipmentSlotType = EquipmentSlotType.WEAPON
@export var weapon_rule: WeaponRule = WeaponRule.NONE


@export_group("Stat Bonuses")
@export var max_hp_bonus: float = 0.0
@export var max_mp_bonus: float = 0.0
@export var atk_bonus: float = 0.0
@export var def_bonus: float = 0.0
@export var spd_bonus: float = 0.0