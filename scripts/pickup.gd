extends Area2D


signal collected(persistent_id: StringName)

@export var item_data: ItemData
@export var persistent_id: StringName


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
