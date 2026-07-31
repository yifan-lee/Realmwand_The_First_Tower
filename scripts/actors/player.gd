class_name Player
extends CharacterBody2D

signal movement_finished

@export var player_data: PlayerData

@export_group("Movement")
@export_range(1.0, 256.0, 1.0) var grid_size: float = 32.0
@export_range(0.01, 1.0, 0.01) var move_duration: float = 0.16

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay

var level: int = 1
var experience: int = 0
var gold: int = 0

var base_max_hp: float = 0.0
var base_max_mp: float = 0.0
var base_atk: float = 0.0
var base_def: float = 0.0
var base_spd: float = 0.0

var current_hp: float = 0.0
var current_mp: float = 0.0

var inventory: Array[ItemData] = []
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

	inventory = player_data.starting_items.duplicate()
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