extends BaseTutorial

enum Step {
	INIT,
	WAITING_FOR_MENU,
	WAITING_FOR_FOCUS,
	WAITING_FOR_EQUIP
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"equipment_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"item_added":
		var item: ItemData = event_data as ItemData
		if item != null and item.item_type == ItemData.ItemType.EQUIPMENT:
			return true
	return false


func start() -> void:
	current_step = Step.WAITING_FOR_MENU
	_ui.show_prompt("获得了新装备！请按 ESC 键打开菜单。", false)


func handle_event(event_name: StringName, event_data: Variant) -> void:
	match current_step:
		Step.WAITING_FOR_MENU:
			if event_name == &"menu_opened":
				current_step = Step.WAITING_FOR_FOCUS
				_ui.show_prompt("请将焦点移动到新获得的装备上。", false)
		
		Step.WAITING_FOR_FOCUS:
			if event_name == &"item_focused":
				var item: ItemData = event_data as ItemData
				if item != null and item.item_type == ItemData.ItemType.EQUIPMENT:
					current_step = Step.WAITING_FOR_EQUIP
					_ui.show_prompt("按下确认键即可穿戴该装备。", false)
			elif event_name == &"menu_closed":
				_ui.hide_prompt()
				complete()
					
		Step.WAITING_FOR_EQUIP:
			if event_name == &"item_equipped" or event_name == &"item_selected" or event_name == &"menu_closed":
				complete()
