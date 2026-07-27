class_name Battle
extends Control

signal battle_finished(
	victory: bool,
	experience_reward: int,
	gold_reward: int,
)

@onready var player_atb: ProgressBar = $PlayerPanel/PlayerInfo/PlayerATB
@onready var enemy_atb: ProgressBar = $EnemyPanel/EnemyInfo/EnemyATB
@onready var attack_button: Button = $ActionPanel/Actions/AttackButton
@onready var battle_message: Label = $BattleMessage
@onready var enemy_hp: ProgressBar = $EnemyPanel/EnemyInfo/EnemyHP
@onready var player_hp: ProgressBar = $PlayerPanel/PlayerInfo/PlayerHP
@onready var item_button: Button = $ActionPanel/Actions/ItemButton
@onready var result_button: Button = $ActionPanel/Actions/ResultButton

const PLAYER_ATB_SPEED: float = 50.0
const ENEMY_ATB_SPEED: float = 40.0
const ENEMY_ATTACK_DAMAGE: float = 50.0
const EXPERIENCE_REWARD: int = 40
const GOLD_REWARD: int = 1
var player_max_health: float = 100.0
var player_attack_damage: float = 50.0

var battle_active: bool = true
var player_won: bool = false
var player_data: Player

const SMALL_POTION_HEALING: float = 50.0



func _ready() -> void:
	player_hp.max_value = player_max_health
	player_hp.value = player_max_health
	attack_button.disabled = true
	attack_button.pressed.connect(_on_attack_button_pressed)
	result_button.pressed.connect(_on_result_button_pressed)
	item_button.pressed.connect(_on_item_button_pressed)
	

func _process(delta: float) -> void:
	if not battle_active:
		return

	player_atb.value = min(
		player_atb.value + PLAYER_ATB_SPEED * delta,
		player_atb.max_value
	)

	enemy_atb.value = min(
		enemy_atb.value + ENEMY_ATB_SPEED * delta,
		enemy_atb.max_value
	)

	if player_atb.value >= player_atb.max_value:
		attack_button.disabled = false
		var has_small_potion := (
			player_data != null
			and player_data.has_item("Small Potion")
		)
		item_button.disabled = (
			not has_small_potion
			or player_hp.value >= player_hp.max_value
		)

	if enemy_atb.value >= enemy_atb.max_value:
		_enemy_attack()

func setup(player: Player) -> void:
	player_data = player
	player_max_health = float(player.max_health)
	player_attack_damage = float(player.attack_power)

func _on_attack_button_pressed() -> void:
	if not battle_active:
		return

	if player_atb.value < player_atb.max_value:
		return

	player_atb.value = 0.0
	attack_button.disabled = true

	enemy_hp.value = max(
		enemy_hp.value - player_attack_damage,
		enemy_hp.min_value
	)
	battle_message.text = "Hero deals %.0f damage!" % player_attack_damage

	if enemy_hp.value <= enemy_hp.min_value:
		_end_battle_victory()

func _end_battle_victory() -> void:
	battle_active = false
	attack_button.disabled = true
	player_atb.value = 0.0
	enemy_atb.value = 0.0
	battle_message.text = "Slime defeated!"

	player_won = true
	attack_button.visible = false
	item_button.visible = false
	result_button.text = "Continue"
	result_button.visible = true

func _enemy_attack() -> void:
	if not battle_active:
		return
	enemy_atb.value = 0.0

	player_hp.value = max(
		player_hp.value - ENEMY_ATTACK_DAMAGE,
		player_hp.min_value
	)
	battle_message.text = "Slime deals %.0f damage!" % ENEMY_ATTACK_DAMAGE

	if player_hp.value <= player_hp.min_value:
		_end_battle_defeated()

func _end_battle_defeated() -> void:
	battle_active = false
	attack_button.disabled = true
	player_atb.value = 0.0
	enemy_atb.value = 0.0
	battle_message.text = "Hero defeated!"
	player_won = false
	attack_button.visible = false
	item_button.visible = false
	result_button.text = "Retry"
	result_button.visible = true

func _on_result_button_pressed() -> void:
	if player_won:
		battle_finished.emit(
			true,
			EXPERIENCE_REWARD,
			GOLD_REWARD,
		)
	else:
		battle_finished.emit(
			false,
			0,
			0,
		)

func _on_item_button_pressed() -> void:
	if not battle_active:
		return

	if player_atb.value < player_atb.max_value:
		return

	if player_data == null:
		return

	if not player_data.has_item("Small Potion"):
		return

	if player_hp.value >= player_hp.max_value:
		return

	player_atb.value = 0.0
	attack_button.disabled = true
	item_button.disabled = true

	if not player_data.consume_item("Small Potion"):
		return

	player_hp.value = min(
		player_hp.value + SMALL_POTION_HEALING,
		player_hp.max_value
	)

	battle_message.text = "Hero uses Small Potion!"