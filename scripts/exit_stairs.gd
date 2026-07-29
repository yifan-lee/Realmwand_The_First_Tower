class_name FloorTransition
extends Area2D


signal transition_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
)

@export var target_floor_id: StringName
@export var target_spawn_id: StringName
@export_range(0.0, 256.0, 1.0)
var arrival_suppression_radius: float = 16.0

var is_armed: bool = true
var suppressed_body: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func arm() -> void:
	is_armed = true
	suppressed_body = null


func disarm() -> void:
	is_armed = false
	suppressed_body = null


func suppress_until_body_exits(
	body: Node2D
) -> void:
	is_armed = false
	suppressed_body = body


func should_suppress_at_arrival(
	body: Node2D
) -> bool:
	if body in get_overlapping_bodies():
		return true

	return (
		global_position.distance_to(
			body.global_position
		)
		<= arrival_suppression_radius
	)


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player

	if player == null or not is_armed:
		return

	is_armed = false
	transition_requested.emit(
		target_floor_id,
		target_spawn_id
	)


func _on_body_exited(body: Node2D) -> void:
	if body != suppressed_body:
		return

	arm()
