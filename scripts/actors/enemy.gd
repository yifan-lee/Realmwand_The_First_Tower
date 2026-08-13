@tool
class_name Enemy
extends StaticBody2D

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal battle_requested(enemy: Enemy, player: Player)
signal stats_changed

@export_group("Identity")
@export var instance_id: StringName = &""

@export_group("Layout")
@export var grid_size: Vector2i = Vector2i(1, 1):
	set(value):
		grid_size = value
		if is_node_ready():
			_update_size()

const TILE_BASE_SIZE = Vector2(24, 24)
@export_storage var visual_scale_multiplier: float = 1.0

@export var collision_tile_size: Vector2 = TILE_BASE_SIZE:
	set(value):
		collision_tile_size = value
		if is_node_ready():
			_update_size()

@export_group("Data")
@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		_refresh_visual()


@onready var stats: EnemyStats = $EnemyStats

var is_defeated: bool = false
var _active_collision_layer: int = 0

# Proxy properties
var current_hp: float:
	get(): return stats.current_hp if stats else 0.0
	set(v): if stats: stats.set_current_hp(v)

var current_mp: float:
	get(): return stats.current_mp if stats else 0.0
	set(v): if stats: stats.set_current_mp(v)

var current_fp: float:
	get(): return stats.current_fp if stats else 0.0
	set(v): if stats: stats.set_current_fp(v)


func _ready() -> void:
	_refresh_visual()
	_update_size()

	if Engine.is_editor_hint():
		return

	_active_collision_layer = collision_layer

	if enemy_data == null:
		push_error("Enemy requires an EnemyData resource.")
		set_defeated(true)
		return

	stats.initialize(enemy_data)
	stats.stats_changed.connect(_on_stats_changed)


func interact(player: Player) -> void:
	request_battle(player)


func request_battle(player: Player) -> void:
	if is_defeated:
		return
	battle_requested.emit(self, player)
	EventBus.battle_requested.emit(self, player)


func set_defeated(defeated: bool) -> void:
	is_defeated = defeated
	visible = not is_defeated
	set_deferred("collision_layer", 0 if is_defeated else _active_collision_layer)


func _on_stats_changed() -> void:
	stats_changed.emit()
	if stats.current_hp <= 0.0:
		set_defeated(true)
	elif stats.current_hp > 0.0 and is_defeated:
		set_defeated(false)


func get_persistent_id() -> String:
	if not instance_id.is_empty():
		return instance_id
	return IdGenerator.generate_instance_id(self, enemy_data)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if enemy_data == null:
		warnings.append("Enemy requires an EnemyData resource.")
	elif enemy_data.id.is_empty():
		warnings.append("EnemyData requires a non-empty ID.")

	if enemy_data != null and enemy_data.get_world_texture() == null:
		warnings.append("EnemyData requires a world texture or portrait.")
	return warnings


func _refresh_visual() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	if enemy_data == null:
		sprite.texture = null
		return
	sprite.texture = enemy_data.get_world_texture()
	VisualUtils.auto_scale_sprite(sprite, grid_size, enemy_data.visual_scale_multiplier)


func _update_size() -> void:
	var shape_node = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return
	var rect_shape = shape_node.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		shape_node.shape = rect_shape
	var tile_size := get_collision_tile_size()
	rect_shape.size = Vector2(tile_size.x * grid_size.x, tile_size.y * grid_size.y)


func get_collision_tile_size() -> Vector2:
	return collision_tile_size

# Proxy methods
func take_damage(amount: float) -> float: return stats.take_damage(amount)
func change_hp(amount: float) -> void: stats.change_hp(amount)
func set_current_hp(value: float) -> void: stats.set_current_hp(value)
func change_mp(amount: float) -> void: stats.change_mp(amount)
func set_current_mp(value: float) -> void: stats.set_current_mp(value)
func change_fp(amount: float) -> void: stats.change_fp(amount)
func set_current_fp(value: float) -> void: stats.set_current_fp(value)

func get_max_hp() -> float: return stats.get_max_hp()
func get_max_mp() -> float: return stats.get_max_mp()
func get_max_fp() -> float: return stats.get_max_fp()
func get_fp_recovery_spd() -> float: return stats.get_fp_recovery_spd()
func get_cp() -> float: return stats.get_cp()
func get_atk() -> float: return stats.get_atk()
func get_def() -> float: return stats.get_def()
func get_spd() -> float: return stats.get_spd()
