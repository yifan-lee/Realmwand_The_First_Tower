class_name TowerSwitch
extends Area2D


signal state_changed(switch_id: int, is_active: bool)

@export var switch_id: int = 0
@export var persistent_id: StringName

@onready var sprite: Sprite2D = $Sprite2D

var is_active: bool = false
var is_locked: bool = false


func interact() -> void:
	if is_locked:
		return

	set_active(not is_active)
	state_changed.emit(switch_id, is_active)

func set_active(value: bool) -> void:
	is_active = value

	if is_active:
		sprite.modulate = Color("#00FF00FF")
	else:
		sprite.modulate = Color("#FF00FFFF")

func reset_switch() -> void:
	is_locked = false
	set_active(false)

func lock() -> void:
	is_locked = true


func get_floor_state_id() -> StringName:
	if persistent_id != &"":
		return persistent_id

	return StringName(name)


func save_floor_state() -> Dictionary:
	return {
		"removed": false,
		"is_active": is_active,
		"is_locked": is_locked,
	}


func restore_floor_state(
	state: Dictionary
) -> void:
	is_locked = bool(
		state.get("is_locked", false)
	)
	set_active(
		bool(state.get("is_active", false))
	)
