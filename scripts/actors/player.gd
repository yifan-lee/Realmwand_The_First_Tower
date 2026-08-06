class_name Player
extends CharacterBody2D

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal movement_finished
signal stats_changed
signal level_up_available

@export var player_data: PlayerData

@export_group("Movement")
@export_range(1.0, 256.0, 1.0) var grid_size: float = 32.0
@export_range(0.01, 1.0, 0.01) var move_duration: float = 0.25

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
var base_max_fp: float = 0.0
var base_start_fp: float = 0.0
var base_fp_recovery_spd: float = 0.0
var base_atk: float = 0.0
var base_def: float = 0.0
var base_spd: float = 0.0

var current_hp: float = 0.0
var current_mp: float = 0.0
var current_fp: float = 0.0


var learned_skills: Array[SkillData] = []
var pending_learned_skills: Array[SkillData] = []

var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var input_enabled: bool = true
var _held_directions: Array[Vector2] = []


func _ready() -> void:
	if player_data == null:
		push_error("Player requires a PlayerData resource.")
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	equipment.equipment_changed.connect(_on_equipment_changed)
	_initialize_runtime_state()
	_apply_data_visuals()
	_update_interaction_ray()


func get_ui_portrait() -> Texture2D:
	if player_data != null and player_data.portrait != null:
		return player_data.portrait
	if animated_sprite == null or animated_sprite.sprite_frames == null:
		return null
	return animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation,
		animated_sprite.frame
	)


func capture_save_data() -> Dictionary:
	var skill_paths: Array[String] = []
	for skill: SkillData in learned_skills:
		if not skill.resource_path.is_empty():
			skill_paths.append(skill.resource_path)
	return {
		"level": level,
		"experience": experience,
		"gold": gold,
		"unspent_stat_points": unspent_stat_points,
		"base_max_hp": base_max_hp,
		"base_max_mp": base_max_mp,
		"base_max_fp": base_max_fp,
		"base_start_fp": base_start_fp,
		"base_fp_recovery_spd": base_fp_recovery_spd,
		"base_atk": base_atk,
		"base_def": base_def,
		"base_spd": base_spd,
		"current_hp": current_hp,
		"current_mp": current_mp,
		"current_fp": current_fp,
		"facing_direction": [facing_direction.x, facing_direction.y],
		"learned_skills": skill_paths,
		"inventory": inventory.capture_save_data(),
		"equipment": equipment.capture_save_data(),
	}


func restore_save_data(data: Dictionary) -> void:
	level = maxi(1, int(data.get("level", level)))
	experience = maxi(0, int(data.get("experience", experience)))
	gold = maxi(0, int(data.get("gold", gold)))
	unspent_stat_points = maxi(0, int(data.get("unspent_stat_points", unspent_stat_points)))
	base_max_hp = float(data.get("base_max_hp", base_max_hp))
	base_max_mp = float(data.get("base_max_mp", base_max_mp))
	base_max_fp = float(data.get("base_max_fp", base_max_fp))
	base_start_fp = float(data.get("base_start_fp", base_start_fp))
	base_fp_recovery_spd = float(data.get("base_fp_recovery_spd", base_fp_recovery_spd))
	base_atk = float(data.get("base_atk", base_atk))
	base_def = float(data.get("base_def", base_def))
	base_spd = float(data.get("base_spd", base_spd))
	inventory.restore_save_data(data.get("inventory", []))
	equipment.restore_save_data(data.get("equipment", []))
	learned_skills.clear()
	var skills_value: Variant = data.get("learned_skills", [])
	if skills_value is Array:
		for path_value: Variant in skills_value:
			var skill := load(String(path_value)) as SkillData
			if skill != null:
				learned_skills.append(skill)
	current_hp = clampf(float(data.get("current_hp", current_hp)), 0.0, get_max_hp())
	current_mp = clampf(float(data.get("current_mp", current_mp)), 0.0, get_max_mp())
	current_fp = clampf(float(data.get("current_fp", current_fp)), 0.0, get_max_fp())
	var facing_value: Variant = data.get("facing_direction", [])
	if facing_value is Array and facing_value.size() >= 2:
		facing_direction = Vector2(float(facing_value[0]), float(facing_value[1]))
	_update_interaction_ray()
	_play_directional_animation(&"idle")
	stats_changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	var movement_direction := _get_movement_event_direction(event)
	if movement_direction != Vector2.ZERO:
		_handle_movement_input(event, movement_direction)
		return

	if not input_enabled or is_moving:
		return

	if event.is_action_pressed(&"interact"):
		_try_interact()
		get_viewport().set_input_as_handled()


func _get_movement_event_direction(event: InputEvent) -> Vector2:
	if event.is_action(&"move_up"):
		return Vector2.UP
	if event.is_action(&"move_down"):
		return Vector2.DOWN
	if event.is_action(&"move_left"):
		return Vector2.LEFT
	if event.is_action(&"move_right"):
		return Vector2.RIGHT
	return Vector2.ZERO


func _handle_movement_input(
	event: InputEvent,
	direction: Vector2
) -> void:
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


func _initialize_runtime_state() -> void:
	level = player_data.starting_level
	experience = player_data.starting_experience
	gold = player_data.starting_gold

	base_max_hp = player_data.max_hp
	base_max_mp = player_data.max_mp
	base_max_fp = player_data.max_fp
	base_start_fp = player_data.start_fp
	base_fp_recovery_spd = player_data.fp_recovery_spd
	base_atk = player_data.atk
	base_def = player_data.def
	base_spd = player_data.spd

	current_hp = get_max_hp()
	current_mp = get_max_mp()
	current_fp = clampf(
		base_start_fp,
		0.0,
		get_max_fp()
	)

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
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var collider: Object = interaction_ray.get_collider()
		if collider is Enemy:
			(collider as Enemy).request_battle(self)
			_play_directional_animation(&"idle")
			return

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
	movement_finished.emit()

	var next_direction := _get_latest_held_direction()
	if input_enabled and next_direction != Vector2.ZERO:
		_set_facing_direction(next_direction)
		_move_one_tile(next_direction)
	else:
		_play_directional_animation(&"idle")


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

	if not input_enabled:
		_held_directions.clear()
		if not is_moving:
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


func set_current_fp(value: float) -> void:
	var next_fp: float = clampf(
		value,
		0.0,
		get_max_fp()
	)

	if is_equal_approx(current_fp, next_fp):
		return

	current_fp = next_fp
	stats_changed.emit()


func change_fp(amount: float) -> void:
	set_current_fp(current_fp + amount)


func get_experience_for_next_level() -> int:
	return FORMULAS.experience_for_next_level(level)


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	var leveled_up := false

	while experience >= get_experience_for_next_level():
		experience -= get_experience_for_next_level()
		level += 1
		base_atk += FORMULAS.AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL
		base_def += FORMULAS.AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL
		base_spd += FORMULAS.AUTO_PRIMARY_STAT_INCREASE_PER_LEVEL
		unspent_stat_points += FORMULAS.FREE_STAT_POINTS_PER_LEVEL
		leveled_up = true

		if player_data.level_skills.has(level):
			var new_skill: SkillData = player_data.level_skills[level]
			if not learned_skills.has(new_skill):
				learned_skills.append(new_skill)
				pending_learned_skills.append(new_skill)

	stats_changed.emit()

	if leveled_up:
		level_up_available.emit()


func spend_stat_point(stat_id: StringName) -> bool:
	if unspent_stat_points <= 0:
		return false

	match stat_id:
		&"atk":
			base_atk += FORMULAS.stat_point_increase(stat_id)
		&"def":
			base_def += FORMULAS.stat_point_increase(stat_id)
		&"spd":
			base_spd += FORMULAS.stat_point_increase(stat_id)
		_:
			return false

	unspent_stat_points -= 1
	stats_changed.emit()
	return true


func get_stat_allocation_preview(
	allocation: Dictionary[StringName, int]
) -> Dictionary[StringName, float]:
	var atk_points: int = int(allocation.get(&"atk", 0))
	var def_points: int = int(allocation.get(&"def", 0))
	var spd_points: int = int(allocation.get(&"spd", 0))
	var increase: float = FORMULAS.stat_point_increase(&"atk")
	var next_base_atk: float = base_atk + atk_points * increase
	var next_base_def: float = base_def + def_points * increase
	var next_base_spd: float = base_spd + spd_points * increase
	var next_max_hp: float = FORMULAS.resolve_base_max_hp(
		base_max_hp,
		next_base_def,
		next_base_spd
	) + equipment.get_max_hp_bonus()
	var next_max_mp: float = FORMULAS.resolve_base_max_mp(
		base_max_mp,
		next_base_atk,
		next_base_spd
	) + equipment.get_max_mp_bonus()

	var hp_increase := next_max_hp - get_max_hp()
	var mp_increase := next_max_mp - get_max_mp()
	return {
		&"current_hp": current_hp + hp_increase if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE else current_hp,
		&"max_hp": next_max_hp,
		&"current_mp": current_mp + mp_increase if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE else current_mp,
		&"max_mp": next_max_mp,
		&"fp_recovery": FORMULAS.resolve_base_fp_recovery(
			base_fp_recovery_spd,
			next_base_atk,
			next_base_def
		),
		&"atk": next_base_atk + equipment.get_atk_bonus(),
		&"def": next_base_def + equipment.get_def_bonus(),
		&"spd": next_base_spd + equipment.get_spd_bonus(),
	}


func apply_stat_allocation(
	allocation: Dictionary[StringName, int]
) -> bool:
	var total_points := 0
	for stat_id: StringName in [&"atk", &"def", &"spd"]:
		var points: int = int(allocation.get(stat_id, 0))
		if points < 0:
			return false
		total_points += points
	if total_points <= 0 or total_points > unspent_stat_points:
		return false

	var previous_max_hp: float = get_max_hp()
	var previous_max_mp: float = get_max_mp()
	var increase: float = FORMULAS.stat_point_increase(&"atk")
	base_atk += int(allocation.get(&"atk", 0)) * increase
	base_def += int(allocation.get(&"def", 0)) * increase
	base_spd += int(allocation.get(&"spd", 0)) * increase
	unspent_stat_points -= total_points
	if FORMULAS.RESTORE_CURRENT_ON_MAX_RESOURCE_INCREASE:
		current_hp = clampf(current_hp + get_max_hp() - previous_max_hp, 0.0, get_max_hp())
		current_mp = clampf(current_mp + get_max_mp() - previous_max_mp, 0.0, get_max_mp())
	else:
		current_hp = minf(current_hp, get_max_hp())
		current_mp = minf(current_mp, get_max_mp())
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
		FORMULAS.resolve_base_max_hp(
			base_max_hp,
			base_def,
			base_spd
		)
		+ equipment.get_max_hp_bonus()
	)


func get_max_mp() -> float:
	return (
		FORMULAS.resolve_base_max_mp(
			base_max_mp,
			base_atk,
			base_spd
		)
		+ equipment.get_max_mp_bonus()
	)


func get_max_fp() -> float:
	return base_max_fp


func get_start_fp() -> float:
	return base_start_fp


func get_fp_recovery_spd() -> float:
	return FORMULAS.resolve_base_fp_recovery(
		base_fp_recovery_spd,
		base_atk,
		base_def
	)


func get_stat_upgrade_preview(stat_id: StringName) -> Dictionary[StringName, float]:
	var next_atk := base_atk
	var next_def := base_def
	var next_spd := base_spd
	var increase := FORMULAS.stat_point_increase(stat_id)
	match stat_id:
		&"atk":
			next_atk += increase
		&"def":
			next_def += increase
		&"spd":
			next_spd += increase
		_:
			return {}
	return {
		&"max_hp": FORMULAS.resolve_base_max_hp(base_max_hp, next_def, next_spd) - get_max_hp(),
		&"max_mp": FORMULAS.resolve_base_max_mp(base_max_mp, next_atk, next_spd) - get_max_mp(),
		&"fp_recovery": FORMULAS.resolve_base_fp_recovery(base_fp_recovery_spd, next_atk, next_def) - get_fp_recovery_spd(),
	}


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
