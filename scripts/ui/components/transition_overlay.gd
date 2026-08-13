class_name TransitionOverlay
extends ColorRect


func _ready() -> void:
	EventBus.screen_fade_out_started.connect(_on_screen_fade_out_started)
	EventBus.screen_fade_in_with_info_started.connect(_on_screen_fade_in_with_info_started)


func _on_screen_fade_out_started() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.finished.connect(func(): EventBus.screen_fade_out_finished.emit())


func _on_screen_fade_in_with_info_started(_floor_name: String, _floor_desc: String) -> void:
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_LINEAR)
