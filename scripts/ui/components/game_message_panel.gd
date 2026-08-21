class_name GameMessagePanel
extends PanelContainer

@onready var message_label: Label = %MessageLabel

@export_range(0.0, 30.0, 0.1) var message_display_seconds := 3.0

var _message_token := 0
var _tween: Tween = null


func _ready() -> void:
	EventBus.system_message_requested.connect(show_message)
	modulate.a = 0.0
	visible = false


func show_message(message: String) -> void:
	_message_token += 1
	var current_token := _message_token
	
	if _tween != null and _tween.is_valid():
		_tween.kill()
		
	if message.is_empty():
		clear_message()
		return

	message_label.text = message
	visible = true
	
	# Smooth fade-in
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	if is_zero_approx(message_display_seconds):
		return
		
	get_tree().create_timer(message_display_seconds).timeout.connect(
		_hide_message_if_current.bind(current_token),
		CONNECT_ONE_SHOT
	)


func clear_message() -> void:
	_message_token += 1
	if _tween != null and _tween.is_valid():
		_tween.kill()
	message_label.text = ""
	modulate.a = 0.0
	visible = false


func _hide_message_if_current(token: int) -> void:
	if token != _message_token:
		return
		
	if _tween != null and _tween.is_valid():
		_tween.kill()
		
	# Smooth fade-out
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_callback(func():
		if token == _message_token:
			visible = false
			message_label.text = ""
	)
