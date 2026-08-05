@tool
class_name Stair
extends Area2D

enum Direction {
	UP,
	DOWN,
}

@export_group("Appearance")
@export var direction: Direction = Direction.UP:
	set(value):
		direction = value
		_update_visual()

@export_group("Destination")
@export var target_floor_id: StringName = &""
@export var target_spawn_id: StringName = &""

var transition_requested: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	var player := body as Player

	if player == null:
		return

	if transition_requested:
		return

	if not player.is_moving:
		return

	if target_floor_id == &"":
		push_error("Stair requires a target floor ID.")
		return

	if target_spawn_id == &"":
		push_error("Stair requires a target spawn ID.")
		return

	transition_requested = true

	if player.is_moving:
		await player.movement_finished

	if not is_instance_valid(player):
		transition_requested = false
		return

	EventBus.floor_change_requested.emit(
		target_floor_id,
		target_spawn_id
	)

	transition_requested = false


func _update_visual() -> void:
	var animated_sprite := get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if animated_sprite == null:
		return

	if direction == Direction.UP:
		animated_sprite.animation = &"up"
	else:
		animated_sprite.animation = &"down"

	animated_sprite.frame = 0