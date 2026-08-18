class_name BattleManager
extends Node

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

signal battle_started(enemy: Enemy)
signal battle_finished(victory: bool)
signal player_turn_started

enum BattleState {
	INACTIVE,
	RUNNING,
	WAITING_FOR_PLAYER,
}

var _player: Player
var _enemy: Enemy
var _battle_ui: BattleUI
var _state: BattleState = BattleState.INACTIVE
var _player_atb: float = 0.0
var _enemy_atb: float = 0.0

var _pre_battle_hp: float = 0.0
var _pre_battle_mp: float = 0.0
var _pre_battle_fp: float = 0.0
var _pre_battle_inventory: Array[Dictionary] = []

var _pre_battle_enemy_hp: float = 0.0
var _pre_battle_enemy_mp: float = 0.0
var _pre_battle_enemy_fp: float = 0.0
var _cooldowns: Dictionary[StringName, int] = {}
var _enemy_cooldowns: Dictionary[StringName, int] = {}
var _player_casting_skill: SkillData
var _enemy_casting_skill: SkillData
var _enemy_queued_skill: SkillData
var _is_paused: bool = false

var status_controller: BattleStatusController = BattleStatusController.new()


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
	if _is_paused or _state != BattleState.RUNNING or _enemy == null:
		return

	_recover_focus_points(delta)
	if _enemy_atb >= FORMULAS.ATB_MAX:
		_resolve_ready_enemy_turn()
		return

	_player_atb = minf(
		FORMULAS.ATB_MAX,
		_player_atb + FORMULAS.calculate_atb_gain(get_actor_stat(_player, StatusEffectData.StatType.SPD), delta)
	)
	_enemy_atb = minf(
		FORMULAS.ATB_MAX,
		_enemy_atb + FORMULAS.calculate_atb_gain(get_actor_stat(_enemy, StatusEffectData.StatType.SPD), delta)
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
			player_turn_started.emit()
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
	
	_pre_battle_hp = _player.current_hp
	_pre_battle_mp = _player.current_mp
	_pre_battle_fp = _player.current_fp
	_pre_battle_inventory = _player.inventory.capture_save_data()
	
	_pre_battle_enemy_hp = _enemy.current_hp
	_pre_battle_enemy_mp = _enemy.current_mp
	_pre_battle_enemy_fp = _enemy.current_fp
	
	_player.set_current_fp(_player.get_start_fp())
	_enemy.set_current_fp(_enemy.enemy_data.start_fp)
	_state = BattleState.RUNNING
	_player_atb = 0.0
	_enemy_atb = 0.0
	_cooldowns.clear()
	_enemy_cooldowns.clear()
	_player_casting_skill = null
	_enemy_casting_skill = null
	status_controller.clear_all()
	_player.set_input_enabled(false)
	
	_load_passive_statuses()
	_battle_ui.open(_player, _enemy, self)
	_queue_enemy_next_skill()
	_battle_ui.show_message("遭遇 %s，战斗开始。" % _enemy.enemy_data.display_name)
	battle_started.emit(_enemy)


func _load_passive_statuses() -> void:
	_load_actor_passives(_player)
	_load_actor_passives(_enemy)


func _load_actor_passives(actor: Node) -> void:
	if actor == null:
		return
	var skills: Array[SkillData] = []
	if actor.has_method(&"get_skills"):
		skills = actor.get_skills()
	elif actor is Enemy and (actor as Enemy).enemy_data != null:
		skills = (actor as Enemy).enemy_data.skills
	elif actor is Player:
		skills = (actor as Player).learned_skills

	for skill: SkillData in skills:
		if skill != null and skill.skill_type == SkillData.SkillType.PASSIVE:
			for effect: ActionEffectData in skill.effects:
				if effect.status_to_apply != null:
					status_controller.apply_status(actor, effect.status_to_apply)


func _on_battle_requested(enemy: Enemy, player: Player) -> void:
	start_battle(enemy, player)


func _get_skill_cost(skill: SkillData, type: ActionCostData.CostType) -> float:
	var total := 0.0
	for cost: ActionCostData in skill.costs:
		if cost.cost_type == type:
			total += cost.value
	return total


func _on_skill_selected(skill: SkillData) -> void:
	if _state != BattleState.WAITING_FOR_PLAYER or skill == null:
		return
	if get_skill_cooldown(skill.id, false) > 0:
		_battle_ui.show_message("%s 仍在冷却。" % skill.display_name)
		return
		
	var hp_cost := _get_skill_cost(skill, ActionCostData.CostType.HP)
	var mp_cost := _get_skill_cost(skill, ActionCostData.CostType.MP)
	var fp_cost := _get_skill_cost(skill, ActionCostData.CostType.FP)
	var cd: int = skill.get_cooldown()
	var cast_time := _get_skill_cost(skill, ActionCostData.CostType.CAST_TIME)

	if _player.current_hp <= hp_cost or _player.current_mp < mp_cost or _player.current_fp < fp_cost:
		_battle_ui.show_message("资源不足，无法施放 %s。" % skill.display_name)
		return

	if hp_cost > 0: _player.change_hp(-hp_cost)
	if mp_cost > 0: _player.change_mp(-mp_cost)
	if fp_cost > 0: _player.change_fp(-fp_cost)
	
	if cd > 0: _cooldowns[skill.id] = cd + 1
	
	if is_zero_approx(cast_time):
		_release_player_skill(skill)
		return

	_player_casting_skill = skill
	_player_atb = FORMULAS.calculate_atb_after_cast(cast_time)
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
		
	_decrement_cooldowns(false)
	status_controller.on_action_finished(_player)
	status_controller.on_trigger_event(_player, StatusEffectData.TriggerType.ON_ANY_ACTION)
	
	var preview = BattleCalculator.evaluate_item(item, _player, [_enemy], self)
	_apply_preview(preview, item.effects, false, false)
	
	if item.consumed_on_use:
		_player.inventory.remove_item(item.id)
	_battle_ui.show_message("使用了 %s。" % item.display_name)
	
	var player_delta = preview.actor_deltas.get(_player, null)
	var is_free_action = false
	if player_delta != null and player_delta.is_free_action:
		is_free_action = true
	_complete_player_action(is_free_action)


func _on_escape_requested() -> void:
	if _state == BattleState.WAITING_FOR_PLAYER:
		_finish_battle(false)


func _begin_enemy_turn() -> void:
	if _state != BattleState.RUNNING:
		return

	var skill: SkillData = _enemy_queued_skill

	if skill == null:
		_enemy_atb = 0.0
		_resolve_enemy_attack(null)
		return

	var hp_cost := _get_skill_cost(skill, ActionCostData.CostType.HP)
	var mp_cost := _get_skill_cost(skill, ActionCostData.CostType.MP)
	var fp_cost := _get_skill_cost(skill, ActionCostData.CostType.FP)
	var cd: int = skill.get_cooldown()
	var cast_time := _get_skill_cost(skill, ActionCostData.CostType.CAST_TIME)

	if hp_cost > 0: _enemy.change_hp(-hp_cost)
	if mp_cost > 0: _enemy.change_mp(-mp_cost)
	if fp_cost > 0: _enemy.change_fp(-fp_cost)
	if cd > 0: _enemy_cooldowns[skill.id] = cd + 1
	
	if is_zero_approx(cast_time):
		_resolve_enemy_attack(skill)
		return

	_enemy_casting_skill = skill
	_enemy_atb = FORMULAS.calculate_atb_after_cast(cast_time)
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

	var preview := BattleActionPreview.new()
	BattleCalculator.evaluate_skill_effects(resolved_skill, _player, [_enemy], self, preview)
	_decrement_cooldowns(false)
	status_controller.on_action_finished(_player)
	status_controller.on_trigger_event(_player, StatusEffectData.TriggerType.ON_ANY_ACTION)
	if resolved_skill.skill_type == SkillData.SkillType.PHYSICAL:
		status_controller.on_trigger_event(_player, StatusEffectData.TriggerType.ON_PHYSICAL_ATTACK)
	elif resolved_skill.skill_type == SkillData.SkillType.MAGICAL:
		status_controller.on_trigger_event(_player, StatusEffectData.TriggerType.ON_MAGICAL_ATTACK)

	var is_physical := (resolved_skill.skill_type == SkillData.SkillType.PHYSICAL)
	_apply_preview(preview, resolved_skill.effects, false, is_physical)
	
	var message = "使用了 %s。" % resolved_skill.display_name
	for extra in preview.extra_messages:
		message += "\n" + extra
	_battle_ui.show_message(message)
	
	var player_delta = preview.actor_deltas.get(_player, null)
	var is_free_action = false
	if player_delta != null and player_delta.is_free_action:
		is_free_action = true
	_complete_player_action(is_free_action)
	if _enemy.is_defeated or _enemy.current_hp <= 0.0:
		_finish_battle(true)
	elif _player.current_hp <= 0.0:
		_finish_battle(false)


func _release_enemy_skill() -> void:
	var skill := _enemy_casting_skill
	_enemy_casting_skill = null
	_resolve_enemy_attack(skill)


func _resolve_enemy_attack(skill: SkillData) -> void:
	var skill_name := "攻击"
	if skill != null:
		skill_name = skill.display_name
		
	var preview := BattleActionPreview.new()
	BattleCalculator.evaluate_skill_effects(skill, _enemy, [_player], self, preview)
	_decrement_cooldowns(true)
	status_controller.on_action_finished(_enemy)
	status_controller.on_trigger_event(_enemy, StatusEffectData.TriggerType.ON_ANY_ACTION)
	
	var is_physical := (skill == null) or (skill.skill_type == SkillData.SkillType.PHYSICAL)
	if is_physical:
		status_controller.on_trigger_event(_enemy, StatusEffectData.TriggerType.ON_PHYSICAL_ATTACK)
	elif skill != null and skill.skill_type == SkillData.SkillType.MAGICAL:
		status_controller.on_trigger_event(_enemy, StatusEffectData.TriggerType.ON_MAGICAL_ATTACK)

	if skill == null:
		# Fallback to basic attack if no skill
		var damage: float = FORMULAS.calculate_skill_damage(
			get_actor_stat(_enemy, StatusEffectData.StatType.ATK),
			1.0,
			get_actor_stat(_player, StatusEffectData.StatType.DEF)
		)
		_player.change_hp(-damage)
		var counter_messages: Array[String] = []
		var counter_events = status_controller.on_damage_taken(_player, _enemy, damage, true)
		for event in counter_events:
			var dmg: float = event.damage
			_enemy.change_hp(-dmg)
			var source_name: String = event.status_name if not event.status_name.is_empty() else "反伤"
			counter_messages.append("【%s】对 %s 反弹了 %.0f 点伤害！" % [source_name, _enemy.enemy_data.display_name, dmg])
		var msg_text := "%s 使用 %s，造成 %.0f 点伤害。" % [_enemy.enemy_data.display_name, skill_name, damage]
		for extra in counter_messages:
			msg_text += "\n" + extra
		_battle_ui.show_message(msg_text)
	else:
		_apply_preview(preview, skill.effects, true, is_physical)
		var message = "%s 使用了 %s。" % [_enemy.enemy_data.display_name, skill_name]
		for extra in preview.extra_messages:
			message += "\n" + extra
		_battle_ui.show_message(message)
	
	var enemy_delta = preview.actor_deltas.get(_enemy, null)
	var is_free_action = false
	if enemy_delta != null and enemy_delta.is_free_action:
		is_free_action = true
		
	if is_free_action:
		_enemy_atb = FORMULAS.ATB_MAX
	else:
		_enemy_atb = 0.0
		
	_queue_enemy_next_skill()
	_battle_ui.refresh_stats()
	
	if _player.current_hp <= 0.0:
		_finish_battle(false)
	elif _enemy.current_hp <= 0.0:
		_finish_battle(true)


func _apply_preview(preview: BattleActionPreview, effects_to_apply: Array[ActionEffectData] = [], caster_is_enemy: bool = false, is_physical: bool = true) -> void:
	var caster: Node = _enemy if caster_is_enemy else _player
	var counter_messages: Array[String] = []

	for actor in preview.actor_deltas.keys():
		var delta = preview.actor_deltas[actor]
		var prev_shield: float = actor.current_shield if (actor != null and actor.get("current_shield") != null) else 0.0
		if delta.shield_delta > 0.0 and actor.has_method(&"add_shield"):
			actor.add_shield(delta.shield_delta)
		actor.change_hp(delta.hp_delta)
		actor.change_mp(delta.mp_delta)
		actor.change_fp(delta.fp_delta)
		if delta.is_interrupted:
			_interrupt_actor(actor)
		# 破盾检测
		var cur_shield: float = actor.current_shield if (actor != null and actor.get("current_shield") != null) else 0.0
		if prev_shield > 0.0 and cur_shield <= 0.0:
			status_controller.on_shield_depleted(actor)

		# 受击反伤结算
		if delta.hp_delta < 0.0 and actor != caster and caster != null:
			var actual_dmg: float = absf(delta.hp_delta)
			var counter_events = status_controller.on_damage_taken(actor, caster, actual_dmg, is_physical)
			for event in counter_events:
				var dmg: float = event.damage
				caster.change_hp(-dmg)
				var source_name: String = event.status_name if not event.status_name.is_empty() else "反伤"
				var caster_name: String = "玩家" if caster == _player else (_enemy.enemy_data.display_name if _enemy.enemy_data else "敌人")
				counter_messages.append("【%s】对 %s 反弹了 %.0f 点伤害！" % [source_name, caster_name, dmg])

	# Apply buff/debuff status data
	for effect: ActionEffectData in effects_to_apply:
		if effect.status_to_apply != null:
			var targets: Array[Node] = []
			if effect.target == ActionEffectData.TargetType.SELF:
				targets = [_enemy] if caster_is_enemy else [_player]
			elif effect.target == ActionEffectData.TargetType.OPPONENT:
				targets = [_player] if caster_is_enemy else [_enemy]
			elif effect.target == ActionEffectData.TargetType.ALL:
				targets = [_player, _enemy]
			for tgt in targets:
				if tgt != null:
					status_controller.apply_status(tgt, effect.status_to_apply)

	for msg in counter_messages:
		preview.extra_messages.append(msg)


func _complete_player_action(is_free_action: bool = false) -> void:
	if is_free_action:
		_player_atb = FORMULAS.ATB_MAX
		_state = BattleState.WAITING_FOR_PLAYER
		_battle_ui.set_action_available(true)
	else:
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
	if _player != null and _player.has_method(&"clear_shield"):
		_player.clear_shield()
	if _enemy != null and _enemy.has_method(&"clear_shield"):
		_enemy.clear_shield()
	status_controller.clear_all()
	if victory:
		var reward := _get_experience_reward()
		_player.gold += _enemy.enemy_data.gold_reward
		_player.add_experience(reward)
	else:
		_player.set_current_hp(_pre_battle_hp)
		_player.set_current_mp(_pre_battle_mp)
		_player.set_current_fp(_pre_battle_fp)
		_player.inventory.restore_save_data(_pre_battle_inventory)
		
		_enemy.set_current_hp(_pre_battle_enemy_hp)
		_enemy.set_current_mp(_pre_battle_enemy_mp)
		_enemy.set_current_fp(_pre_battle_enemy_fp)
	battle_finished.emit(victory)
	_enemy = null
	EventBus.system_message_requested.emit(
		"战斗胜利。" if victory else "战斗结束。"
	)


func _get_experience_reward() -> int:
	if _enemy.enemy_data.experience_reward_override >= 0:
		return _enemy.enemy_data.experience_reward_override
	return FORMULAS.default_enemy_experience(
		_enemy.enemy_data.atk,
		_enemy.enemy_data.def,
		_enemy.enemy_data.spd
	)


func get_actor_effects(actor: Node) -> Array[Dictionary]:
	return status_controller.get_active_effects_for_ui(actor)


func _decrement_cooldowns(is_enemy: bool) -> void:
	var cds: Dictionary[StringName, int] = _enemy_cooldowns if is_enemy else _cooldowns
	for skill_id: StringName in cds.keys():
		var remaining: int = cds[skill_id] - 1
		if remaining <= 0:
			cds.erase(skill_id)
		else:
			cds[skill_id] = remaining


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


func _queue_enemy_next_skill() -> void:
	if _enemy == null or _enemy.is_defeated:
		_enemy_queued_skill = null
		_battle_ui.set_enemy_forecast(null)
		return
	_enemy_queued_skill = BattleEnemyAI.choose_skill(_enemy, self)
	_battle_ui.set_enemy_forecast(_enemy_queued_skill)


func get_actor_stat(actor: Node, stat_type: StatusEffectData.StatType) -> float:
	var base_value := 0.0
	if actor == _player:
		match stat_type:
			StatusEffectData.StatType.ATK:
				base_value = _player.get_atk()
			StatusEffectData.StatType.DEF:
				base_value = _player.get_def()
			StatusEffectData.StatType.SPD:
				base_value = _player.get_spd()
			StatusEffectData.StatType.MAX_HP:
				base_value = _player.get_max_hp()
			StatusEffectData.StatType.MAX_MP:
				base_value = _player.get_max_mp()
	elif actor == _enemy:
		match stat_type:
			StatusEffectData.StatType.ATK:
				base_value = _enemy.get_atk()
			StatusEffectData.StatType.DEF:
				base_value = _enemy.get_def()
			StatusEffectData.StatType.SPD:
				base_value = _enemy.get_spd()
			StatusEffectData.StatType.MAX_HP:
				base_value = _enemy.get_max_hp()
			StatusEffectData.StatType.MAX_MP:
				base_value = _enemy.get_max_mp()

	return status_controller.get_effective_stat(base_value, actor, stat_type)


func get_skill_power_modifier(actor: Node, skill_type: int) -> float:
	return status_controller.get_skill_power_modifier(actor, skill_type)


func get_skill_cooldown(skill_id: StringName, is_enemy: bool = false) -> int:
	var cds: Dictionary[StringName, int] = _enemy_cooldowns if is_enemy else _cooldowns
	return cds.get(skill_id, 0)


func pause_battle() -> void:
	_is_paused = true


func resume_battle() -> void:
	_is_paused = false


func is_player_casting() -> bool:
	return _player_casting_skill != null


func is_enemy_casting() -> bool:
	return _enemy_casting_skill != null


func is_actor_casting(actor: Node) -> bool:
	if actor == _player:
		return is_player_casting()
	elif actor == _enemy:
		return is_enemy_casting()
	return false


func is_actor_interrupted(actor: Node) -> bool:
	if actor == _player:
		return _player_casting_skill != null and _player_atb < 0.0
	elif actor == _enemy:
		return _enemy_casting_skill != null and _enemy_atb < 0.0
	return false


func _interrupt_actor(actor: Node) -> void:
	if actor == _player:
		if _player_casting_skill != null:
			_battle_ui.show_message("%s 的吟唱被打断！" % _player.player_data.display_name)
			_player_casting_skill = null
			_player_atb = 0.0
			_battle_ui.set_atb(_player_atb, _enemy_atb)
	elif actor == _enemy:
		if _enemy_casting_skill != null:
			_battle_ui.show_message("%s 的吟唱被打断！" % _enemy.enemy_data.display_name)
			_enemy_casting_skill = null
			_enemy_atb = 0.0
			_battle_ui.set_atb(_player_atb, _enemy_atb)
			_queue_enemy_next_skill()
