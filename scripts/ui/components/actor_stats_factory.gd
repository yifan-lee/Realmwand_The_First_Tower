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

	# Apply Preview Deltas
	if preview != null:
		view.current_hp_delta = preview.current_hp_delta
		view.current_shield_delta = preview.current_shield_delta
		view.current_mp_delta = preview.current_mp_delta
		view.current_fp_delta = preview.current_fp_delta
		view.current_atb_delta = preview.current_atb_delta
		view.max_hp_delta = preview.max_hp_delta
		view.max_mp_delta = preview.max_mp_delta
		view.atk_delta = preview.atk_delta
		view.def_delta = preview.def_delta
		view.spd_delta = preview.spd_delta
		view.fp_recovery_spd_delta = preview.fp_recovery_spd_delta

	return view
