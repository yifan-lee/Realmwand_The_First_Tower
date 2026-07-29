class_name FloorOne
extends Floor

@onready var floor_switch: TowerSwitch = $Switch
@onready var door: Door = $Door

var current_sequence_index: int = 0
var puzzle_solved: bool = false


func _ready() -> void:
	super()

	floor_switch.state_changed.connect(
		_on_switch_state_changed
	)
	_sync_door_with_switch()

func _on_switch_state_changed(
	_switch_id: int,
	is_active: bool
) -> void:
	door.set_open(is_active)

func _sync_door_with_switch() -> void:
	door.set_open(floor_switch.is_active)

func restore_runtime_state(state: Dictionary) -> void:
	super(state)
	_sync_door_with_switch()
