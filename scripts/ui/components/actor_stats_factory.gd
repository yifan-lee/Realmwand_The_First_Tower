class_name ActorStatsFactory
extends RefCounted

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")


static func create_view_data(
	actor: Node,
	_profile: ActorStatsDisplayProfile = null,
	context: ActorStatsContext = null,
	preview: ActorStatsPreviewData = null
) -> ActorStatsViewData:
	if actor == null:
		return null

	var view := ActorStatsViewData.new()

	if actor is Player:
		var player := actor as Player
		if player.player_data != null:
			view.display_name = player.player_data.display_name
		view.portrait = player.get_ui_portrait()
		view.description = ""
		view.level = player.level
		view.experience = player.experience
		view.experience_to_next_level = player.get_experience_for_next_level()
		view.current_hp = player.current_hp
		view.current_shield = player.current_shield
		view.max_hp = player.get_max_hp()
		view.current_mp = player.current_mp
		view.max_mp = player.get_max_mp()
		view.current_fp = player.current_fp
		view.max_fp = player.get_max_fp()
		view.start_fp = player.get_start_fp()
		view.fp_recovery_spd = player.get_fp_recovery_spd()
		view.atk = player.get_atk()
		view.def = player.get_def()
		view.spd = player.get_spd()
		view.cp = 0.0
	elif actor is Enemy:
		var enemy := actor as Enemy
		if enemy.enemy_data != null:
			view.display_name = enemy.enemy_data.display_name
			view.description = enemy.enemy_data.description
			view.portrait = enemy.enemy_data.portrait
			view.start_fp = enemy.enemy_data.start_fp
		view.level = 0
		view.experience = 0
		view.experience_to_next_level = 0
		view.current_hp = enemy.current_hp
		view.current_shield = enemy.current_shield
		view.max_hp = enemy.get_max_hp()
		view.current_mp = enemy.current_mp
		view.max_mp = enemy.get_max_mp()
		view.current_fp = enemy.current_fp
		view.max_fp = enemy.get_max_fp()
		view.fp_recovery_spd = enemy.get_fp_recovery_spd()
		view.atk = enemy.get_atk()
		view.def = enemy.get_def()
		view.spd = enemy.get_spd()
		view.cp = enemy.get_cp()
	else:
		view.display_name = actor.name

	# Apply Context (Battle / Runtime Overrides)
	if context != null:
		view.current_atb = context.current_atb
		view.max_atb = context.max_atb
		if context.has_override_atk():
			view.atk = context.effective_atk
		if context.has_override_def():
			view.def = context.effective_def
		if context.has_override_spd():
			view.spd = context.effective_spd
		view.active_effects = context.active_effects.duplicate()
	else:
		view.current_atb = 0.0
		view.max_atb = FORMULAS.ATB_MAX
		view.active_effects = []

	# Apply Preview Deltas (only when preview has actual changes)
	if preview != null and preview.has_any_preview():
		view.current_hp_delta = preview.current_hp_delta
		view.current_shield_delta = preview.current_shield_delta
		view.current_mp_delta = preview.current_mp_delta
		view.current_fp_delta = preview.current_fp_delta
		view.current_atb_delta = preview.current_atb_delta
		view.max_hp_delta = preview.max_hp_delta
		view.max_mp_delta = preview.max_mp_delta
		view.max_fp_delta = preview.max_fp_delta
		view.start_fp_delta = preview.start_fp_delta
		view.atk_delta = preview.atk_delta
		view.def_delta = preview.def_delta
		view.spd_delta = preview.spd_delta
		view.fp_recovery_spd_delta = preview.fp_recovery_spd_delta
		view.cp_delta = preview.cp_delta

	return view


static func create_preview_from_equipment(
	player: Player,
	equipment: EquipmentData,
	target_slot: int = -1
) -> ActorStatsPreviewData:
	if player == null or equipment == null or player.equipment == null:
		return null
	var slot := target_slot
	if slot < 0:
		var compatible := player.equipment.get_compatible_slots(equipment)
		slot = compatible[0] if not compatible.is_empty() else -1
	if slot < 0:
		return null
	var displaced: Array[EquipmentData] = player.equipment.get_displaced_items(equipment, slot)
	var delta: Dictionary[StringName, float] = FORMULAS.equipment_delta(equipment, displaced)
	var preview := ActorStatsPreviewData.new()
	preview.max_hp_delta = delta.get(&"max_hp", 0.0)
	preview.max_mp_delta = delta.get(&"max_mp", 0.0)
	preview.atk_delta = delta.get(&"atk", 0.0)
	preview.def_delta = delta.get(&"def", 0.0)
	preview.spd_delta = delta.get(&"spd", 0.0)
	return preview


static func create_preview_from_item(
	player: Player,
	item: ItemData
) -> ActorStatsPreviewData:
	if player == null or item == null:
		return null
	if item is EquipmentData:
		return create_preview_from_equipment(player, item as EquipmentData)
	var preview := ActorStatsPreviewData.new()
	var hp_rec := 0.0
	var mp_rec := 0.0
	var fp_rec := 0.0
	for effect: ActionEffectData in item.effects:
		if effect.resource_type == ActionEffectData.ResourceType.HP and effect.value > 0:
			hp_rec += effect.value if effect.calc_method == ActionEffectData.CalcMethod.FIXED_AMOUNT else (player.get_max_hp() * effect.value)
		elif effect.resource_type == ActionEffectData.ResourceType.MP and effect.value > 0:
			mp_rec += effect.value if effect.calc_method == ActionEffectData.CalcMethod.FIXED_AMOUNT else (player.get_max_mp() * effect.value)
		elif effect.resource_type == ActionEffectData.ResourceType.FP and effect.value > 0:
			fp_rec += effect.value if effect.calc_method == ActionEffectData.CalcMethod.FIXED_AMOUNT else (player.get_max_fp() * effect.value)
	preview.current_hp_delta = FORMULAS.calculate_recovery_delta(player.current_hp, player.get_max_hp(), hp_rec)
	preview.current_mp_delta = FORMULAS.calculate_recovery_delta(player.current_mp, player.get_max_mp(), mp_rec)
	preview.current_fp_delta = FORMULAS.calculate_recovery_delta(player.current_fp, player.get_max_fp(), fp_rec)
	return preview


static func create_preview_from_skill(
	actor: Node,
	skill: SkillData
) -> ActorStatsPreviewData:
	if actor == null or skill == null:
		return null
	var preview := ActorStatsPreviewData.new()
	var base_atk := float(actor.get_atk()) if actor.has_method("get_atk") else 0.0
	var base_def := float(actor.get_def()) if actor.has_method("get_def") else 0.0
	var base_spd := float(actor.get_spd()) if actor.has_method("get_spd") else 0.0
	for effect: ActionEffectData in skill.effects:
		if effect.status_to_apply != null:
			var status := effect.status_to_apply
			match status.affected_stat:
				StatusEffectData.StatType.ATK:
					preview.atk_delta += FORMULAS.status_effect_delta(base_atk, status)
				StatusEffectData.StatType.DEF:
					preview.def_delta += FORMULAS.status_effect_delta(base_def, status)
				StatusEffectData.StatType.SPD:
					preview.spd_delta += FORMULAS.status_effect_delta(base_spd, status)
	return preview


static func create_preview_from_permanent_increase(
	player: Player,
	stat_id: StringName,
	amount: float
) -> ActorStatsPreviewData:
	if player == null or stat_id.is_empty() or is_zero_approx(amount):
		return null
	var preview_dict := player.get_permanent_stat_increase_preview(stat_id, amount)
	var preview := ActorStatsPreviewData.new()
	preview.current_hp_delta = preview_dict.get(&"current_hp", player.current_hp) - player.current_hp
	preview.max_hp_delta = preview_dict.get(&"max_hp", player.get_max_hp()) - player.get_max_hp()
	preview.current_mp_delta = preview_dict.get(&"current_mp", player.current_mp) - player.current_mp
	preview.max_mp_delta = preview_dict.get(&"max_mp", player.get_max_mp()) - player.get_max_mp()
	preview.atk_delta = preview_dict.get(&"atk", player.get_atk()) - player.get_atk()
	preview.def_delta = preview_dict.get(&"def", player.get_def()) - player.get_def()
	preview.spd_delta = preview_dict.get(&"spd", player.get_spd()) - player.get_spd()
	preview.fp_recovery_spd_delta = preview_dict.get(&"fp_recovery", player.get_fp_recovery_spd()) - player.get_fp_recovery_spd()
	return preview


static func create_preview_from_entry(
	actor: Node,
	entry: Variant,
	extra_param: Variant = null
) -> ActorStatsPreviewData:
	if entry == null or actor == null:
		return null
	if entry is ActorStatsPreviewData:
		var p_data := entry as ActorStatsPreviewData
		return p_data if p_data.has_any_preview() else null
	if entry is EquipmentData and actor is Player:
		var slot := int(extra_param) if extra_param is int else -1
		return create_preview_from_equipment(actor as Player, entry as EquipmentData, slot)
	if entry is ItemData and actor is Player:
		return create_preview_from_item(actor as Player, entry as ItemData)
	if entry is SkillData:
		return create_preview_from_skill(actor, entry as SkillData)
	return null
