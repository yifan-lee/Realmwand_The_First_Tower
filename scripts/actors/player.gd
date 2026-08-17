class_name Player
extends CharacterBody2D

signal movement_finished
signal stats_changed
signal level_up_available
signal skill_learned(skill: SkillData)

@export var player_data: PlayerData

@export_group("Movement")
@export_range(1.0, 256.0, 1.0) var grid_size: float = 32.0
@export_range(0.01, 1.0, 0.01) var move_duration: float = 0.25

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentLoadout = $Equipment

@onready var stats: PlayerStats = $PlayerStats
@onready var progression: PlayerProgression = $PlayerProgression
@onready var movement: PlayerMovement = $PlayerMovement

# Proxy properties to preserve backward compatibility as much as possible for other systems
var current_hp: float:
	get(): return stats.current_hp if stats else 0.0
	set(v): if stats: stats.set_current_hp(v)

var current_mp: float:
	get(): return stats.current_mp if stats else 0.0
	set(v): if stats: stats.set_current_mp(v)

var current_fp: float:
	get(): return stats.current_fp if stats else 0.0
	set(v): if stats: stats.set_current_fp(v)

var level: int:
	get(): return progression.level if progression else 1
var experience: int:
	get(): return progression.experience if progression else 0
var gold: int:
	get(): return progression.gold if progression else 0
	set(v): if progression: progression.gold = v
var unspent_stat_points: int:
	get(): return progression.unspent_stat_points if progression else 0
var learned_skills: Array[SkillData]:
	get(): return progression.learned_skills if progression else []


func has_skill(skill_id: StringName) -> bool:
	return progression.has_skill(skill_id) if progression else false


func get_skill(skill_id: StringName) -> SkillData:
	return progression.get_skill(skill_id) if progression else null


func learn_skill(skill: SkillData) -> bool:
	return progression.learn_skill(skill) if progression else false


func forget_skill(skill_id: StringName) -> bool:
	return progression.forget_skill(skill_id) if progression else false


func _ready() -> void:
	if player_data == null:
		push_error("Player requires a PlayerData resource.")
		set_process(false)
		set_physics_process(false)
		return

	equipment.equipment_changed.connect(_on_equipment_changed)
	
	# Initialize components
	stats.initialize(player_data, equipment)
	progression.initialize(player_data, stats)
	movement.initialize(self, animated_sprite, interaction_ray, grid_size, move_duration)
	
	# Connect component signals to forward them
	stats.stats_changed.connect(func(): stats_changed.emit())
	progression.level_up_available.connect(func(): level_up_available.emit())
	progression.skill_learned.connect(func(skill): skill_learned.emit(skill))
	movement.movement_finished.connect(func(): movement_finished.emit())

	_apply_data_visuals()


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
	for skill: SkillData in progression.learned_skills:
		if not skill.resource_path.is_empty():
			skill_paths.append(skill.resource_path)
			
	return {
		"level": progression.level,
		"experience": progression.experience,
		"gold": progression.gold,
		"unspent_stat_points": progression.unspent_stat_points,
		"base_max_hp": stats.base_max_hp,
		"base_max_mp": stats.base_max_mp,
		"base_max_fp": stats.base_max_fp,
		"base_start_fp": stats.base_start_fp,
		"base_fp_recovery_spd": stats.base_fp_recovery_spd,
		"base_atk": stats.base_atk,
		"base_def": stats.base_def,
		"base_spd": stats.base_spd,
		"current_hp": stats.current_hp,
		"current_mp": stats.current_mp,
		"current_fp": stats.current_fp,
		"facing_direction": [movement.facing_direction.x, movement.facing_direction.y],
		"learned_skills": skill_paths,
		"inventory": inventory.capture_save_data(),
		"equipment": equipment.capture_save_data(),
	}


func restore_save_data(data: Dictionary) -> void:
	progression.level = maxi(1, int(data.get("level", progression.level)))
	progression.experience = maxi(0, int(data.get("experience", progression.experience)))
	progression.gold = maxi(0, int(data.get("gold", progression.gold)))
	progression.unspent_stat_points = maxi(0, int(data.get("unspent_stat_points", progression.unspent_stat_points)))
	
	stats.base_max_hp = float(data.get("base_max_hp", stats.base_max_hp))
	stats.base_max_mp = float(data.get("base_max_mp", stats.base_max_mp))
	stats.base_max_fp = float(data.get("base_max_fp", stats.base_max_fp))
	stats.base_start_fp = float(data.get("base_start_fp", stats.base_start_fp))
	stats.base_fp_recovery_spd = float(data.get("base_fp_recovery_spd", stats.base_fp_recovery_spd))
	stats.base_atk = float(data.get("base_atk", stats.base_atk))
	stats.base_def = float(data.get("base_def", stats.base_def))
	stats.base_spd = float(data.get("base_spd", stats.base_spd))
	
	inventory.restore_save_data(data.get("inventory", []))
	equipment.restore_save_data(data.get("equipment", []))
	
	progression.learned_skills.clear()
	var skills_value: Variant = data.get("learned_skills", [])
	if skills_value is Array:
		for path_value: Variant in skills_value:
			var skill := load(String(path_value)) as SkillData
			if skill != null:
				progression.learned_skills.append(skill)
				
	# Compat logic for new skills
	for skill: SkillData in player_data.starting_skills:
		if skill != null and not progression.learned_skills.has(skill):
			progression.learned_skills.append(skill)
	for i: int in range(1, progression.level + 1):
		if player_data.level_skills.has(i):
			var skill: SkillData = player_data.level_skills[i]
			if skill != null and not progression.learned_skills.has(skill):
				progression.learned_skills.append(skill)
				
	stats.current_hp = clampf(float(data.get("current_hp", stats.current_hp)), 0.0, stats.get_max_hp())
	stats.current_mp = clampf(float(data.get("current_mp", stats.current_mp)), 0.0, stats.get_max_mp())
	stats.current_fp = clampf(float(data.get("current_fp", stats.current_fp)), 0.0, stats.get_max_fp())
	
	var facing_value: Variant = data.get("facing_direction", [])
	if facing_value is Array and facing_value.size() >= 2:
		movement.facing_direction = Vector2(float(facing_value[0]), float(facing_value[1]))
		
	movement._update_interaction_ray()
	movement.play_directional_animation(&"idle")
	stats.stats_changed.emit()


func _apply_data_visuals() -> void:
	if player_data.sprite_frames != null:
		animated_sprite.sprite_frames = player_data.sprite_frames
	movement.play_directional_animation(&"idle")


func set_input_enabled(enabled: bool) -> void:
	movement.set_input_enabled(enabled)


# Proxy methods for backwards compatibility and ease of access
func get_max_hp() -> float: return stats.get_max_hp()
func get_max_mp() -> float: return stats.get_max_mp()
func get_max_fp() -> float: return stats.get_max_fp()
func get_start_fp() -> float: return stats.get_start_fp()
func get_fp_recovery_spd() -> float: return stats.get_fp_recovery_spd()
func get_atk() -> float: return stats.get_atk()
func get_def() -> float: return stats.get_def()
func get_spd() -> float: return stats.get_spd()

func set_current_hp(value: float) -> void: stats.set_current_hp(value)
func change_hp(amount: float) -> void: stats.change_hp(amount)
func take_damage(amount: float) -> float: return stats.take_damage(amount)
func add_shield(amount: float) -> void: stats.add_shield(amount)
func clear_shield() -> void: stats.clear_shield()
var current_shield: float:
	get(): return stats.current_shield if stats else 0.0
func set_current_mp(value: float) -> void: stats.set_current_mp(value)
func change_mp(amount: float) -> void: stats.change_mp(amount)
func set_current_fp(value: float) -> void: stats.set_current_fp(value)
func change_fp(amount: float) -> void: stats.change_fp(amount)

func get_experience_for_next_level() -> int: return progression.get_experience_for_next_level()
func add_experience(amount: int) -> void: progression.add_experience(amount)
func spend_stat_point(stat_id: StringName) -> bool: return progression.spend_stat_point(stat_id)
func get_stat_allocation_preview(alloc: Dictionary[StringName, int]) -> Dictionary[StringName, float]: return progression.get_stat_allocation_preview(alloc)
func apply_stat_allocation(alloc: Dictionary[StringName, int]) -> bool: return progression.apply_stat_allocation(alloc)
func get_permanent_stat_increase_preview(stat_id: StringName, amount: float) -> Dictionary[StringName, float]: return progression.get_permanent_stat_increase_preview(stat_id, amount)
func apply_permanent_stat_increase(stat_id: StringName, amount: float) -> bool: return progression.apply_permanent_stat_increase(stat_id, amount)
func get_stat_upgrade_preview(stat_id: StringName) -> Dictionary[StringName, float]: return progression.get_stat_upgrade_preview(stat_id)


# Equipment Logic
func equip_item(item_id: StringName, target_slot: int) -> bool:
	var item := inventory.get_item(item_id) as EquipmentData
	if item == null: return false
	if not equipment.can_equip(item, target_slot): return false

	var displaced_items: Array[EquipmentData] = equipment.get_displaced_items(item, target_slot)
	for displaced_item: EquipmentData in displaced_items:
		var available_capacity: int = inventory.get_remaining_capacity(displaced_item)
		if displaced_item.id == item.id:
			available_capacity += 1
		if available_capacity < 1:
			return false

	if not inventory.remove_item(item_id):
		return false

	var actual_displaced_items: Array[EquipmentData] = equipment.equip(item, target_slot)
	for displaced_item: EquipmentData in actual_displaced_items:
		var remaining_amount: int = inventory.add_item(displaced_item)
		if remaining_amount > 0:
			push_error("Could not return displaced equipment '%s'." % displaced_item.id)
			return false
	return true


func unequip_item(target_slot: int) -> bool:
	var item := equipment.get_equipped(target_slot)
	if item == null: return false

	var remaining_amount: int = inventory.add_item(item)
	if remaining_amount > 0:
		return false

	equipment.unequip(target_slot)
	return true


func _on_equipment_changed() -> void:
	stats.current_hp = minf(stats.current_hp, stats.get_max_hp())
	stats.current_mp = minf(stats.current_mp, stats.get_max_mp())
	stats.stats_changed.emit()
