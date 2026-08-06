@tool
class_name ItemPickup
extends Area2D

signal picked_up(item: ItemData, amount: int)

@export_group("Identity")
@export var pickup_id: StringName = &""

@export_group("Content")
@export var item_data: ItemData:
	set(value):
		item_data = value
		_refresh_visual()

@export_range(1, 999, 1) var amount: int = 1

var is_collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_visual()


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if is_collected:
		return

	if not body is Player:
		return

	if item_data == null or amount <= 0:
		return

	var player := body as Player
	var remaining_amount: int = (
		player.inventory.add_item(item_data, amount)
	)
	var accepted_amount: int = amount - remaining_amount

	if accepted_amount <= 0:
		return

	picked_up.emit(item_data, accepted_amount)

	if remaining_amount == 0:
		set_collected(true)
	else:
		amount = remaining_amount


func _refresh_visual() -> void:
	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return

	if item_data == null:
		sprite.texture = null
		return

	sprite.texture = item_data.world_texture


func get_instance_id() -> String:
	if not pickup_id.is_empty():
		return pickup_id
	return IdGenerator.generate_instance_id(self, item_data)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if item_data == null:
		warnings.append(
			"ItemPickup requires an ItemData resource."
		)
	elif item_data.id.is_empty():
		warnings.append(
			"ItemPickup's ItemData requires a non-empty ID."
		)
	elif item_data.world_texture == null:
		warnings.append(
			"ItemPickup's ItemData has no world texture."
		)

	return warnings


func set_collected(collected: bool) -> void:
	is_collected = collected
	visible = not is_collected

	set_deferred(
		"monitoring",
		not is_collected
	)