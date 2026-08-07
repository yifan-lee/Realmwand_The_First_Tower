@tool
class_name Enemy
extends StaticBody2D

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal battle_requested(
	enemy: Enemy,
	player: Player
)
signal stats_changed

@export_group("Identity")
@export var instance_id: StringName = &""

@export_group("Data")
@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		_refresh_visual()


var current_hp: float = 0.0
var current_mp: float = 0.0
var current_fp: float = 0.0
var is_defeated: bool = false

var _active_collision_layer: int = 0


func _ready() -> void:
	_refresh_visual()

	if Engine.is_editor_hint():
		return

	_active_collision_layer = collision_layer

	if enemy_data == null:
		push_error(
			"Enemy requires an EnemyData resource."
		)
		set_defeated(true)
		return

	current_hp = get_max_hp()
	current_mp = get_max_mp()
	current_fp = clampf(
		enemy_data.start_fp,
		0.0,
		get_max_fp()
	)


func interact(player: Player) -> void:
	request_battle(player)


func request_battle(player: Player) -> void:
	if is_defeated:
		return

	battle_requested.emit(self, player)
	EventBus.battle_requested.emit(self, player)


func take_damage(amount: float) -> float:
	if is_defeated or amount <= 0.0:
		return 0.0

	var applied_damage: float = minf(
		amount,
		current_hp
	)

	current_hp -= applied_damage
	stats_changed.emit()

	if current_hp <= 0.0:
		current_hp = 0.0
		set_defeated(true)

	return applied_damage


func change_hp(amount: float) -> void:
	if enemy_data == null:
		return
		
	set_current_hp(current_hp + amount)


func set_current_hp(value: float) -> void:
	if enemy_data == null:
		return
		
	var next_hp := clampf(
		value,
		0.0,
		get_max_hp()
	)
	if is_equal_approx(current_hp, next_hp):
		return
		
	current_hp = next_hp
	stats_changed.emit()
	
	if current_hp <= 0.0:
		set_defeated(true)
	elif current_hp > 0.0 and is_defeated:
		set_defeated(false)


func change_mp(amount: float) -> void:
	if enemy_data == null:
		return

	set_current_mp(current_mp + amount)


func set_current_mp(value: float) -> void:
	if enemy_data == null:
		return

	var next_mp := clampf(
		value,
		0.0,
		get_max_mp()
	)
	if is_equal_approx(current_mp, next_mp):
		return

	current_mp = next_mp
	stats_changed.emit()


func change_fp(amount: float) -> void:
	if enemy_data == null:
		return

	set_current_fp(current_fp + amount)


func set_current_fp(value: float) -> void:
	if enemy_data == null:
		return

	var next_fp := clampf(
		value,
		0.0,
		get_max_fp()
	)
	if is_equal_approx(current_fp, next_fp):
		return

	current_fp = next_fp
	stats_changed.emit()


func set_defeated(defeated: bool) -> void:
	is_defeated = defeated
	visible = not is_defeated

	set_deferred(
		"collision_layer",
		0 if is_defeated
		else _active_collision_layer
	)


func get_max_hp() -> float:
	return FORMULAS.resolve_base_max_hp(enemy_data.max_hp, enemy_data.def, enemy_data.spd)


func get_max_mp() -> float:
	return FORMULAS.resolve_base_max_mp(enemy_data.max_mp, enemy_data.atk, enemy_data.spd)


func get_max_fp() -> float:
	return enemy_data.max_fp


func get_fp_recovery_spd() -> float:
	return FORMULAS.resolve_base_fp_recovery(enemy_data.fp_recovery_spd, enemy_data.atk, enemy_data.def)


func get_cp() -> float:
	return FORMULAS.calculate_cp(enemy_data.atk, enemy_data.def, enemy_data.spd)


func get_persistent_id() -> String:
	if not instance_id.is_empty():
		return instance_id
	return IdGenerator.generate_instance_id(self, enemy_data)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if enemy_data == null:
		warnings.append(
			"Enemy requires an EnemyData resource."
		)
	elif enemy_data.id.is_empty():
		warnings.append(
			"EnemyData requires a non-empty ID."
		)


	if (
		enemy_data != null
		and enemy_data.get_world_texture() == null
	):
		warnings.append(
			"EnemyData requires a world texture or portrait."
		)

	return warnings


func _refresh_visual() -> void:
	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return

	if enemy_data == null:
		sprite.texture = null
		return

	sprite.texture = enemy_data.get_world_texture()
