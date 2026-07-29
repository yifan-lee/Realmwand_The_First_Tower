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
@onready var world_enemies: Array[WorldEnemy] = [
	$Slime,
	$WorldEnemy2,
]
@onready var battle_layer: CanvasLayer = $BattleLayer
@onready var player_menu: PlayerMenu = $MenuLayer/PlayerMenu
@onready var level_label: Label = (
	$UI/StatsPanel/Stat/LevelLabel
)
@onready var health_label: Label = (
	$UI/StatsPanel/Stat/HealthLabel
)
@onready var experience_label: Label = (
	$UI/StatsPanel/Stat/ExperienceLabel
)
@onready var gold_label: Label = (
	$UI/StatsPanel/Stat/GoldLabel
)

const CORRECT_SEQUENCE: Array[int] = [2, 1, 3]
const BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/battle.tscn"
)

var current_sequence_index: int = 0
var puzzle_solved: bool = false

var active_battle: Battle
var active_enemy: WorldEnemy


func _ready() -> void:
	player.item_added.connect(_on_player_item_added)
	pickup_message_timer.timeout.connect(_on_pickup_message_timer_timeout)
	for tower_switch in tower_switches:
		tower_switch.state_changed.connect(_on_switch_state_changed)
	exit_stairs.reached.connect(_on_exit_stairs_reached)
	for world_enemy in world_enemies:
		world_enemy.battle_requested.connect(_on_battle_requested)
	player.rewards_received.connect(_on_rewards_received)
	player.leveled_up.connect(_on_player_leveled_up)
	player.equipment_changed.connect(_on_equipment_changed)
	player_menu.closed.connect(_on_player_menu_closed)
	_update_player_hud()


func _unhandled_input(event: InputEvent) -> void:
	if (
		not event.is_action_pressed("ui_cancel")
		or active_battle != null
		or player_menu.visible
	):
		return

	player.set_process_unhandled_input(false)
	player_menu.open(player)
	get_viewport().set_input_as_handled()


func _on_player_menu_closed() -> void:
	if active_battle == null:
		player.set_process_unhandled_input(true)
		_update_player_hud()


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

func _on_battle_requested(enemy: WorldEnemy) -> void:
	if active_battle != null:
		return

	active_enemy = enemy
	player.set_process_unhandled_input(false)
	_start_battle()

func _start_battle() -> void:
	active_battle = BATTLE_SCENE.instantiate() as Battle
	active_battle.setup(player, active_enemy.enemy_data)
	battle_layer.add_child(active_battle)
	active_battle.battle_finished.connect(_on_battle_finished)

func _on_battle_finished(
	victory: bool,
	experience_reward: int,
	gold_reward: int
) -> void:
	active_battle.queue_free()
	active_battle = null

	if victory:
		player.add_battle_rewards(
			experience_reward,
			gold_reward
		)
		active_enemy.queue_free()
		active_enemy = null
		player.set_process_unhandled_input(true)
	else:
		player.restore_full_health()
		_update_player_hud()
		await get_tree().process_frame
		_start_battle()

func _on_rewards_received(
	experience_gained: int,
	gold_gained: int
) -> void:
	pickup_message.text = (
		"Gained %d EXP and %d Gold"
		% [experience_gained, gold_gained]
	)
	pickup_message_timer.start()
	_update_player_hud()

func _on_player_leveled_up(new_level: int) -> void:
	pickup_message.text = "Level Up! Level %d" % new_level
	pickup_message_timer.start()
	_update_player_hud()

func _on_equipment_changed(
	equipment_name: String,
	total_attack_power: float
) -> void:
	pickup_message.text = (
		"Equipment changed: %s - Attack %.0f"
		% [equipment_name, total_attack_power]
	)
	pickup_message_timer.start()
	_update_player_hud()

func _update_player_hud() -> void:
	level_label.text = "Level: %d" % player.level

	health_label.text = (
		"HP: %d / %d"
		% [
			player.current_hp,
			player.max_hp,
		]
	)

	experience_label.text = (
		"EXP: %d / %d"
		% [
			player.experience,
			player.experience_to_next_level,
		]
	)

	gold_label.text = "Gold: %d" % player.gold
