extends Area2D

@export var item_name: String = "Unknown Item"
@export var attack_bonus: int = 0

func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	player.add_item(item_name, attack_bonus)
	queue_free()