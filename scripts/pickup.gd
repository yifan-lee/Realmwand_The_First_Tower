extends Area2D

@export var item_name: String = "Unknown Item"


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	player.add_item(item_name)
	queue_free()