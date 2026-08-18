class_name IntroVideo
extends CanvasLayer


signal intro_finished


@onready var intro_root: Control = (
	$IntroRoot
)

@onready var video_player: VideoStreamPlayer = (
	$IntroRoot/VideoStreamPlayer
)


func _ready() -> void:
	video_player.finished.connect(
		_on_video_finished
	)
	intro_root.visible = false


func play_intro() -> void:
	intro_root.visible = true
	video_player.play()


func _on_video_finished() -> void:
	_finish_intro()

func _unhandled_input(event: InputEvent) -> void:
	if not intro_root.visible:
		return

	if (
		event.is_action_pressed(&"ui_accept")
		or event.is_action_pressed(&"toggle_menu")
	):
		_finish_intro()
		get_viewport().set_input_as_handled()


func _finish_intro() -> void:
	if not intro_root.visible:
		return

	video_player.stop()
	intro_root.visible = false
	intro_finished.emit()

func is_playing_intro() -> bool:
	return visible and intro_root != null and intro_root.visible
