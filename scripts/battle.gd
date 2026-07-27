class_name Battle
extends Control

signal battle_finished(victory: bool)

@onready var player_atb: ProgressBar = $PlayerPanel/PlayerInfo/PlayerATB
@onready var enemy_atb: ProgressBar = $EnemyPanel/EnemyInfo/EnemyATB
@onready var attack_button: Button = $ActionPanel/Actions/AttackButton
@onready var battle_message: Label = $BattleMessage
@onready var enemy_hp: ProgressBar = $EnemyPanel/EnemyInfo/EnemyHP
@onready var player_hp: ProgressBar = $PlayerPanel/PlayerInfo/PlayerHP
@onready var item_button: Button = $ActionPanel/Actions/ItemButton
@onready var result_button: Button = $ActionPanel/Actions/ResultButton

const PLAYER_ATB_SPEED: float = 35.0
const ENEMY_ATB_SPEED: float = 25.0
const PLAYER_ATTACK_DAMAGE: float = 30.0
const ENEMY_ATTACK_DAMAGE: float = 30.0

var battle_active: bool = true
var player_won: bool = false

func _ready() -> void:
	attack_button.disabled = true
	attack_button.pressed.connect(_on_attack_button_pressed)
	result_button.pressed.connect(_on_result_button_pressed)

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

	if enemy_atb.value >= enemy_atb.max_value:
		_enemy_attack()

func _on_attack_button_pressed() -> void:
	if not battle_active:
		return

	if player_atb.value < player_atb.max_value:
		return

	player_atb.value = 0.0
	attack_button.disabled = true

	enemy_hp.value = max(
		enemy_hp.value - PLAYER_ATTACK_DAMAGE,
		enemy_hp.min_value
	)
	battle_message.text = "Hero deals %.0f damage!" % PLAYER_ATTACK_DAMAGE

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
	battle_finished.emit(player_won)
	print("Battle finished. Victory: ", player_won)
