extends BaseTutorial

enum Step {
	INIT,
	SHOW_PROMPT,
	FINISH
}

var current_step: Step = Step.INIT

func _init() -> void:
	tutorial_id = &"cast_time_tutorial"

func should_trigger(event_name: StringName, _event_data: Variant) -> bool:
	if event_name == &"player_turn_started":
		if _manager._player != null:
			for skill: SkillData in _manager._player.learned_skills:
				if skill.id == &"data_attack":
					return true
	return false

func start() -> void:
	current_step = Step.SHOW_PROMPT
	
	if _manager._battle_manager != null:
		_manager._battle_manager.pause_battle()
		
	var battle_ui: BattleUI = null
	if _manager._battle_manager != null:
		battle_ui = _manager._battle_manager._battle_ui
		
	var target: Control = null
	if battle_ui != null and battle_ui.skill_panel != null:
		target = battle_ui.skill_panel.get_skill_row(&"data_attack")
		if target != null:
			target.grab_focus()
		
	_ui.show_prompt_at("【数据攻击】是一个带有“吟唱时间”的技能。\n点击施放后它不会立刻生效，而是在ATB条退后一段距离后重新读条，等读条到达终点时才会真正打出伤害。\n吟唱期间会被具有打断效果的技能打断！\n\n[color=#8EA3AA]按确认键继续[/color]", target, true)
	if not _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.connect(_on_ui_confirmed)

func handle_event(_event_name: StringName, _event_data: Variant) -> void:
	pass

func _on_ui_confirmed() -> void:
	match current_step:
		Step.SHOW_PROMPT:
			current_step = Step.FINISH
			if _ui.confirmed.is_connected(_on_ui_confirmed):
				_ui.confirmed.disconnect(_on_ui_confirmed)
			
			_ui.hide_prompt()
			
			if _manager._battle_manager != null:
				_manager._battle_manager.resume_battle()
			
			complete()
