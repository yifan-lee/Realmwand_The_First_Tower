class_name ItemData
extends Resource

enum ItemType {
	CONSUMABLE,
	WEAPON,
	SPECIAL,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var item_type: ItemType

@export_group("Usage")
@export var usable_in_battle: bool = true
@export var consumed_on_use: bool = true

@export_group("Recovery")
@export var healing_amount: int = 0
@export var mp_recovery_amount: int = 0

@export_group("Equipment")
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var speed_bonus: int = 0


func get_category_name() -> String:
	match item_type:
		ItemType.CONSUMABLE:
			return "Potions"
		ItemType.WEAPON:
			return "Equipment"
		ItemType.SPECIAL:
			return "Special"

	return "Special"
