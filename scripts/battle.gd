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
@onready var enemy_name: Label = $EnemyPanel/EnemyInfo/EnemyName

const PLAYER_ATB_SPEED: float = 50.0
var player_attack_damage: float = 50.0

var battle_active: bool = true
var player_won: bool = false
var player_data: Player
var enemy_data: EnemyData

const SMALL_POTION: ItemData = preload(
	"res://resources/items/small_potion.tres"
)



func _ready() -> void:
	if player_data == null:
		push_error("Battle.setup() 没有收到 Player")
		set_process(false)
		return

	if enemy_data == null:
		push_error("Battle.setup() 没有收到 Enemy")
		set_process(false)
		return

	player_hp.max_value = player_data.max_health
	player_hp.value = player_data.current_health

	enemy_name.text = enemy_data.display_name
	enemy_hp.max_value = enemy_data.max_health
	enemy_hp.value = enemy_data.max_health

	battle_message.text = (
		"%s appeared!" % enemy_data.display_name
	)

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
		enemy_atb.value + enemy_data.atb_speed * delta,
		enemy_atb.max_value
	)

	if player_atb.value >= player_atb.max_value:
		attack_button.disabled = false
		var has_small_potion := (
			player_data != null
			and player_data.has_item(SMALL_POTION.id)
		)
		item_button.disabled = (
			not has_small_potion
			or player_data.current_health >= player_data.max_health
		)

	if enemy_atb.value >= enemy_atb.max_value:
		_enemy_attack()

func setup(
	player: Player,
	enemy: EnemyData
) -> void:
	player_data = player
	player_attack_damage = float(player.attack_power)
	enemy_data = enemy

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
	battle_message.text = (
		"%s defeated!" 
		% enemy_data.display_name
	)

	player_won = true
	attack_button.visible = false
	item_button.visible = false
	result_button.text = "Continue"
	result_button.visible = true

func _enemy_attack() -> void:
	if not battle_active:
		return
	enemy_atb.value = 0.0

	player_data.take_damage(int(enemy_data.attack_damage))
	player_hp.value = player_data.current_health
	battle_message.text = (
		"%s deals %.0f damage!" 
		% [
			enemy_data.display_name,
			enemy_data.attack_damage,
		]
	)

	if player_data.current_health <= 0:
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
			enemy_data.experience_reward,
			enemy_data.gold_reward,
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

	if player_data.current_health >= player_data.max_value:
		return

	var used_item := player_data.consume_item(
		SMALL_POTION.id
	)

	if used_item == null:
		return

	player_atb.value = 0.0
	attack_button.disabled = true
	item_button.disabled = true


	player_data.heal(used_item.healing_amount)
	player_hp.value = player_data.current_health

	battle_message.text = "Hero uses %s!" % used_item.display_name