extends BaseTutorial

enum Step {
	INIT,
	WAIT_FOR_MENU,
	WAIT_FOR_FOCUS,
	WAIT_FOR_USE,
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
	_ui.show_prompt("你获得了【HP恢复药水】！请按 ESC 键打开背包。", false)


func handle_event(event_name: StringName, event_data: Variant) -> void:
	match current_step:
		Step.WAIT_FOR_MENU:
			if event_name == &"menu_opened":
				current_step = Step.WAIT_FOR_FOCUS
				_ui.show_prompt("请将焦点移动到药水上。", false)
		
		Step.WAIT_FOR_FOCUS:
			if event_name == &"item_focused":
				var item: ItemData = event_data as ItemData
				if item != null and item.id == &"hp_recovery_lv1":
					current_step = Step.WAIT_FOR_USE
					_ui.show_prompt("按下确认键即可在背包中使用该药水恢复生命。", false)
			elif event_name == &"menu_closed":
				_ui.hide_prompt()
				complete()
					
		Step.WAIT_FOR_USE:
			if event_name == &"item_selected" or event_name == &"menu_closed":
				_ui.hide_prompt()
				complete()
