class_name GameMessagePanel
extends PanelContainer

@onready var message_label: Label = %MessageLabel


func show_message(message: String) -> void:
	message_label.text = message
	visible = not message.is_empty()


func clear_message() -> void:
	message_label.text = ""
	visible = false