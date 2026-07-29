class_name Door
extends StaticBody2D

@export var persistent_id: StringName

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_open: bool = false


func set_open(value: bool) -> void:
	is_open = value
	sprite.visible = not is_open
	collision_shape.set_deferred("disabled", is_open)

	print("Door open: ", is_open)


func get_floor_state_id() -> StringName:
	if persistent_id != &"":
		return persistent_id

	return StringName(name)


func save_floor_state() -> Dictionary:
	return {
		"removed": false,
		"is_open": is_open,
	}


func restore_floor_state(
	state: Dictionary
) -> void:
	set_open(
		bool(state.get("is_open", false))
	)
