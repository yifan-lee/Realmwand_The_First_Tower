@tool
class_name Enemy
extends StaticBody2D

signal battle_requested(
	enemy: Enemy,
	player: Player
)

@export_group("Identity")
@export var instance_id: StringName = &""

@export_group("Data")
@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		_refresh_visual()


var current_hp: float = 0.0
var current_mp: float = 0.0
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

	current_hp = enemy_data.max_hp
	current_mp = enemy_data.max_mp


func interact(player: Player) -> void:
	if is_defeated:
		return

	battle_requested.emit(self, player)


func take_damage(amount: float) -> float:
	if is_defeated or amount <= 0.0:
		return 0.0

	var applied_damage: float = minf(
		amount,
		current_hp
	)

	current_hp -= applied_damage

	if current_hp <= 0.0:
		current_hp = 0.0
		set_defeated(true)

	return applied_damage


func set_defeated(defeated: bool) -> void:
	is_defeated = defeated
	visible = not is_defeated

	set_deferred(
		"collision_layer",
		0 if is_defeated
		else _active_collision_layer
	)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if instance_id.is_empty():
		warnings.append(
			"Enemy requires a unique floor instance ID."
		)

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
		and enemy_data.world_texture == null
	):
		warnings.append(
			"EnemyData requires a world texture."
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

	sprite.texture = enemy_data.world_texture