extends BaseTutorial

enum Step {
	INIT,
	SHOW_FP,
	SHOW_SKILL,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"fp_skill_tutorial"


func should_trigger(event_name: StringName, _event_data: Variant) -> bool:
	if event_name == &"battle_started":
		if _manager._player != null:
			for skill: SkillData in _manager._player.learned_skills:
				if skill.id == &"hard_attack":
					return true
	return false


func start() -> void:
	current_step = Step.SHOW_FP
	
	if _manager._battle_manager != null:
		_manager._battle_manager.pause_battle()
	
	if _manager._feature_unlock_state != null:
		_manager._feature_unlock_state.unlock(&"fp")
		
	var battle_ui: BattleUI = null
	if _manager._battle_manager != null:
		battle_ui = _manager._battle_manager._battle_ui
		
	var target: Control = null
	if battle_ui != null and battle_ui.player_stats != null:
		target = battle_ui.player_stats.fp_row
		
	_ui.show_prompt_at("这是你的 FP（专注），你会随着战斗的进行越来越专注，战斗结束之后会清零。\n部分技能会消耗 FP。现在你已经学会了需要 FP 的技能。", target, true)
	if not _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.connect(_on_ui_confirmed)


func handle_event(_event_name: StringName, _event_data: Variant) -> void:
	pass


func _on_ui_confirmed() -> void:
	var battle_ui: BattleUI = null
	if _manager._battle_manager != null:
		battle_ui = _manager._battle_manager._battle_ui

	match current_step:
		Step.SHOW_FP:
			current_step = Step.SHOW_SKILL
			var target: Control = null
			if battle_ui != null and battle_ui.skill_panel != null:
				target = battle_ui.skill_panel.get_skill_row(&"hard_attack")
			
			_ui.show_prompt_at("【强力攻击】技能伤害很高，但会消耗 FP。", target, true)
			
		Step.SHOW_SKILL:
			current_step = Step.FINISH
			if _ui.confirmed.is_connected(_on_ui_confirmed):
				_ui.confirmed.disconnect(_on_ui_confirmed)
			
			_ui.hide_prompt()
			
			if _manager._battle_manager != null:
				_manager._battle_manager.resume_battle()
			
			complete()
