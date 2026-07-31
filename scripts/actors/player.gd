class_name Player
extends CharacterBody2D

signal movement_finished
signal stats_changed
signal level_up_available

@export var player_data: PlayerData

@export_group("Movement")
@export_range(1.0, 256.0, 1.0) var grid_size: float = 32.0
@export_range(0.01, 1.0, 0.01) var move_duration: float = 0.16

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentLoadout = $Equipment

var level: int = 1
var experience: int = 0
var gold: int = 0
var unspent_stat_points: int = 0

var base_max_hp: float = 0.0
var base_max_mp: float = 0.0
var base_atk: float = 0.0
var base_def: float = 0.0
var base_spd: float = 0.0

var current_hp: float = 0.0
var current_mp: float = 0.0


var learned_skills: Array[SkillData] = []

var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var input_enabled: bool = true


func _ready() -> void:
	if player_data == null:
		push_error("Player requires a PlayerData resource.")
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	_initialize_runtime_state()
	_apply_data_visuals()
	_update_interaction_ray()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or is_moving:
		return

	if event.is_action_pressed(&"interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
		return

	var direction := Vector2.ZERO

	if event.is_action_pressed(&"move_up"):
		direction = Vector2.UP
	elif event.is_action_pressed(&"move_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed(&"move_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed(&"move_right"):
		direction = Vector2.RIGHT

	if direction == Vector2.ZERO:
		return

	_set_facing_direction(direction)
	_move_one_tile(direction)
	get_viewport().set_input_as_handled()


func _initialize_runtime_state() -> void:
	level = player_data.starting_level
	experience = player_data.starting_experience
	gold = player_data.starting_gold

	base_max_hp = player_data.max_hp
	base_max_mp = player_data.max_mp
	base_atk = player_data.atk
	base_def = player_data.def
	base_spd = player_data.spd

	current_hp = base_max_hp
	current_mp = base_max_mp

	for starting_item: ItemData in player_data.starting_items:
		var remaining_amount := inventory.add_item(starting_item)

		if remaining_amount > 0:
			push_warning(
				"Could not add starting item '%s'."
				% starting_item.id
			)

	learned_skills = player_data.starting_skills.duplicate()


func _apply_data_visuals() -> void:
	if player_data.sprite_frames != null:
		animated_sprite.sprite_frames = player_data.sprite_frames

	_play_directional_animation(&"idle")


func _set_facing_direction(direction: Vector2) -> void:
	facing_direction = direction
	_update_interaction_ray()


func _update_interaction_ray() -> void:
	interaction_ray.target_position = (
		facing_direction * grid_size
	)


func _move_one_tile(direction: Vector2) -> void:
	var motion := direction * grid_size

	if test_move(global_transform, motion):
		_play_directional_animation(&"idle")
		return

	is_moving = true
	_play_directional_animation(&"walk")

	var target_position := global_position + motion
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		self,
		"global_position",
		target_position,
		move_duration
	)

	await tween.finished

	global_position = target_position
	is_moving = false
	_play_directional_animation(&"idle")
	movement_finished.emit()


func _play_directional_animation(
	action: StringName
) -> void:
	if animated_sprite.sprite_frames == null:
		return

	var animation_name := StringName(
		"%s_%s"
		% [
			action,
			_get_direction_suffix(),
		]
	)

	if animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		animated_sprite.play(animation_name)


func _get_direction_suffix() -> StringName:
	if facing_direction == Vector2.UP:
		return &"up"

	if facing_direction == Vector2.DOWN:
		return &"down"

	if facing_direction == Vector2.LEFT:
		return &"left"

	return &"right"


func _try_interact() -> void:
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var target: Object = interaction_ray.get_collider()

	if target == null:
		return

	if target.has_method(&"interact"):
		target.call(&"interact", self)


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled

	if not input_enabled and not is_moving:
		_play_directional_animation(&"idle")

func set_current_hp(value: float) -> void:
	var next_hp: float = clampf(
		value,
		0.0,
		get_max_hp()
	)

	if is_equal_approx(current_hp, next_hp):
		return

	current_hp = next_hp
	stats_changed.emit()


func change_hp(amount: float) -> void:
	set_current_hp(current_hp + amount)


func set_current_mp(value: float) -> void:
	var next_mp: float = clampf(
		value,
		0.0,
		get_max_mp()
	)

	if is_equal_approx(current_mp, next_mp):
		return

	current_mp = next_mp
	stats_changed.emit()


func change_mp(amount: float) -> void:
	set_current_mp(current_mp + amount)


func get_experience_for_next_level() -> int:
	return level * 100


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	var leveled_up := false

	while experience >= get_experience_for_next_level():
		experience -= get_experience_for_next_level()
		level += 1
		unspent_stat_points += 5
		leveled_up = true

	stats_changed.emit()

	if leveled_up:
		level_up_available.emit()


func spend_stat_point(stat_id: StringName) -> bool:
	if unspent_stat_points <= 0:
		return false

	match stat_id:
		&"max_hp":
			base_max_hp += 10.0
			current_hp += 10.0
		&"max_mp":
			base_max_mp += 5.0
			current_mp += 5.0
		&"atk":
			base_atk += 1.0
		&"def":
			base_def += 1.0
		&"spd":
			base_spd += 1.0
		_:
			return false

	unspent_stat_points -= 1
	stats_changed.emit()
	return true

func equip_item(
	item_id: StringName,
	target_slot: int
) -> bool:
	var item := inventory.get_item(
		item_id
	) as EquipmentData

	if item == null:
		return false

	if not equipment.can_equip(
		item,
		target_slot
	):
		return false

	var displaced_items: Array[EquipmentData] = (
		equipment.get_displaced_items(
			item,
			target_slot
		)
	)

	for displaced_item: EquipmentData in displaced_items:
		var available_capacity: int = (
			inventory.get_remaining_capacity(
				displaced_item
			)
		)

		if displaced_item.id == item.id:
			available_capacity += 1

		if available_capacity < 1:
			return false

	if not inventory.remove_item(item_id):
		return false

	var actual_displaced_items: Array[EquipmentData] = (
		equipment.equip(
			item,
			target_slot
		)
	)

	for displaced_item: EquipmentData in (
		actual_displaced_items
	):
		var remaining_amount: int = (
			inventory.add_item(displaced_item)
		)

		if remaining_amount > 0:
			push_error(
				"Could not return displaced equipment '%s'."
				% displaced_item.id
			)
			return false

	return true


func unequip_item(target_slot: int) -> bool:
	var item := equipment.get_equipped(
		target_slot
	)

	if item == null:
		return false

	var remaining_amount: int = (
		inventory.add_item(item)
	)

	if remaining_amount > 0:
		return false

	equipment.unequip(target_slot)

	return true


func get_max_hp() -> float:
	return (
		base_max_hp
		+ equipment.get_max_hp_bonus()
	)


func get_max_mp() -> float:
	return (
		base_max_mp
		+ equipment.get_max_mp_bonus()
	)


func get_atk() -> float:
	return (
		base_atk
		+ equipment.get_atk_bonus()
	)


func get_def() -> float:
	return (
		base_def
		+ equipment.get_def_bonus()
	)


func get_spd() -> float:
	return (
		base_spd
		+ equipment.get_spd_bonus()
	)


func _on_equipment_changed() -> void:
	current_hp = minf(
		current_hp,
		get_max_hp()
	)
	current_mp = minf(
		current_mp,
		get_max_mp()
	)

	stats_changed.emit()
