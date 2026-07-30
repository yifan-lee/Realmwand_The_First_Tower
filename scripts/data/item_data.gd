class_name ItemData
extends Resource

enum ItemType {
	CONSUMABLE,
	EQUIPMENT,
	KEY_ITEM,
	MATERIAL,
}

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE

@export_group("Visual")
@export var icon: Texture2D
@export var world_texture: Texture2D

@export_group("Inventory")
@export_range(1, 999, 1) var max_stack: int = 99

@export_group("Usage")
@export var usable_from_inventory: bool = false
@export var usable_in_battle: bool = false
@export var consumed_on_use: bool = false