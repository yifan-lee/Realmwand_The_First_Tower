@tool
class_name Door
extends StaticBody2D

@export var persistent_id: StringName
@export var closed_frame_coords: Vector2i:
	set(value):
		closed_frame_coords = value
		_refresh_visual()
@export var open_frame_coords: Vector2i:
	set(value):
		open_frame_coords = value
		_refresh_visual()

var is_open: bool = false


func _ready() -> void:
	_refresh_visual()


func set_open(value: bool) -> void:
	is_open = value
	_refresh_visual()

	print("Door open: ", is_open)


func _refresh_visual() -> void:
	var current_sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D
	var current_collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D

	if current_sprite != null:
		current_sprite.visible = true
		current_sprite.frame_coords = (
			open_frame_coords
			if is_open
			else closed_frame_coords
		)

	if current_collision != null:
		current_collision.set_deferred(
			"disabled",
			is_open
		)


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
