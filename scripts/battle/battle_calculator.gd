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
		
	# 1. Evaluate Costs (applied to caster)
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
				caster_delta.atb_delta = FORMULAS.calculate_atb_after_cast(cost.value)
				
	# 2. Evaluate Effects (applied to targets or self)
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
					target_delta.hp_delta -= damage
					total_applied_damage += damage
				ActionEffectData.EffectType.ATK:
					target_delta.atk_delta += FORMULAS.skill_effect_delta(battle_manager.get_actor_stat(target, ActionEffectData.EffectType.ATK), effect)
				ActionEffectData.EffectType.DEF:
					target_delta.def_delta += FORMULAS.skill_effect_delta(battle_manager.get_actor_stat(target, ActionEffectData.EffectType.DEF), effect)
				ActionEffectData.EffectType.SPD:
					target_delta.spd_delta += FORMULAS.skill_effect_delta(battle_manager.get_actor_stat(target, ActionEffectData.EffectType.SPD), effect)
				ActionEffectData.EffectType.FREE_ACTION:
					target_delta.is_free_action = true

	if total_applied_damage > 0.0:
		preview.add_message("%s 造成了 %.0f 点伤害。" % [skill.display_name, total_applied_damage])
		
	return preview


static func evaluate_item(
	item: ItemData,
	caster: Node,
	targets: Array[Node],
	battle_manager: BattleManager
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
