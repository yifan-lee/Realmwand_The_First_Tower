class_name BaseTutorial
extends Node

signal tutorial_completed(tutorial_id: StringName)

var tutorial_id: StringName = &"base_tutorial"
var _manager # type: TutorialManager
var _ui: TutorialUI


func setup(manager, ui: TutorialUI) -> void:
	_manager = manager
	_ui = ui


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	return false


func start() -> void:
	pass


func handle_event(event_name: StringName, event_data: Variant) -> void:
	pass


func complete() -> void:
	if _ui != null:
		_ui.hide_prompt()
	tutorial_completed.emit(tutorial_id)
