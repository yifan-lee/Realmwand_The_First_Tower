extends BaseTutorial

enum Step {
	INIT,
	INTRO,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"fp_skill_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"skill_learned" and event_data is SkillData:
		if event_data.id == &"hard_attack":
			return true
	return false


func start() -> void:
	current_step = Step.INTRO
	
	if _manager._player != null:
		
	if _manager._feature_unlock_state != null:
		_manager._feature_unlock_state.unlock(&"fp")
		
	var target: Control = null
	var game_hud: GameHUD = _manager.get_node_or_null("../../OverlayRoot/GameHUD")
	if game_hud != null and game_hud.actor_stats_panel != null:
		target = game_hud.actor_stats_panel.fp_row
		
	_ui.show_prompt_at("这是你的 FP (战技点)，释放强力战技会消耗它。", target, true)
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
			if _manager._player != null:
			complete()
