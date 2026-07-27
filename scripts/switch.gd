class_name TowerSwitch
extends Area2D


signal state_changed(switch_id: int, is_active: bool)

@export var switch_id: int = 0

@onready var sprite: Sprite2D = $Sprite2D

var is_active: bool = false
var is_locked: bool = false


func interact() -> void:
	if is_locked:
		return

	set_active(not is_active)
	state_changed.emit(switch_id, is_active)

func set_active(value: bool):
	is_active = value

	if is_active:
		sprite.modulate = Color.GREEN
	else:
		sprite.modulate = Color.MAGENTA

func reset_switch() -> void:
	is_locked = false
	set_active(false)

func lock() -> void:
	is_locked = true