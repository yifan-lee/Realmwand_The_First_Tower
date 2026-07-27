extends Node2D

@onready var player: Player = $Player
@onready var pickup_message: Label = $UI/PickupMessage
@onready var pickup_message_timer: Timer = $UI/PickupMessageTimer
@onready var tower_switches: Array[TowerSwitch] = [
	$Switch1,
	$Switch2,
	$Switch3,
]
@onready var door: Door = $Door
@onready var exit_stairs: ExitStairs = $ExitStairs

const CORRECT_SEQUENCE: Array[int] = [2, 1, 3]

var current_sequence_index: int = 0
var puzzle_solved: bool = false


func _ready() -> void:
	player.item_added.connect(_on_player_item_added)
	pickup_message_timer.timeout.connect(_on_pickup_message_timer_timeout)
	for tower_switch in tower_switches:
		tower_switch.state_changed.connect(_on_switch_state_changed)
	exit_stairs.reached.connect(_on_exit_stairs_reached)


func _on_player_item_added(item_name: String) -> void:
	pickup_message.text = "Picked up: " + item_name
	pickup_message_timer.start()


func _on_pickup_message_timer_timeout() -> void:
	pickup_message.text = ""

func _on_switch_state_changed(
	switch_id: int,
	is_active: bool
) -> void:
	if puzzle_solved:
		return

	var expected_switch_id := CORRECT_SEQUENCE[current_sequence_index]

	if not is_active or switch_id != expected_switch_id:
		_reset_switch_puzzle()
		return

	current_sequence_index += 1
	print("Correct switch: ", switch_id)

	if current_sequence_index == CORRECT_SEQUENCE.size():
		_complete_switch_puzzle()

func _reset_switch_puzzle() -> void:
	current_sequence_index = 0
	for tower_switch in tower_switches:
		tower_switch.reset_switch()

	door.set_open(false)
	print("Wrong sequence. Puzzle reset.")

func _complete_switch_puzzle() -> void:
	puzzle_solved = true
	door.set_open(true)

	for tower_switch in tower_switches:
		tower_switch.lock()

	print("Puzzle solved.")

func _on_exit_stairs_reached() -> void:
	player.set_process_unhandled_input(false)
	pickup_message_timer.stop()
	pickup_message.text = "Floor 1 Complete!"

	print("Floor 1 complete.")
