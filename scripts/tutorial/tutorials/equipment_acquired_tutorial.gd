class_name EquipmentAcquiredTutorial
extends BaseTutorial

var _current_item: ItemData = null


func _init() -> void:
	tutorial_id = &"equipment_acquired_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"item_added" and event_data is ItemData:
		var item: ItemData = event_data as ItemData
		if item != null and item.item_type == ItemData.ItemType.EQUIPMENT:
			# 仅在首次装备教程已完成后才触发后续单次通知
			if _manager != null and _manager.completed_tutorials.has(&"equipment_tutorial"):
				_current_item = item
				return true
	return false


func start() -> void:
	var item_name: String = _current_item.display_name if _current_item != null else "新装备"
	_ui.show_prompt("获得新装备【%s】！可在 ESC 菜单中查看并穿戴。\n\n[color=#8EA3AA]按确认键继续[/color]" % item_name, true)
	if not _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.connect(_on_ui_confirmed)


func _on_ui_confirmed() -> void:
	if _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.disconnect(_on_ui_confirmed)
	_ui.hide_prompt()
	complete()
