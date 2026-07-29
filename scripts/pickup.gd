@tool
extends Area2D


signal collected(persistent_id: StringName)

@export var item_data: ItemData:
	set(value):
		if (
			item_data != null
			and item_data.changed.is_connected(
				_on_item_data_changed
			)
		):
			item_data.changed.disconnect(
				_on_item_data_changed
			)

		item_data = value

		if item_data != null:
			item_data.changed.connect(
				_on_item_data_changed
			)

		_refresh_visual()
@export var persistent_id: StringName


func _ready() -> void:
	_refresh_visual()


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return

	if item_data == null:
		push_warning("Pickup 没有配置 ItemData")
		return

	player.add_item(item_data)
	collected.emit(get_floor_state_id())
	queue_free()


func get_floor_state_id() -> StringName:
	if persistent_id != &"":
		return persistent_id

	return StringName(name)


func save_floor_state() -> Dictionary:
	return {
		"removed": false,
	}


func restore_floor_state(
	_state: Dictionary
) -> void:
	set_deferred("monitoring", true)


func _refresh_visual() -> void:
	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return

	sprite.texture = (
		item_data.icon
		if item_data != null
		else null
	)


func _on_item_data_changed() -> void:
	_refresh_visual()
