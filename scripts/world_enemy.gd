@tool
class_name WorldEnemy
extends Area2D

@export var enemy_data: EnemyData:
	set(value):
		if (
			enemy_data != null
			and enemy_data.changed.is_connected(
				_on_enemy_data_changed
			)
		):
			enemy_data.changed.disconnect(
				_on_enemy_data_changed
			)

		enemy_data = value

		if enemy_data != null:
			enemy_data.changed.connect(
				_on_enemy_data_changed
			)

		_refresh_visual()
@export var persistent_id: StringName

signal battle_requested(enemy: WorldEnemy)

var encounter_started: bool = false


func _ready() -> void:
	_refresh_visual()

	if Engine.is_editor_hint():
		return

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


func capture_encounter_state() -> Dictionary:
	return {
		"global_position": global_position,
	}


func restore_encounter_state(state: Dictionary) -> void:
	global_position = state.get(
		"global_position",
		global_position
	)
	encounter_started = false
	set_deferred("monitoring", true)


func restore_floor_state(
	_state: Dictionary
) -> void:
	encounter_started = false
	set_deferred("monitoring", true)


func _refresh_visual() -> void:
	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return

	sprite.texture = (
		enemy_data.portrait
		if enemy_data != null
		else null
	)


func _on_enemy_data_changed() -> void:
	_refresh_visual()
