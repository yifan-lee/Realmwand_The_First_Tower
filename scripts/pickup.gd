extends Area2D

@export var item_data: ItemData

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return

	if item_data == null:
		push_warning("Pickup 没有配置 ItemData")
		return

	player.add_item(item_data)
	queue_free()