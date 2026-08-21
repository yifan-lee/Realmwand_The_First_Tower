extends BaseTutorial

enum Step {
	INIT,
	INTRO,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"interrupt_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"skill_learned" and event_data is SkillData:
		if event_data.id == &"kick_off":
			return true
	return false


func start() -> void:
	current_step = Step.INTRO
	_ui.show_prompt("学会技能【打断】，[color=#ff4d4f]可以打断敌方的吟唱[/color]，在菜单界面查看。\n\n[color=#8EA3AA]按确认键继续[/color]", true)
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
