class_name Door
extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_open: bool = false


func set_open(value: bool) -> void:
	is_open = value
	sprite.visible = not is_open
	collision_shape.set_deferred("disabled", is_open)

	print("Door open: ", is_open)