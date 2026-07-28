class_name SkillPreviewBuilder
extends RefCounted


static func build(
	skill: SkillData,
	player: Player,
	enemy: EnemyData = null,
	balance: BattleBalanceConfig = null
) -> Dictionary:
	var player_preview := CombatantPreviewData.new()
	var enemy_preview := CombatantPreviewData.new()

	player_preview.mp_delta = -skill.mp_cost

	if (
		enemy != null
		and balance != null
		and skill.target_type == SkillData.TargetType.ENEMY
	):
		enemy_preview.hp_delta = -balance.calculate_damage(
			player.total_atk,
			enemy.def,
			skill.skill_power
		)

	for effect in skill.effects:
		var target_preview := enemy_preview

		if (
			effect.target_type
			== SkillEffectData.TargetType.SELF
		):
			target_preview = player_preview

		match effect.effect_type:
			SkillEffectData.EffectType.ATK:
				target_preview.atk_delta += effect.value
			SkillEffectData.EffectType.DEF:
				target_preview.def_delta += effect.value
			SkillEffectData.EffectType.SPD:
				target_preview.spd_delta += effect.value

	return {
		"player": player_preview,
		"enemy": enemy_preview,
	}
