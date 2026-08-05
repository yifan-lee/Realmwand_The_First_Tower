class_name BattleManager
extends Node

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal battle_started(enemy: Enemy)
signal battle_finished(victory: bool)

enum BattleState {
	INACTIVE,
	RUNNING,
	WAITING_FOR_PLAYER,
}

var _player: Player
var _enemy: Enemy
var _battle_ui: BattleUI
var _state: BattleState = BattleState.INACTIVE
var _player_atb := 0.0
var _enemy_atb := 0.0
var _cooldowns: Dictionary[StringName, float] = {}
var _enemy_cooldowns: Dictionary[StringName, float] = {}
var _player_casting_skill: SkillData
var _enemy_casting_skill: SkillData
var _player_effects: Array[Dictionary] = []
var _enemy_effects: Array[Dictionary] = []


func setup(player: Player, battle_ui: BattleUI) -> void:
	_player = player
	_battle_ui = battle_ui
	EventBus.battle_requested.connect(_on_battle_requested)
	battle_ui.skill_selected.connect(_on_skill_selected)
	battle_ui.item_selected.connect(_on_item_selected)
	battle_ui.escape_requested.connect(_on_escape_requested)


func is_active() -> bool:
	return _state != BattleState.INACTIVE


func is_waiting_for_player() -> bool:
	return _state == BattleState.WAITING_FOR_PLAYER


func _process(delta: float) -> void:
	if _state != BattleState.RUNNING or _enemy == null:
		return

	_tick_cooldowns(delta)
	_tick_effects(_player_effects, delta)
	_tick_effects(_enemy_effects, delta)
	_recover_focus_points(delta)
	if _enemy_atb >= FORMULAS.ATB_MAX:
		_resolve_ready_enemy_turn()
		return

	_player_atb = minf(
		FORMULAS.ATB_MAX,
		_player_atb + FORMULAS.calculate_atb_gain(_get_player_stat(SkillEffectData.EffectType.SPD), delta)
	)
	_enemy_atb = minf(
		FORMULAS.ATB_MAX,
		_enemy_atb + FORMULAS.calculate_atb_gain(_get_enemy_stat(SkillEffectData.EffectType.SPD), delta)
	)

	if _player_atb >= FORMULAS.ATB_MAX:
		if _player_casting_skill != null:
			_release_player_skill()
			if not is_active():
				return
		else:
			_state = BattleState.WAITING_FOR_PLAYER
			_battle_ui.set_action_available(true)
			_battle_ui.show_message("轮到你行动，战斗时间已暂停。")
			_battle_ui.set_atb(_player_atb, _enemy_atb)
			return

	if _enemy_atb >= FORMULAS.ATB_MAX:
		_resolve_ready_enemy_turn()
		return

	_battle_ui.set_atb(_player_atb, _enemy_atb)


func start_battle(enemy: Enemy, player: Player) -> void:
	if is_active() or enemy == null or player == null or enemy.is_defeated:
		return
	_enemy = enemy
	_player = player
	_player.set_current_fp(_player.get_start_fp())
	_enemy.set_current_fp(_enemy.enemy_data.start_fp)
	_state = BattleState.RUNNING
	_player_atb = 0.0
	_enemy_atb = 0.0
	_cooldowns.clear()
	_enemy_cooldowns.clear()
	_player_casting_skill = null
	_enemy_casting_skill = null
	_player_effects.clear()
	_enemy_effects.clear()
	_player.set_input_enabled(false)
	_battle_ui.open(_player, _enemy)
	_battle_ui.show_message("遭遇 %s，战斗开始。" % _enemy.enemy_data.display_name)
	battle_started.emit(_enemy)


func _on_battle_requested(enemy: Enemy, player: Player) -> void:
	start_battle(enemy, player)


func _on_skill_selected(skill: SkillData) -> void:
	if _state != BattleState.WAITING_FOR_PLAYER or skill == null:
		return
	if _cooldowns.get(skill.id, 0.0) > 0.0:
		_battle_ui.show_message("%s 仍在冷却。" % skill.display_name)
		return
	if _player.current_mp < skill.mp_cost:
		_battle_ui.show_message("魔力不足。")
		return
	if _player.current_fp < skill.fp_cost:
		_battle_ui.show_message("专注值不足。")
		return

	_player.change_mp(-skill.mp_cost)
	_player.change_fp(-skill.fp_cost)
	_cooldowns[skill.id] = skill.cooldown_seconds
	if is_zero_approx(skill.cast_time):
		_release_player_skill(skill)
		return

	_player_casting_skill = skill
	_player_atb = FORMULAS.calculate_atb_after_cast(skill.cast_time)
	_state = BattleState.RUNNING
	_battle_ui.set_action_available(false)
	_battle_ui.refresh_stats()
	_battle_ui.set_atb(_player_atb, _enemy_atb)
	_battle_ui.show_message("%s 正在吟唱。" % skill.display_name)


func _on_item_selected(item: ItemData) -> void:
	if _state != BattleState.WAITING_FOR_PLAYER or item == null:
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
	if _state == BattleState.WAITING_FOR_PLAYER:
		_finish_battle(false)


func _begin_enemy_turn() -> void:
	if _state != BattleState.RUNNING:
		return

	var skill := _get_enemy_usable_skill()
	if skill == null:
		_enemy_atb = 0.0
		_resolve_enemy_attack(null)
		return

	_enemy.change_mp(-skill.mp_cost)
	_enemy.change_fp(-skill.fp_cost)
	_enemy_cooldowns[skill.id] = skill.cooldown_seconds
	if is_zero_approx(skill.cast_time):
		_resolve_enemy_attack(skill)
		return

	_enemy_casting_skill = skill
	_enemy_atb = FORMULAS.calculate_atb_after_cast(skill.cast_time)
	_battle_ui.refresh_stats()
	_battle_ui.set_atb(_player_atb, _enemy_atb)
	_battle_ui.show_message("%s 正在吟唱 %s。" % [_enemy.enemy_data.display_name, skill.display_name])


func _resolve_ready_enemy_turn() -> void:
	if _enemy_casting_skill != null:
		_release_enemy_skill()
	else:
		_begin_enemy_turn()
	if is_active():
		_battle_ui.set_atb(_player_atb, _enemy_atb)


func _release_player_skill(skill: SkillData = null) -> void:
	var resolved_skill := skill
	if resolved_skill == null:
		resolved_skill = _player_casting_skill
	_player_casting_skill = null
	if resolved_skill == null:
		return

	var applied := 0.0
	if resolved_skill.target_type == SkillData.TargetType.ENEMY:
		var damage: float = FORMULAS.calculate_skill_damage(
			_get_player_stat(SkillEffectData.EffectType.ATK),
			resolved_skill.skill_power,
			_get_enemy_stat(SkillEffectData.EffectType.DEF)
		)
		applied = _enemy.take_damage(damage)
	_apply_skill_effects(resolved_skill, false)
	if applied > 0.0:
		_battle_ui.show_message("%s 造成了 %.0f 点伤害。" % [resolved_skill.display_name, applied])
	else:
		_battle_ui.show_message("使用了 %s。" % resolved_skill.display_name)
	_complete_player_action()
	if _enemy.is_defeated:
		_finish_battle(true)


func _release_enemy_skill() -> void:
	var skill := _enemy_casting_skill
	_enemy_casting_skill = null
	_resolve_enemy_attack(skill)


func _resolve_enemy_attack(skill: SkillData) -> void:
	var power := 0.0
	var skill_name := "攻击"
	if skill != null:
		power = skill.skill_power
		skill_name = skill.display_name
	var damage: float = FORMULAS.calculate_skill_damage(
		_get_enemy_stat(SkillEffectData.EffectType.ATK),
		power,
		_get_player_stat(SkillEffectData.EffectType.DEF)
	)
	_player.change_hp(-damage)
	if skill != null:
		_apply_skill_effects(skill, true)
	_enemy_atb = 0.0
	_battle_ui.refresh_stats()
	_battle_ui.show_message("%s 使用 %s，造成 %.0f 点伤害。" % [_enemy.enemy_data.display_name, skill_name, damage])
	if _player.current_hp <= 0.0:
		_finish_battle(false)


func _complete_player_action() -> void:
	_player_atb = 0.0
	_state = BattleState.RUNNING
	_battle_ui.set_action_available(false)
	_battle_ui.refresh_stats()


func _finish_battle(victory: bool) -> void:
	if not is_active():
		return
	_state = BattleState.INACTIVE
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
	return FORMULAS.default_enemy_experience(
		_enemy.enemy_data.atk,
		_enemy.enemy_data.def,
		_enemy.enemy_data.spd
	)


func _tick_cooldowns(delta: float) -> void:
	for skill_id: StringName in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(0.0, _cooldowns[skill_id] - delta)
	for skill_id: StringName in _enemy_cooldowns.keys():
		_enemy_cooldowns[skill_id] = maxf(0.0, _enemy_cooldowns[skill_id] - delta)


func _recover_focus_points(delta: float) -> void:
	_player.change_fp(
		FORMULAS.calculate_fp_recovery(
			_player.get_fp_recovery_spd(),
			delta
		)
	)
	_enemy.change_fp(
		FORMULAS.calculate_fp_recovery(
		_enemy.get_fp_recovery_spd(),
			delta
		)
	)


func _get_enemy_usable_skill() -> SkillData:
	for skill: SkillData in _enemy.enemy_data.skills:
		if _enemy_cooldowns.get(skill.id, 0.0) > 0.0:
			continue
		if _enemy.current_mp < skill.mp_cost:
			continue
		if _enemy.current_fp < skill.fp_cost:
			continue
		return skill
	return null


func _apply_skill_effects(
	skill: SkillData,
	caster_is_enemy: bool
) -> void:
	for effect: SkillEffectData in skill.effects:
		var targets_self := effect.target_type == SkillEffectData.TargetType.SELF
		var target: Array[Dictionary] = _player_effects
		if targets_self == caster_is_enemy:
			target = _enemy_effects
		target.append({
			&"effect": effect,
			&"remaining": effect.duration_seconds,
		})


func _tick_effects(
	effects: Array[Dictionary],
	delta: float
) -> void:
	for index: int in range(effects.size() - 1, -1, -1):
		var remaining: float = float(effects[index].get(&"remaining", 0.0)) - delta
		if remaining <= 0.0:
			effects.remove_at(index)
		else:
			effects[index][&"remaining"] = remaining


func _get_player_stat(effect_type: int) -> float:
	var base_value := 0.0
	match effect_type:
		SkillEffectData.EffectType.ATK:
			base_value = _player.get_atk()
		SkillEffectData.EffectType.DEF:
			base_value = _player.get_def()
		SkillEffectData.EffectType.SPD:
			base_value = _player.get_spd()
	return FORMULAS.calculate_effective_stat(base_value, _player_effects, effect_type)


func _get_enemy_stat(effect_type: int) -> float:
	var base_value := 0.0
	match effect_type:
		SkillEffectData.EffectType.ATK:
			base_value = _enemy.enemy_data.atk
		SkillEffectData.EffectType.DEF:
			base_value = _enemy.enemy_data.def
		SkillEffectData.EffectType.SPD:
			base_value = _enemy.enemy_data.spd
	return FORMULAS.calculate_effective_stat(base_value, _enemy_effects, effect_type)
