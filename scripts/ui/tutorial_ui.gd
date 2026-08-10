class_name TutorialUI
extends CanvasLayer


@onready var tutorial_root: Control = (
	$TutorialRoot
)

@onready var message_label: Label = (
	$TutorialRoot/CenterContainer/Panel/Margin/Content/MessageLabel
)


func show_prompt(message: String) -> void:
	message_label.text = message
	tutorial_root.visible = true


func hide_prompt() -> void:
	tutorial_root.visible = false