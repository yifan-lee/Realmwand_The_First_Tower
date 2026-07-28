class_name Battle
extends Control

signal battle_finished(
	victory: bool,
	experience_reward: int,
	gold_reward: int,
)

@onready var atb_track: ProgressBar = $SharedATB/Track
@onready var player_point: TextureRect = $SharedATB/PlayerPoint
@onready var enemy_point: TextureRect = $SharedATB/EnemyPoint
@onready var attack_button: Button = $ActionPanel/Actions/AttackButton
@onready var battle_message: Label = $BattleMessage
@onready var enemy_hp: ProgressBar = $EnemyPanel/EnemyInfo/EnemyHP
@onready var enemy_mp: ProgressBar = $EnemyPanel/EnemyInfo/EnemyMP
@onready var player_hp: ProgressBar = $PlayerPanel/PlayerInfo/PlayerHP
@onready var player_mp: ProgressBar = $PlayerPanel/PlayerInfo/PlayerMP
@onready var item_button: Button = $ActionPanel/Actions/ItemButton
@onready var result_button: Button = $ActionPanel/Actions/ResultButton
@onready var enemy_name: Label = $EnemyPanel/EnemyInfo/EnemyName

const BATTLE_BALANCE: BattleBalanceConfig = preload(
	"res://resources/battle/battle_balance.tres"
)
const ATB_MAX: float = 100.0

var player_atb: float = 0.0
var enemy_atb: float = 0.0
var waiting_for_player_action: bool = false

var player_atk: float = 50.0

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

	player_atb = 0.0
	enemy_atb = 0.0
	_update_atb_points()

	player_hp.max_value = player_data.max_hp
	player_hp.value = player_data.current_hp
	player_mp.max_value = player_data.max_mp
	player_mp.value = player_data.current_mp

	enemy_name.text = enemy_data.display_name
	enemy_hp.max_value = enemy_data.max_hp
	enemy_hp.value = enemy_data.max_hp
	enemy_mp.max_value = enemy_data.max_mp
	enemy_mp.value = enemy_data.max_mp

	battle_message.text = (
		"%s appeared!" % enemy_data.display_name
	)

	attack_button.disabled = true
	item_button.disabled = true
	attack_button.pressed.connect(_on_attack_button_pressed)
	result_button.pressed.connect(_on_result_button_pressed)
	item_button.pressed.connect(_on_item_button_pressed)
	

func _process(delta: float) -> void:
	if not battle_active:
		return
	
	if waiting_for_player_action:
		return

	if player_atb < ATB_MAX:
		player_atb = min(
			player_atb
			+ BATTLE_BALANCE.get_atb_rate(player_data.total_spd, ATB_MAX) * delta,
			ATB_MAX
		)

	enemy_atb = min(
		enemy_atb
		+ BATTLE_BALANCE.get_atb_rate(enemy_data.spd, ATB_MAX) * delta,
		ATB_MAX
	)

	_update_atb_points()

	if player_atb >= ATB_MAX:
		_enable_player_actions()
		return
		

	if enemy_atb >= ATB_MAX:
		_enemy_attack()

func _update_atb_point(
	point: TextureRect,
	atb_value: float
) -> void:
	var progress := clampf(atb_value / ATB_MAX, 0.0, 1.0)
	var start_x := (atb_track.position.x - point.size.x / 2.0)
	var end_x := (atb_track.position.x + atb_track.size.x - point.size.x / 2.0)
	point.position.x = lerpf(start_x, end_x, progress)


func _update_atb_points() -> void:
	_update_atb_point(player_point, player_atb)
	_update_atb_point(enemy_point, enemy_atb)

func _enable_player_actions() -> void:
	waiting_for_player_action = true
	attack_button.disabled = false
	attack_button.grab_focus()

	var has_small_potion := (
		player_data != null
		and player_data.has_item(SMALL_POTION.id)
	)

	item_button.disabled = (
		not has_small_potion
		or player_data.current_hp >= player_data.max_hp
	)

func _finish_player_action() -> void:
	waiting_for_player_action = false
	player_atb = 0.0
	attack_button.disabled = true
	item_button.disabled = true
	_update_atb_points()

	attack_button.release_focus()
	item_button.release_focus()

func setup(
	player: Player,
	enemy: EnemyData
) -> void:
	player_data = player
	player_atk = float(player.total_atk)
	enemy_data = enemy

func _on_attack_button_pressed() -> void:
	if not battle_active:
		return

	if player_atb < ATB_MAX:
		return

	_finish_player_action()

	var damage := BATTLE_BALANCE.calculate_damage(
		player_data.total_atk,
		enemy_data.def,
		BATTLE_BALANCE.basic_attack_power
	)

	enemy_hp.value = max(
		enemy_hp.value - damage,
		enemy_hp.min_value
	)
	battle_message.text = "Hero deals %.0f damage!" % damage

	if enemy_hp.value <= enemy_hp.min_value:
		_end_battle_victory()

func _enemy_attack() -> void:
	if not battle_active:
		return
	enemy_atb = 0.0
	_update_atb_points()

	var damage := BATTLE_BALANCE.calculate_damage(
		enemy_data.atk,
		player_data.total_def,
		BATTLE_BALANCE.basic_attack_power
	)

	player_data.take_damage(damage)
	player_hp.value = player_data.current_hp
	battle_message.text = (
		"%s deals %.0f damage!" 
		% [
			enemy_data.display_name,
			damage,
		]
	)

	if player_data.current_hp <= 0:
		_end_battle_defeated()


func _end_battle_victory() -> void:
	battle_active = false
	waiting_for_player_action = false
	attack_button.disabled = true
	player_atb = 0.0
	enemy_atb = 0.0
	_update_atb_points()
	battle_message.text = (
		"%s defeated!" 
		% enemy_data.display_name
	)

	player_won = true
	attack_button.visible = false
	item_button.visible = false
	result_button.text = "Continue"
	result_button.visible = true
	result_button.grab_focus()


func _end_battle_defeated() -> void:
	battle_active = false
	waiting_for_player_action = false
	attack_button.disabled = true
	player_atb = 0.0
	enemy_atb = 0.0
	_update_atb_points()
	battle_message.text = "Hero defeated!"
	player_won = false
	attack_button.visible = false
	item_button.visible = false
	result_button.text = "Retry"
	result_button.visible = true
	result_button.grab_focus()

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

	if not waiting_for_player_action:
		return

	if player_data == null:
		return

	if player_data.current_hp >= player_data.max_hp:
		return

	var used_item := player_data.consume_item(
		SMALL_POTION.id
	)

	if used_item == null:
		return

	_finish_player_action()

	player_data.heal(used_item.healing_amount)
	player_hp.value = player_data.current_hp

	battle_message.text = "Hero uses %s!" % used_item.display_name
