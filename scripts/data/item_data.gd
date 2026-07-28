class_name ItemData
extends Resource

enum ItemType {
	CONSUMABLE,
	WEAPON,
}

@export var id: StringName
@export var display_name: String
@export var item_type: ItemType
@export var healing_amount: int = 0
@export var attack_bonus: int = 0