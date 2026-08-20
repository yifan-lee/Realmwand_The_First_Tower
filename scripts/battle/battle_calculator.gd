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
		var effect_targets: Array[Node] = []
		if effect.target == ActionEffectData.TargetType.SELF:
			if caster != null:
				effect_targets.append(caster)
		elif effect.target == ActionEffectData.TargetType.ALL:
			for t in targets:
				if t != null:
					effect_targets.append(t)
			if caster != null and not effect_targets.has(caster):
				effect_targets.append(caster)
		else:
			for t in targets:
				if t != null:
					effect_targets.append(t)
			
		for target in effect_targets:
			if target == null:
				continue
			var target_delta := preview.get_or_create_delta(target)
			
			# 1. 打断处理
			if effect.is_interrupt:
				if battle_manager != null and battle_manager.is_actor_casting(target):
					target_delta.is_interrupted = true
					preview.add_message("打断了吟唱。")
				else:
					preview.add_message("目标没有正在吟唱的技能。")

			# 2. 即时资源结算
			if effect.resource_type != ActionEffectData.ResourceType.NONE and not is_zero_approx(effect.value):
				var amount := _calculate_resource_amount(effect, caster, target, skill, battle_manager)
				match effect.resource_type:
					ActionEffectData.ResourceType.HP:
						target_delta.hp_delta += amount
						if amount < 0.0:
							total_applied_damage += absf(amount)
					ActionEffectData.ResourceType.MP:
						target_delta.mp_delta += amount
					ActionEffectData.ResourceType.FP:
						target_delta.fp_delta += amount
					ActionEffectData.ResourceType.SHIELD:
						target_delta.shield_delta += amount
						if amount > 0.0:
							preview.add_message("获得了 %.0f 点护盾。" % amount)

			# 3. 施加状态预览
			if effect.status_to_apply != null and battle_manager != null:
				var status := effect.status_to_apply
				match status.affected_stat:
					StatusEffectData.StatType.ATK:
						var base_atk := battle_manager.get_actor_stat(target, StatusEffectData.StatType.ATK)
						target_delta.atk_delta += FORMULAS.status_effect_delta(base_atk, status)
					StatusEffectData.StatType.DEF:
						var base_def := battle_manager.get_actor_stat(target, StatusEffectData.StatType.DEF)
						target_delta.def_delta += FORMULAS.status_effect_delta(base_def, status)
					StatusEffectData.StatType.SPD:
						var base_spd := battle_manager.get_actor_stat(target, StatusEffectData.StatType.SPD)
						target_delta.spd_delta += FORMULAS.status_effect_delta(base_spd, status)

		# 4. 自由动作处理
		if effect.is_free_action and caster != null:
			var caster_delta := preview.get_or_create_delta(caster)
			caster_delta.is_free_action = true

	if total_applied_damage > 0.0:
		preview.add_message("%s 造成了 %.0f 点伤害。" % [skill.display_name, total_applied_damage])


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
		var effect_targets: Array[Node] = []
		if effect.target == ActionEffectData.TargetType.SELF:
			if caster != null:
				effect_targets.append(caster)
		elif effect.target == ActionEffectData.TargetType.ALL:
			for t in targets:
				if t != null:
					effect_targets.append(t)
			if caster != null and not effect_targets.has(caster):
				effect_targets.append(caster)
		else:
			for t in targets:
				if t != null:
					effect_targets.append(t)
			
		for target in effect_targets:
			if target == null:
				continue
			var target_delta := preview.get_or_create_delta(target)

			# 1. 打断处理
			if effect.is_interrupt:
				if battle_manager != null and battle_manager.is_actor_casting(target):
					target_delta.is_interrupted = true
					preview.add_message("打断了吟唱。")
				else:
					preview.add_message("目标没有正在吟唱的技能。")

			# 2. 即时资源结算
			if effect.resource_type != ActionEffectData.ResourceType.NONE and not is_zero_approx(effect.value):
				var amount := _calculate_resource_amount(effect, caster, target, null, battle_manager)
				match effect.resource_type:
					ActionEffectData.ResourceType.HP:
						target_delta.hp_delta += amount
					ActionEffectData.ResourceType.MP:
						target_delta.mp_delta += amount
					ActionEffectData.ResourceType.FP:
						target_delta.fp_delta += amount
					ActionEffectData.ResourceType.SHIELD:
						target_delta.shield_delta += amount
						if amount > 0.0:
							preview.add_message("获得了 %.0f 点护盾。" % amount)

			# 3. 施加状态预览
			if effect.status_to_apply != null and battle_manager != null:
				var status := effect.status_to_apply
				match status.affected_stat:
					StatusEffectData.StatType.ATK:
						var base_atk := battle_manager.get_actor_stat(target, StatusEffectData.StatType.ATK)
						target_delta.atk_delta += FORMULAS.status_effect_delta(base_atk, status)
					StatusEffectData.StatType.DEF:
						var base_def := battle_manager.get_actor_stat(target, StatusEffectData.StatType.DEF)
						target_delta.def_delta += FORMULAS.status_effect_delta(base_def, status)
					StatusEffectData.StatType.SPD:
						var base_spd := battle_manager.get_actor_stat(target, StatusEffectData.StatType.SPD)
						target_delta.spd_delta += FORMULAS.status_effect_delta(base_spd, status)

		# 4. 自由动作处理
		if effect.is_free_action and caster != null:
			var caster_delta := preview.get_or_create_delta(caster)
			caster_delta.is_free_action = true

	return preview


static func _calculate_resource_amount(
	effect: ActionEffectData,
	caster: Node,
	target: Node,
	skill: SkillData,
	battle_manager: BattleManager
) -> float:
	match effect.calc_method:
		ActionEffectData.CalcMethod.FIXED_AMOUNT:
			return effect.value
		ActionEffectData.CalcMethod.MAX_RATIO:
			var max_res := 100.0
			match effect.resource_type:
				ActionEffectData.ResourceType.HP, ActionEffectData.ResourceType.SHIELD:
					max_res = target.get_max_hp() if target.has_method(&"get_max_hp") else 100.0
				ActionEffectData.ResourceType.MP:
					max_res = target.get_max_mp() if target.has_method(&"get_max_mp") else 100.0
				ActionEffectData.ResourceType.FP:
					max_res = target.get_max_fp() if target.has_method(&"get_max_fp") else 100.0
			return max_res * effect.value
		ActionEffectData.CalcMethod.SKILL_POWER:
			if battle_manager == null:
				return effect.value
			var caster_atk: float = battle_manager.get_actor_stat(caster, StatusEffectData.StatType.ATK)
			var target_def: float = battle_manager.get_actor_stat(target, StatusEffectData.StatType.DEF)
			var skill_type_int: int = skill.skill_type if skill != null else int(SkillData.SkillType.PHYSICAL)
			var skill_power_mod: float = battle_manager.get_skill_power_modifier(caster, skill_type_int)
			var damage: float = FORMULAS.calculate_skill_damage(caster_atk, effect.value * skill_power_mod, target_def)
			return -damage
	return 0.0
