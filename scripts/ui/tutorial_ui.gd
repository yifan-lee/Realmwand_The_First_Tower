class_name TutorialUI
extends CanvasLayer

signal confirmed

@onready var tutorial_root: Control = $TutorialRoot

@onready var message_label: Label = $TutorialRoot/CenterContainer/Panel/Margin/Content/MessageLabel

var _wait_for_confirmation: bool = false


func show_prompt(
	message: String,
	wait_for_confirmation: bool = false
) -> void:
	message_label.text = message
	_wait_for_confirmation = wait_for_confirmation
	tutorial_root.visible = true


func hide_prompt() -> void:
	_wait_for_confirmation = false
	tutorial_root.visible = false
	var panel = $TutorialRoot/CenterContainer/Panel
	if panel:
		panel.top_level = false


func show_prompt_at(
	message: String,
	target_control: Control,
	wait_for_confirmation: bool = false
) -> void:
	show_prompt(message, wait_for_confirmation)
	
	if target_control != null:
		var panel = $TutorialRoot/CenterContainer/Panel
		if panel:
			panel.top_level = true
			# 简单地把提示框放在目标控件的右侧
			panel.global_position = target_control.global_position + Vector2(target_control.size.x + 20, 0)


func _input(event: InputEvent) -> void:
	if not tutorial_root.visible:
		return

	if not _wait_for_confirmation:
		return

	if event.is_action_pressed(&"ui_accept"):
		_wait_for_confirmation = false
		confirmed.emit()
		get_viewport().set_input_as_handled()
