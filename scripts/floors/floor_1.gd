class_name FloorOne
extends Floor


const CORRECT_SEQUENCE: Array[int] = [2, 1, 3]

var current_sequence_index: int = 0
var puzzle_solved: bool = false


func _ready() -> void:
	super()
	_restore_puzzle_runtime_state()

	for tower_switch: TowerSwitch in _get_tower_switches():
		tower_switch.state_changed.connect(
			_on_switch_state_changed
		)


func capture_runtime_state() -> Dictionary:
	var state := super()
	state[&"floor_puzzle"] = {
		"current_sequence_index": current_sequence_index,
		"puzzle_solved": puzzle_solved,
	}
	return state


func restore_runtime_state(state: Dictionary) -> void:
	super(state)
	_restore_puzzle_runtime_state()


func _on_switch_state_changed(
	switch_id: int,
	is_active: bool
) -> void:
	if puzzle_solved:
		return

	var expected_switch_id := (
		CORRECT_SEQUENCE[current_sequence_index]
	)

	if not is_active or switch_id != expected_switch_id:
		_reset_switch_puzzle()
		return

	current_sequence_index += 1

	if (
		current_sequence_index
		== CORRECT_SEQUENCE.size()
	):
		_complete_switch_puzzle()


func _reset_switch_puzzle() -> void:
	current_sequence_index = 0

	for tower_switch: TowerSwitch in _get_tower_switches():
		tower_switch.reset_switch()

	var door := _get_door()
	if door != null:
		door.set_open(false)


func _complete_switch_puzzle() -> void:
	puzzle_solved = true

	var door := _get_door()
	if door != null:
		door.set_open(true)

	for tower_switch: TowerSwitch in _get_tower_switches():
		tower_switch.lock()


func _restore_puzzle_runtime_state() -> void:
	var puzzle_state: Dictionary = runtime_state.get(
		&"floor_puzzle",
		{}
	)
	current_sequence_index = int(
		puzzle_state.get(
			"current_sequence_index",
			current_sequence_index
		)
	)
	puzzle_solved = bool(
		puzzle_state.get(
			"puzzle_solved",
			puzzle_solved
		)
	)

	if not puzzle_solved:
		return

	var door := _get_door()
	if door != null:
		door.set_open(true)

	for tower_switch: TowerSwitch in _get_tower_switches():
		tower_switch.lock()


func _get_tower_switches() -> Array[TowerSwitch]:
	var switches: Array[TowerSwitch] = []

	for node: Node in find_children(
		"*",
		"TowerSwitch",
		true,
		false
	):
		var tower_switch := node as TowerSwitch
		if tower_switch != null:
			switches.append(tower_switch)

	return switches


func _get_door() -> Door:
	for node: Node in find_children(
		"*",
		"Door",
		true,
		false
	):
		var door := node as Door
		if door != null:
			return door

	return null
