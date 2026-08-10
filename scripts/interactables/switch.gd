class_name FloorSwitch
extends Area2D

signal state_changed(
	switch_id: StringName,
	is_active: bool
)

@export_group("Identity")
@export var switch_id: StringName = &""

@export_group("State")
@export var is_active: bool = false

@export var visual_scale_multiplier: float = 1.0:
	set(value):
		visual_scale_multiplier = value
		if is_node_ready():
			_update_visual()

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


func get_persistent_id() -> String:
	if not switch_id.is_empty():
		return switch_id
	return IdGenerator.generate_instance_id(self)


func _ready() -> void:
	_update_visual()


func interact(_player: Node) -> void:
	set_active(not is_active)


func set_active(active: bool) -> void:
	if is_active == active:
		return

	is_active = active
	_update_visual()
	state_changed.emit(switch_id, is_active)


func _update_visual() -> void:
	if is_active:
		animated_sprite.play(&"active")
	else:
		animated_sprite.play(&"inactive")
		
	VisualUtils.auto_scale_sprite(animated_sprite, Vector2i(1, 1), visual_scale_multiplier)