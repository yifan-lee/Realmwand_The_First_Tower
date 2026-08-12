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
	_ui.show_prompt("获得了新装备！请按 ESC 键打开菜单。", true)


func handle_event(event_name: StringName, event_data: Variant) -> void:
	match current_step:
		Step.WAITING_FOR_MENU:
			if event_name == &"menu_opened":
				current_step = Step.WAITING_FOR_FOCUS
				_ui.show_prompt("请将鼠标移动或焦点移动到新获得的装备上。", true)
		
		Step.WAITING_FOR_FOCUS:
			if event_name == &"item_focused":
				var item: ItemData = event_data as ItemData
				if item != null and item.item_type == ItemData.ItemType.EQUIPMENT:
					current_step = Step.WAITING_FOR_EQUIP
					_ui.show_prompt("按下确认键即可穿戴该装备。", true)
					
		Step.WAITING_FOR_EQUIP:
			if event_name == &"item_equipped":
				_ui.show_prompt("穿戴成功！教程结束。", true)
				# 等待玩家按下确认键 (通过 tutorial_ui 的 confirmed 信号触发)
				if not _ui.confirmed.is_connected(_on_ui_confirmed):
					_ui.confirmed.connect(_on_ui_confirmed)


func _on_ui_confirmed() -> void:
	if _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.disconnect(_on_ui_confirmed)
	complete()
