class_name BattleManager
extends Node

signal battle_started(enemy: Enemy)
signal battle_finished(victory: bool)

const ATB_MAX := 100.0

var _player: Player
var _enemy: Enemy
var _battle_ui: BattleUI
var _active := false
var _player_atb := 0.0
var _enemy_atb := 0.0
var _player_ready := false
var _cooldowns: Dictionary[StringName, float] = {}


func setup(player: Player, battle_ui: BattleUI) -> void:
	_player = player
	_battle_ui = battle_ui
	EventBus.battle_requested.connect(_on_battle_requested)
	battle_ui.skill_selected.connect(_on_skill_selected)
	battle_ui.item_selected.connect(_on_item_selected)
	battle_ui.escape_requested.connect(_on_escape_requested)


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active or _enemy == null:
		return

	_tick_cooldowns(delta)

	if not _player_ready:
		_player_atb = minf(ATB_MAX, _player_atb + _player.get_spd() * delta)
		if _player_atb >= ATB_MAX:
			_player_ready = true
			_battle_ui.set_action_available(true)
			_battle_ui.show_message("轮到你行动。")

	_enemy_atb = minf(ATB_MAX, _enemy_atb + _enemy.enemy_data.spd * delta)
	if _enemy_atb >= ATB_MAX:
		_enemy_atb = 0.0
		_enemy_take_turn()

	_battle_ui.set_atb(_player_atb, _enemy_atb)


func start_battle(enemy: Enemy, player: Player) -> void:
	if _active or enemy == null or player == null or enemy.is_defeated:
		return

	_enemy = enemy
	_player = player
	_active = true
	_player_atb = 0.0
	_enemy_atb = 0.0
	_player_ready = false
	_cooldowns.clear()
	_player.set_input_enabled(false)
	_battle_ui.open(_player, _enemy)
	_battle_ui.show_message("遭遇 %s，战斗开始。" % _enemy.enemy_data.display_name)
	battle_started.emit(_enemy)


func _on_battle_requested(enemy: Enemy, player: Player) -> void:
	start_battle(enemy, player)


func _on_skill_selected(skill: SkillData) -> void:
	if not _active or not _player_ready or skill == null:
		return
	if _cooldowns.get(skill.id, 0.0) > 0.0:
		_battle_ui.show_message("%s 仍在冷却。" % skill.display_name)
		return
	if _player.current_mp < skill.mp_cost:
		_battle_ui.show_message("MP 不足。")
		return

	_player.change_mp(-skill.mp_cost)
	var damage := maxf(1.0, _player.get_atk() + skill.skill_power - _enemy.enemy_data.def)
	var applied := _enemy.take_damage(damage)
	_cooldowns[skill.id] = skill.cooldown_seconds
	_battle_ui.show_message("%s 造成了 %.0f 点伤害。" % [skill.display_name, applied])
	_complete_player_action()

	if _enemy.is_defeated:
		_finish_battle(true)


func _on_item_selected(item: ItemData) -> void:
	if not _active or not _player_ready or item == null:
		return
	if not item.usable_in_battle:
		_battle_ui.show_message("这个物品不能在战斗中使用。")
		return

	_player.change_hp(item.hp_recovery)
	_player.change_mp(item.mp_recovery)
	if item.consumed_on_use:
		_player.inventory.remove_item(item.id)
	_battle_ui.show_message("使用了 %s。" % item.display_name)
	_complete_player_action()


func _on_escape_requested() -> void:
	if _active:
		_finish_battle(false)


func _enemy_take_turn() -> void:
	if not _active:
		return

	var power := 0.0
	var skill_name := "攻击"
	if not _enemy.enemy_data.skills.is_empty():
		var skill: SkillData = _enemy.enemy_data.skills.front()
		power = skill.skill_power
		skill_name = skill.display_name

	var damage := maxf(1.0, _enemy.enemy_data.atk + power - _player.get_def())
	_player.change_hp(-damage)
	_battle_ui.refresh_stats()
	_battle_ui.show_message("%s 使用 %s，造成 %.0f 点伤害。" % [_enemy.enemy_data.display_name, skill_name, damage])

	if _player.current_hp <= 0.0:
		_finish_battle(false)


func _complete_player_action() -> void:
	_player_atb = 0.0
	_player_ready = false
	_battle_ui.set_action_available(false)
	_battle_ui.refresh_stats()


func _finish_battle(victory: bool) -> void:
	if not _active:
		return

	_active = false
	_battle_ui.close()
	_player.set_input_enabled(true)

	if victory:
		var reward := _get_experience_reward()
		_player.gold += _enemy.enemy_data.gold_reward
		_player.add_experience(reward)
	else:
		_player.set_current_hp(maxf(1.0, _player.current_hp))

	battle_finished.emit(victory)
	_enemy = null


func _get_experience_reward() -> int:
	if _enemy.enemy_data.experience_reward_override >= 0:
		return _enemy.enemy_data.experience_reward_override
	return maxi(1, roundi(_enemy.enemy_data.max_hp * 0.25))


func _tick_cooldowns(delta: float) -> void:
	for skill_id: StringName in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(0.0, _cooldowns[skill_id] - delta)
