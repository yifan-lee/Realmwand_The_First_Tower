class_name WorldEnemy
extends Area2D

@export var enemy_data: EnemyData
@export var persistent_id: StringName

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

	if enemy_data == null:
		push_warning("WorldEnemy 没有配置 EnemyData")
		return
		
	encounter_started = true
	set_deferred("monitoring", false)
	battle_requested.emit(self)


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
	encounter_started = false
	set_deferred("monitoring", true)
