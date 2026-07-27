class_name ExitStairs
extends Area2D

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player

	if player == null:
		return

	set_deferred("monitoring", false)
	reached.emit()