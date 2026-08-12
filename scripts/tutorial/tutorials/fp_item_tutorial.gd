extends BaseTutorial

enum Step {
	INIT,
	WAIT_FOR_MENU,
	EXPLAIN_FREE_ACTION,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"fp_item_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"item_added" and event_data is ItemData:
		if event_data.id == &"fp_recovery_lv1":
			return true
	return false


func start() -> void:
	current_step = Step.WAIT_FOR_MENU
	
		
	_ui.show_prompt("你获得了FP恢复药水！请按 ESC 键打开背包查看。", true)


func handle_event(event_name: StringName, _event_data: Variant) -> void:
	match current_step:
		Step.WAIT_FOR_MENU:
			if event_name == &"menu_opened":
				current_step = Step.EXPLAIN_FREE_ACTION
				_ui.show_prompt("请注意，在战斗中使用FP恢复药水是不消耗回合的 Free Action！", true)
				if not _ui.confirmed.is_connected(_on_ui_confirmed):
					_ui.confirmed.connect(_on_ui_confirmed)


func _on_ui_confirmed() -> void:
	match current_step:
		Step.EXPLAIN_FREE_ACTION:
			current_step = Step.FINISH
			if _ui.confirmed.is_connected(_on_ui_confirmed):
				_ui.confirmed.disconnect(_on_ui_confirmed)
			_ui.hide_prompt()
			complete()
