class_name GameMessagePanel
extends PanelContainer

@onready var message_label: Label = %MessageLabel

@export_range(0.0, 30.0, 0.1) var message_display_seconds := 3.0

var _message_token := 0


func show_message(message: String) -> void:
	_message_token += 1
	message_label.text = message
	visible = not message.is_empty()
	if message.is_empty() or is_zero_approx(message_display_seconds):
		return
	get_tree().create_timer(message_display_seconds).timeout.connect(
		_hide_message_if_current.bind(_message_token),
		CONNECT_ONE_SHOT
	)


func clear_message() -> void:
	_message_token += 1
	message_label.text = ""
	visible = false


func _hide_message_if_current(token: int) -> void:
	if token == _message_token:
		clear_message()
