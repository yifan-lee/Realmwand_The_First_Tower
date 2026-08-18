class_name PlayerMovement
extends Node

signal movement_finished

var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var input_enabled: bool = true

var _player: Player
var _animated_sprite: AnimatedSprite2D
var _interaction_ray: RayCast2D
var _grid_size: float
var _move_duration: float
var _held_directions: Array[Vector2] = []


func initialize(
	player: Player, 
	sprite: AnimatedSprite2D, 
	ray: RayCast2D, 
	grid_size: float, 
	move_duration: float
) -> void:
	_player = player
	_animated_sprite = sprite
	_interaction_ray = ray
	_grid_size = grid_size
	_move_duration = move_duration
	
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not _player.visible or is_movement_locked() or is_moving:
		return
		
	var movement_direction := _get_movement_event_direction(event)
	if movement_direction != Vector2.ZERO:
		_handle_movement_input(event, movement_direction)
		return

	if event.is_action_pressed(&"interact"):
		_try_interact()
		get_viewport().set_input_as_handled()


func _get_movement_event_direction(event: InputEvent) -> Vector2:
	if event.is_action(&"move_up"): return Vector2.UP
	if event.is_action(&"move_down"): return Vector2.DOWN
	if event.is_action(&"move_left"): return Vector2.LEFT
	if event.is_action(&"move_right"): return Vector2.RIGHT
	return Vector2.ZERO


func _handle_movement_input(event: InputEvent, direction: Vector2) -> void:
	if event.is_pressed():
		if event is InputEventKey and (event as InputEventKey).echo:
			return
		if not input_enabled:
			return
			
		_remember_held_direction(direction)
		_set_facing_direction(direction)
		
		if not is_moving:
			_move_one_tile(direction)
			
		get_viewport().set_input_as_handled()
		return

	_forget_held_direction(direction)
	get_viewport().set_input_as_handled()


func _remember_held_direction(direction: Vector2) -> void:
	_held_directions.erase(direction)
	_held_directions.append(direction)


func _forget_held_direction(direction: Vector2) -> void:
	_held_directions.erase(direction)


func _get_latest_held_direction() -> Vector2:
	if _held_directions.is_empty():
		return Vector2.ZERO
	return _held_directions.back()


func _set_facing_direction(direction: Vector2) -> void:
	facing_direction = direction
	_update_interaction_ray()


func _update_interaction_ray() -> void:
	_interaction_ray.target_position = facing_direction * _grid_size


func _move_one_tile(direction: Vector2) -> void:
	var motion := direction * _grid_size
	_interaction_ray.force_raycast_update()
	
	if _interaction_ray.is_colliding():
		var collider: Object = _interaction_ray.get_collider()
		if collider is Enemy:
			(collider as Enemy).request_battle(_player)
			play_directional_animation(&"idle")
			return
		elif collider.has_method(&"begin_interaction") and collider.has_method(&"interact"):
			collider.call(&"interact", _player)
			play_directional_animation(&"idle")
			return

	if _player.test_move(_player.global_transform, motion):
		play_directional_animation(&"idle")
		return

	is_moving = true
	play_directional_animation(&"walk")

	var target_position := _player.global_position + motion
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_player, "global_position", target_position, _move_duration)

	await tween.finished

	_player.global_position = target_position
	is_moving = false
	movement_finished.emit()

	var next_direction := _get_latest_held_direction()
	if input_enabled and next_direction != Vector2.ZERO:
		_set_facing_direction(next_direction)
		_move_one_tile(next_direction)
	else:
		play_directional_animation(&"idle")


func play_directional_animation(action: StringName) -> void:
	if _animated_sprite.sprite_frames == null:
		return

	var animation_name := StringName("%s_%s" % [action, _get_direction_suffix()])

	if _animated_sprite.sprite_frames.has_animation(animation_name):
		_animated_sprite.play(animation_name)


func _get_direction_suffix() -> StringName:
	if facing_direction == Vector2.UP: return &"up"
	if facing_direction == Vector2.DOWN: return &"down"
	if facing_direction == Vector2.LEFT: return &"left"
	return &"right"


func _try_interact() -> void:
	_interaction_ray.force_raycast_update()

	if not _interaction_ray.is_colliding():
		return

	var target: Object = _interaction_ray.get_collider()
	if target == null:
		return

	if target.has_method(&"interact"):
		target.call(&"interact", _player)


var _movement_locks: Dictionary[StringName, bool] = {}


func lock_movement(lock_id: StringName) -> void:
	_movement_locks[lock_id] = true
	_held_directions.clear()
	if not is_moving:
		play_directional_animation(&"idle")


func unlock_movement(lock_id: StringName) -> void:
	_movement_locks.erase(lock_id)


func is_movement_locked() -> bool:
	return not _movement_locks.is_empty() or not input_enabled


func clear_all_movement_locks() -> void:
	_movement_locks.clear()
	_held_directions.clear()


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not input_enabled:
		_held_directions.clear()
		if not is_moving:
			play_directional_animation(&"idle")
