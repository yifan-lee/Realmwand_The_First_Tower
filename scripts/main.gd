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

const BATTLE_SCENE: PackedScene = preload(
	"res://scenes/battle/battle.tscn"
)

var active_battle: Battle
var active_enemy: WorldEnemy


func _ready() -> void:
	player.item_added.connect(_on_player_item_added)
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
		floor_manager.record_enemy_defeated(
			active_enemy
		)
		active_enemy.queue_free()
		active_enemy = null
		if not level_up_allocation_panel.visible:
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
	level_label.text = (
		"Level: %d    AP: %d"
		% [
			player.level,
			player.unspent_attribute_points,
		]
	)

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
