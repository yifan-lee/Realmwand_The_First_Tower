class_name WorldEnemy
extends Area2D

signal battle_requested(enemy: WorldEnemy)

var encounter_started: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if encounter_started:
		return

	var player := body as Player

	if player == null:
		return

	encounter_started = true
	set_deferred("monitoring", false)
	battle_requested.emit(self)