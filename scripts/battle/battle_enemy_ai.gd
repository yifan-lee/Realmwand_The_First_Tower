class_name BattleEnemyAI
extends RefCounted


static func choose_skill(
	enemy: Enemy,
	battle_manager: BattleManager
) -> SkillData:
	if enemy == null or enemy.is_defeated:
		return null
		
	for skill: SkillData in enemy.enemy_data.skills:
		if skill == null or skill.is_passive():
			continue
		if battle_manager.get_skill_cooldown(skill.id, true) > 0:
			continue
			
		var hp_cost := _get_skill_cost(skill, ActionCostData.CostType.HP)
		var mp_cost := _get_skill_cost(skill, ActionCostData.CostType.MP)
		var fp_cost := _get_skill_cost(skill, ActionCostData.CostType.FP)
		
		if enemy.current_hp <= hp_cost:
			continue
		if enemy.current_mp < mp_cost:
			continue
		if enemy.current_fp < fp_cost:
			continue
		return skill
		
	return null


static func _get_skill_cost(skill: SkillData, type: ActionCostData.CostType) -> float:
	var total := 0.0
	for cost: ActionCostData in skill.costs:
		if cost.cost_type == type:
			total += cost.value
	return total
