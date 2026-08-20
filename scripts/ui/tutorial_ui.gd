class_name TutorialUI
extends CanvasLayer

signal confirmed

@onready var tutorial_root: Control = $TutorialRoot
@onready var prompt_container: Control = $TutorialRoot/CenterContainer
@onready var message_label: Label = $TutorialRoot/CenterContainer/Panel/Margin/Content/MessageLabel

@onready var _default_anchor_left: float = prompt_container.anchor_left
@onready var _default_anchor_top: float = prompt_container.anchor_top
@onready var _default_anchor_right: float = prompt_container.anchor_right
@onready var _default_anchor_bottom: float = prompt_container.anchor_bottom
@onready var _default_offset_left: float = prompt_container.offset_left
@onready var _default_offset_top: float = prompt_container.offset_top
@onready var _default_offset_right: float = prompt_container.offset_right
@onready var _default_offset_bottom: float = prompt_container.offset_bottom

@export var target_vertical_gap: float = 16.0

var _wait_for_confirmation: bool = false
var _input_gate = preload("res://scripts/ui/components/ui_input_gate.gd").new()


func show_prompt(
	message: String,
	wait_for_confirmation: bool = false
) -> void:
	_input_gate.reset_gate()
	_restore_default_position()
	message_label.text = message
	_wait_for_confirmation = wait_for_confirmation
	tutorial_root.visible = true


func hide_prompt() -> void:
	_wait_for_confirmation = false
	tutorial_root.visible = false


func show_prompt_at(
	message: String,
	target_control: Control,
	wait_for_confirmation: bool = false
) -> void:
	show_prompt(message, wait_for_confirmation)
	if target_control == null:
		return

	_position_near_target(target_control)


func _restore_default_position() -> void:
	prompt_container.anchor_left = _default_anchor_left
	prompt_container.anchor_top = _default_anchor_top
	prompt_container.anchor_right = _default_anchor_right
	prompt_container.anchor_bottom = _default_anchor_bottom
	prompt_container.offset_left = _default_offset_left
	prompt_container.offset_top = _default_offset_top
	prompt_container.offset_right = _default_offset_right
	prompt_container.offset_bottom = _default_offset_bottom


func _position_near_target(target_control: Control) -> void:
	var target_transform := target_control.get_global_transform_with_canvas()
	var target_bottom := target_transform * Vector2(
		target_control.size.x * 0.5,
		target_control.size.y
	)
	var tutorial_transform := tutorial_root.get_global_transform_with_canvas()
	var target_position := tutorial_transform.affine_inverse() * target_bottom

	prompt_container.anchor_left = 0.0
	prompt_container.anchor_top = 0.0
	prompt_container.anchor_right = 0.0
	prompt_container.anchor_bottom = 0.0

	var desired_position := target_position + Vector2(
		-prompt_container.size.x * 0.5,
		target_vertical_gap
	)
	var viewport_size := get_viewport().get_visible_rect().size
	desired_position.x = clampf(
		desired_position.x,
		0.0,
		maxf(0.0, viewport_size.x - prompt_container.size.x)
	)
	desired_position.y = clampf(
		desired_position.y,
		0.0,
		maxf(0.0, viewport_size.y - prompt_container.size.y)
	)
	prompt_container.position = desired_position


func _input(event: InputEvent) -> void:
	if not tutorial_root.visible:
		return

	if not _wait_for_confirmation:
		return

	if not _input_gate.filter_event(event):
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(&"ui_accept"):
		get_viewport().set_input_as_handled()
		_wait_for_confirmation = false
		confirmed.emit()
