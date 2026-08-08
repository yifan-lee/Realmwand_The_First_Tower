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
@export var effects: Array[ActionEffectData] = []
@export var costs: Array[ActionCostData] = []


func get_details() -> Array[String]:
	var result: Array[String] = []
	
	var effect_lines: Array[String] = []
	for effect: ActionEffectData in effects:
		var desc := effect.get_description()
		if not desc.is_empty():
			effect_lines.append(desc)
			
	if not effect_lines.is_empty():
		result.append("\n[color=#A0A0A0]【效果】[/color]")
		result.append_array(effect_lines)
		
	var cost_lines: Array[String] = []
	for cost: ActionCostData in costs:
		var desc := cost.get_description()
		if not desc.is_empty():
			cost_lines.append(desc)
			
	if not cost_lines.is_empty():
		result.append("\n[color=#A0A0A0]【消耗】[/color]")
		result.append_array(cost_lines)

	return result
