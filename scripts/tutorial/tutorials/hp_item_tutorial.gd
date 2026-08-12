extends BaseTutorial

enum Step {
	INIT,
	WAIT_FOR_MENU,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"hp_item_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"item_added" and event_data is ItemData:
		if event_data.id == &"hp_recovery_lv1":
			return true
	return false


func start() -> void:
	current_step = Step.WAIT_FOR_MENU
	
	if _manager._player != null:
		
	_ui.show_prompt("你获得了HP恢复药水！请按 ESC 键打开背包查看。", true)


func handle_event(event_name: StringName, _event_data: Variant) -> void:
	match current_step:
		Step.WAIT_FOR_MENU:
			if event_name == &"menu_opened":
				current_step = Step.FINISH
				_ui.hide_prompt()
				if _manager._player != null:
				complete()
