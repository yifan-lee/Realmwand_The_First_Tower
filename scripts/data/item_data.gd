class_name ItemData
extends Resource

enum ItemType {
	CONSUMABLE,
	EQUIPMENT,
	SPECIAL,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var item_type: ItemType

@export_group("HUD")
@export var show_count_in_hud: bool = false

@export_group("Usage")
@export var usable_in_battle: bool = true
@export var consumed_on_use: bool = true

@export_group("Recovery")
@export var healing_amount: int = 0
@export var mp_recovery_amount: int = 0


func get_category_name() -> String:
	match item_type:
		ItemType.CONSUMABLE:
			return "Potions"
		ItemType.EQUIPMENT:
			return "Equipment"
		ItemType.SPECIAL:
			return "Special"

	return "Special"
