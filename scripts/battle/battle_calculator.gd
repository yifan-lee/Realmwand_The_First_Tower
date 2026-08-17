class_name BattleCalculator
extends RefCounted

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")


static func evaluate_skill(
	skill: SkillData,
	caster: Node,
	targets: Array[Node],
	battle_manager: BattleManager
) -> BattleActionPreview:
	var preview := BattleActionPreview.new()
	if skill == null or caster == null:
		return preview
	
	evaluate_skill_costs(skill, caster, preview)
	evaluate_skill_effects(skill, caster, targets, battle_manager, preview)
	return preview


static func evaluate_skill_costs(
	skill: SkillData,
	caster: Node,
	preview: BattleActionPreview
) -> void:
	if skill == null or caster == null:
		return
		
	var caster_delta := preview.get_or_create_delta(caster)
	for cost: ActionCostData in skill.costs:
		match cost.cost_type:
			ActionCostData.CostType.HP:
				caster_delta.hp_delta -= cost.value
			ActionCostData.CostType.MP:
				caster_delta.mp_delta -= cost.value
			ActionCostData.CostType.FP:
				caster_delta.fp_delta -= cost.value
			ActionCostData.CostType.CAST_TIME:
				if cost.value > 0.0:
					caster_delta.atb_delta -= FORMULAS.ATB_MAX * cost.value


static func evaluate_skill_effects(
	skill: SkillData,
	caster: Node,
	targets: Array[Node],
	battle_manager: BattleManager,
	preview: BattleActionPreview
) -> void:
	if skill == null or caster == null:
		return
		
	var total_applied_damage := 0.0
	
	for effect: ActionEffectData in skill.effects:
		var effect_targets: Array[Node] = targets
		if effect.target_type == ActionEffectData.TargetType.SELF:
			effect_targets = [caster]
			
		for target in effect_targets:
			var target_delta := preview.get_or_create_delta(target)
			
			match effect.effect_type:
				ActionEffectData.EffectType.RESTORE_HP:
					target_delta.hp_delta += effect.value
				ActionEffectData.EffectType.RESTORE_MP:
					target_delta.mp_delta += effect.value
				ActionEffectData.EffectType.RESTORE_FP:
					target_delta.fp_delta += effect.value
				ActionEffectData.EffectType.REDUCE_MP:
					target_delta.mp_delta -= effect.value
				ActionEffectData.EffectType.REDUCE_FP:
					target_delta.fp_delta -= effect.value
				ActionEffectData.EffectType.INTERRUPT:
					if battle_manager.is_actor_casting(target):
						target_delta.is_interrupted = true
						preview.add_message("打断了吟唱。")
					else:
						preview.add_message("目标没有正在吟唱的技能。")
				ActionEffectData.EffectType.REDUCE_HP:
					var caster_atk = battle_manager.get_actor_stat(caster, ActionEffectData.EffectType.ATK)
					var target_def = battle_manager.get_actor_stat(target, ActionEffectData.EffectType.DEF)
					var skill_power = FORMULAS.calculate_skill_power_modifier(
						effect.value,
						battle_manager.get_actor_effects(caster),
						skill.skill_type
					)
					var damage := FORMULAS.calculate_skill_damage(caster_atk, skill_power, target_def)
					if caster.has_method(&"has_skill") and caster.has_skill(&"overload_spd") and battle_manager != null and battle_manager.has_method(&"get_player_skill_cast_count"):
						var next_cast: int = battle_manager.get_player_skill_cast_count() + 1
						if next_cast % 4 == 0:
							damage = roundf(damage * 1.5)
							preview.add_message("（触发【过载极速】伤害提升 50%！）")
					target_delta.hp_delta -= damage
					total_applied_damage += damage
				ActionEffectData.EffectType.ATK:
					target_delta.atk_delta += FORMULAS.skill_effect_delta(battle_manager.get_actor_stat(target, ActionEffectData.EffectType.ATK), effect)
				ActionEffectData.EffectType.DEF:
					target_delta.def_delta += FORMULAS.skill_effect_delta(battle_manager.get_actor_stat(target, ActionEffectData.EffectType.DEF), effect)
				ActionEffectData.EffectType.SPD:
					target_delta.spd_delta += FORMULAS.skill_effect_delta(battle_manager.get_actor_stat(target, ActionEffectData.EffectType.SPD), effect)
				ActionEffectData.EffectType.SHIELD:
					var shield_amount := effect.value
					if effect.operation_type == ActionEffectData.OperationType.MULTIPLY:
						var max_hp = target.get_max_hp() if target.has_method(&"get_max_hp") else 100.0
						shield_amount = max_hp * effect.value
					target_delta.shield_delta += shield_amount
					preview.add_message("获得了 %.0f 点护盾。" % shield_amount)
				ActionEffectData.EffectType.FREE_ACTION:
					target_delta.is_free_action = true

	if total_applied_damage > 0.0:
		preview.add_message("%s 造成了 %.0f 点伤害。" % [skill.display_name, total_applied_damage])


static func evaluate_item(
	item: ItemData,
	caster: Node,
	targets: Array[Node],
	_battle_manager: BattleManager
) -> BattleActionPreview:
	var preview := BattleActionPreview.new()
	if item == null or caster == null:
		return preview
		
	for effect: ActionEffectData in item.effects:
		var effect_targets: Array[Node] = targets
		if effect.target_type == ActionEffectData.TargetType.SELF:
			effect_targets = [caster]
			
		for target in effect_targets:
			var target_delta := preview.get_or_create_delta(target)
			match effect.effect_type:
				ActionEffectData.EffectType.RESTORE_HP:
					target_delta.hp_delta += effect.value
				ActionEffectData.EffectType.RESTORE_MP:
					target_delta.mp_delta += effect.value
				ActionEffectData.EffectType.RESTORE_FP:
					target_delta.fp_delta += effect.value
				ActionEffectData.EffectType.FREE_ACTION:
					target_delta.is_free_action = true
	return preview
