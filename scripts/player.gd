class_name Player
extends CharacterBody2D

signal item_added(item_name: String)
signal rewards_received(
	experience_gained: int,
	gold_gained: int
)
signal leveled_up(new_level: int)
signal weapon_equipped(
	weapon_name: String,
	total_total_atk: int
)

@onready var interaction_ray: RayCast2D = $InteractionRay

const GRID_SIZE: int = 32
const MOVE_DURATION: float = 0.15
const BASE_EXPERIENCE_REQUIREMENT: int = 40

var is_moving: bool = false
var inventory: Array[ItemData] = []
var facing_direction: Vector2 = Vector2.DOWN
var experience: int = 0
var gold: int = 0
var level: int = 1
var experience_to_next_level: int = BASE_EXPERIENCE_REQUIREMENT
var max_hp: float = 200.0
var current_hp: float = 200.0
var max_mp: float = 100.0
var current_mp: float = 100.0
var base_atk: float = 20.0
var base_def: float = 20.0
var base_spd: float = 20.0
var equipment_atk_bonus: float = 0.0
var equipment_def_bonus: float = 0.0
var equipment_spd_bonus: float = 0.0
var equipped_weapon_name: String = ""

var total_atk: float:
	get:
		return base_atk

var total_def: float:
	get:
		return base_def

var total_spd: float:
	get:
		return base_spd

@export var learned_skills: Array[SkillData] = []

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

func add_item(
	new_item: ItemData
) -> void:
	inventory.append(new_item)
	item_added.emit(new_item.display_name)
	if new_item.item_type == ItemData.ItemType.WEAPON:
		equip_weapon(
			new_item.display_name,
			new_item.attack_bonus
		)
	print("Added item: ", new_item.display_name)
	print("Inventory size: ", inventory.size())

func equip_weapon(
	weapon_name: String,
	attack_bonus: int
) -> void:
	equipped_weapon_name = weapon_name
	equipment_atk_bonus = attack_bonus

	weapon_equipped.emit(
		weapon_name,
		total_atk
	)

	print("Equipped: ", equipped_weapon_name)
	print("Attack power: ", total_atk)

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

		max_hp += 10
		current_hp += 10
		base_atk += 5

		experience_to_next_level = (
			BASE_EXPERIENCE_REQUIREMENT * level
		)

		leveled_up.emit(level)

		print("Level up! Level: ", level)
		print("Max health: ", max_hp)
		print("Attack power: ", total_atk)

func find_item(item_id: StringName) -> ItemData:
	for item in inventory:
		if item.id == item_id:
			return item

	return null

func has_item(item_id: StringName) -> bool:
	return find_item(item_id) != null

func consume_item(item_id: StringName) -> ItemData:
	for item_index in range(inventory.size()):
		var item := inventory[item_index]
		if item.id == item_id:
			inventory.remove_at(item_index)
			print("Consumed: ", item.display_name)
			print("Inventory size: ", inventory.size())
			return item
	return null

func take_damage(damage: int) -> void:
	current_hp = max(
		current_hp - damage,
		0
	)


func heal(amount: int) -> void:
	current_hp = min(
		current_hp + amount,
		max_hp
	)


func restore_full_health() -> void:
	current_hp = max_hp
