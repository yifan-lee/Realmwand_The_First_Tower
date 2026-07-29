extends Node2D

@onready var player: Player = $Player
@onready var floor_manager: FloorManager = $FloorManager
@onready var pickup_message: Label = $UI/PickupMessage
@onready var pickup_message_timer: Timer = $UI/PickupMessageTimer
@onready var battle_layer: CanvasLayer = $BattleLayer
@onready var player_menu: PlayerMenu = $MenuLayer/PlayerMenu
@onready var level_up_allocation_panel: LevelUpAllocationPanel = (
	$MenuLayer/LevelUpAllocationPanel
)
@onready var player_status_panel: CombatantStatusPanel = (
	$UI/PlayerStatusPanel
)
@onready var tracked_inventory_hud: TrackedInventoryHud = (
	$UI/TrackedInventoryHud
)

const BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/battle.tscn"
)

var active_battle: Battle
var active_enemy: WorldEnemy
var player_encounter_state: Dictionary = {}
var enemy_encounter_state: Dictionary = {}


func _ready() -> void:
	player.item_added.connect(_on_player_item_added)
	player.inventory_changed.connect(_update_inventory_hud)
	pickup_message_timer.timeout.connect(_on_pickup_message_timer_timeout)
	floor_manager.battle_requested.connect(
		_on_battle_requested
	)
	floor_manager.floor_changed.connect(
		_on_floor_changed
	)
	player.rewards_received.connect(_on_rewards_received)
	player.leveled_up.connect(_on_player_leveled_up)
	player.attributes_changed.connect(_update_player_hud)
	player.skill_learned.connect(_on_player_skill_learned)
	player.equipment_changed.connect(_on_equipment_changed)
	player_menu.closed.connect(_on_player_menu_closed)
	level_up_allocation_panel.allocation_completed.connect(
		_on_level_up_allocation_completed
	)
	_update_player_hud()
	_update_inventory_hud()
	await floor_manager.initialize()


func _unhandled_input(event: InputEvent) -> void:
	if (
		not event.is_action_pressed("ui_cancel")
		or active_battle != null
		or player_menu.visible
		or level_up_allocation_panel.visible
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


func _on_floor_changed(
	floor_id: StringName,
	_spawn_id: StringName
) -> void:
	pickup_message.text = "Entered %s" % floor_id
	pickup_message_timer.start()

func _on_battle_requested(enemy: WorldEnemy) -> void:
	if active_battle != null or active_enemy != null:
		return

	active_enemy = enemy
	player_encounter_state = (
		player.capture_battle_state()
	)
	enemy_encounter_state = (
		active_enemy.capture_encounter_state()
	)
	player.set_process_unhandled_input(false)
	await player.wait_for_current_movement()
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
		floor_manager.record_enemy_defeated(
			active_enemy
		)
		active_enemy.queue_free()
		active_enemy = null
		_clear_encounter_state()
		if not level_up_allocation_panel.visible:
			player.set_process_unhandled_input(true)
	else:
		player.restore_battle_state(
			player_encounter_state
		)
		active_enemy.restore_encounter_state(
			enemy_encounter_state
		)
		active_enemy = null
		_clear_encounter_state()
		_update_player_hud()
		await get_tree().physics_frame
		player.set_process_unhandled_input(true)


func _clear_encounter_state() -> void:
	player_encounter_state.clear()
	enemy_encounter_state.clear()

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
	player.set_process_unhandled_input(false)
	pickup_message_timer.stop()
	pickup_message.text = (
		"Level Up! Level %d"
		% new_level
	)
	_update_player_hud()
	level_up_allocation_panel.open(player)


func _on_level_up_allocation_completed() -> void:
	_update_player_hud()

	if active_battle == null and not player_menu.visible:
		player.set_process_unhandled_input(true)


func _on_player_skill_learned(skill: SkillData) -> void:
	pickup_message.text = (
		"Learned skill: %s"
		% skill.display_name
	)
	pickup_message_timer.start()


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
	player_status_panel.set_data(
		CombatantStatusViewData.from_player(player)
	)


func _update_inventory_hud() -> void:
	tracked_inventory_hud.set_inventory(player.inventory)
