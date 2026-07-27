class_name Player
extends CharacterBody2D

signal item_added(item_name: String)

@onready var interaction_ray: RayCast2D = $InteractionRay

const GRID_SIZE: int = 32
const MOVE_DURATION: float = 0.15

var is_moving: bool = false

var inventory: Array[String] = []

var facing_direction: Vector2 = Vector2.DOWN


func _unhandled_input(event: InputEvent) -> void:
	if is_moving:
		return

	if event.is_action_pressed("interact"):
		try_interact()
		return

	var direction := Vector2.ZERO

	if event.is_action_pressed("move_up"):
		direction = Vector2.UP
	elif event.is_action_pressed("move_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed("move_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed("move_right"):
		direction = Vector2.RIGHT

	if direction != Vector2.ZERO:
		facing_direction = direction
		interaction_ray.target_position = facing_direction * GRID_SIZE
		move_one_tile(direction)

func move_one_tile(direction: Vector2) -> void:
	var motion := direction * GRID_SIZE
	if test_move(global_transform, motion):
		return
	is_moving = true

	var target_position := position + motion
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, MOVE_DURATION)

	await tween.finished
	is_moving = false

func add_item(new_item_name: String) -> void:
	inventory.append(new_item_name)
	item_added.emit(new_item_name)
	print("Inventory: ", inventory)

func try_interact() -> void:
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var target: Object = interaction_ray.get_collider()

	if target.has_method("interact"):
		target.call("interact")