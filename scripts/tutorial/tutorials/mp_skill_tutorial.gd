extends BaseTutorial

enum Step {
	INIT,
	INTRO,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"mp_skill_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"skill_learned" and event_data is SkillData:
		if event_data.id == &"battle_focus":
			return true
	return false


func start() -> void:
	current_step = Step.INTRO
	
		
	if _manager._feature_unlock_state != null:
		_manager._feature_unlock_state.unlock(&"mp")
		
	var target: Control = null
	var game_hud: GameHUD = _manager.get_node_or_null("../../OverlayRoot/GameHUD")
	if game_hud != null and game_hud.actor_stats_panel != null:
		target = game_hud.actor_stats_panel.mp_row
		
	_ui.show_prompt_at("这是你的 MP (魔法点)，释放法术会消耗它。", target, true)
	if not _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.connect(_on_ui_confirmed)


func handle_event(_event_name: StringName, _event_data: Variant) -> void:
	pass


func _on_ui_confirmed() -> void:
	match current_step:
		Step.INTRO:
			current_step = Step.FINISH
			if _ui.confirmed.is_connected(_on_ui_confirmed):
				_ui.confirmed.disconnect(_on_ui_confirmed)
			_ui.hide_prompt()
			complete()
