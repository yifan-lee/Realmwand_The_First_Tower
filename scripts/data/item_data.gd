@tool
class_name ItemData
extends Resource

enum ItemType {
	CONSUMABLE,
	EQUIPMENT,
	KEY_ITEM,
	MATERIAL,
}

@export_group("Identity")
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var item_type: ItemType

@export_group("Visual")
@export var icon: Texture2D
@export var world_texture: Texture2D

@export_group("Inventory")
@export_range(1, 999, 1) var max_stack: int = 99

@export_group("HUD")
@export var show_count_in_hud: bool = false

@export_group("Usage")
@export var usable_from_inventory: bool = false
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
		ItemType.KEY_ITEM:
			return "Key Items"
		ItemType.MATERIAL:
			return "Materials"

	return "Key Items"


func get_world_texture() -> Texture2D:
	if world_texture != null:
		return world_texture

	return icon
