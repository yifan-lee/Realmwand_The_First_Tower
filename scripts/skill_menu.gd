class_name SkillMenu
extends PanelContainer

signal skill_selected(skill: SkillData)
signal cancelled
signal skill_focused(skill: SkillData)
signal skill_focus_cleared

@onready var skill_list: VBoxContainer = (
	$MarginContainer/Content/SkillScroll/SkillList
)

@onready var cancel_button: Button = (
	$MarginContainer/Content/CancelButton
)

var first_available_button: Button
var first_skill_button: Button
var hovered_skill_button: Button


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_button_pressed)


func open(
	skills: Array[SkillData],
	current_mp: float,
	cooldowns: Dictionary,
	focus_first_skill: bool = true
) -> void:
	_clear_skill_buttons()

	first_available_button = null
	first_skill_button = null

	for skill in skills:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 72.0)
		button.add_theme_font_size_override("font_size", 30)
		var remaining_cd := float(
			cooldowns.get(skill.id, 0.0)
		)

		button.text = skill.display_name

		var is_unavailable := (
			current_mp < skill.mp_cost
			or remaining_cd > 0.0
		)

		if is_unavailable:
			var unavailable_color := Color(
				0.55,
				0.58,
				0.64,
				1.0
			)
			button.add_theme_color_override(
				"font_color",
				unavailable_color
			)
			button.add_theme_color_override(
				"font_focus_color",
				unavailable_color
			)

		button.pressed.connect(
			_on_skill_button_pressed.bind(skill)
		)
		button.focus_entered.connect(
			_on_skill_button_focused.bind(skill)
		)
		button.focus_exited.connect(
			_on_skill_button_focus_exited
		)

		button.mouse_entered.connect(
			_on_skill_button_mouse_entered.bind(
				button,
				skill
			)
		)
		button.mouse_exited.connect(
			_on_skill_button_mouse_exited.bind(button)
		)

		skill_list.add_child(button)

		if first_skill_button == null:
			first_skill_button = button

		if first_available_button == null and not is_unavailable:
			first_available_button = button

	visible = true

	if focus_first_skill:
		grab_first_skill_focus()


func grab_first_skill_focus() -> void:
	if is_instance_valid(first_available_button):
		first_available_button.call_deferred("grab_focus")
	elif is_instance_valid(first_skill_button):
		first_skill_button.call_deferred("grab_focus")
	else:
		cancel_button.call_deferred("grab_focus")


func close() -> void:
	hovered_skill_button = null
	visible = false
	skill_focus_cleared.emit()


func _clear_skill_buttons() -> void:
	hovered_skill_button = null

	for child in skill_list.get_children():
		skill_list.remove_child(child)
		child.queue_free()




func _on_skill_button_pressed(
	skill: SkillData
) -> void:
	skill_selected.emit(skill)


func _on_cancel_button_pressed() -> void:
	cancelled.emit()

func _on_skill_button_focused(
	skill: SkillData
) -> void:
	skill_focused.emit(skill)


func _on_skill_button_mouse_entered(
	button: Button,
	skill: SkillData
) -> void:
	hovered_skill_button = button
	skill_focused.emit(skill)


func _on_skill_button_mouse_exited(
	button: Button
) -> void:
	if hovered_skill_button == button:
		hovered_skill_button = null

	_queue_focus_clear_check()


func _on_skill_button_focus_exited() -> void:
	_queue_focus_clear_check()


func _queue_focus_clear_check() -> void:
	call_deferred("_emit_focus_cleared_if_needed")


func _emit_focus_cleared_if_needed() -> void:
	if hovered_skill_button != null:
		return

	var focus_owner := get_viewport().gui_get_focus_owner()

	if (
		focus_owner != null
		and skill_list.is_ancestor_of(focus_owner)
	):
		return

	skill_focus_cleared.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return

	var focus_owner := get_viewport().gui_get_focus_owner()

	if (
		focus_owner == null
		or not skill_list.is_ancestor_of(focus_owner)
	):
		return

	if (
		event.is_action_pressed("ui_cancel")
		or event.is_action_pressed("ui_left")
	):
		cancelled.emit()
		get_viewport().set_input_as_handled()
