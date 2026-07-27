class_name Player
extends CharacterBody2D

signal item_added(item_name: String)
signal rewards_received(
	experience_gained: int,
	gold_gained: int
)
signal leveled_up(new_level: int)

@onready var interaction_ray: RayCast2D = $InteractionRay

const GRID_SIZE: int = 32
const MOVE_DURATION: float = 0.15
const BASE_EXPERIENCE_REQUIREMENT: int = 40

var is_moving: bool = false
var inventory: Array[String] = []
var facing_direction: Vector2 = Vector2.DOWN
var experience: int = 0
var gold: int = 0
var level: int = 1
var experience_to_next_level: int = BASE_EXPERIENCE_REQUIREMENT
var max_health: int = 100
var attack_power: int = 50

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

func add_battle_rewards(
	experience_gained: int,
	gold_gained: int
) -> void:
	experience += experience_gained
	gold += gold_gained

	rewards_received.emit(
		experience_gained,
		gold_gained
	)

	print("Experience: ", experience)
	print("Gold: ", gold)
	_check_for_level_up()

func _check_for_level_up() -> void:
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1

		max_health += 10
		attack_power += 5

		experience_to_next_level = (
			BASE_EXPERIENCE_REQUIREMENT * level
		)

		leveled_up.emit(level)

		print("Level up! Level: ", level)
		print("Max health: ", max_health)
		print("Attack power: ", attack_power)