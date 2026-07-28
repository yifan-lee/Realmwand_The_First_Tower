class_name SkillMenu
extends PanelContainer

signal skill_selected(skill: SkillData)
signal cancelled
signal skill_focused(skill: SkillData)

@onready var skill_list: VBoxContainer = (
	$MarginContainer/Content/SkillScroll/SkillList
)

@onready var cancel_button: Button = (
	$MarginContainer/Content/CancelButton
)


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_button_pressed)


func open(
	skills: Array[SkillData],
	current_mp: float,
	cooldowns: Dictionary
) -> void:
	_clear_skill_buttons()

	var first_available_button: Button = null

	for skill in skills:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 24.0)
		button.add_theme_font_size_override("font_size", 10)
		var remaining_cd := float(
			cooldowns.get(skill.id, 0.0)
		)

		button.text = _get_skill_button_text(
			skill,
			remaining_cd
		)

		button.disabled = (
			current_mp < skill.mp_cost
			or remaining_cd > 0.0
		)

		button.pressed.connect(
			_on_skill_button_pressed.bind(skill)
		)
		button.focus_entered.connect(
			_on_skill_button_focused.bind(skill)
		)

		button.mouse_entered.connect(
			_on_skill_button_focused.bind(skill)
		)

		skill_list.add_child(button)

		if first_available_button == null and not button.disabled:
			first_available_button = button

	visible = true

	if first_available_button != null:
		first_available_button.call_deferred("grab_focus")
	else:
		cancel_button.call_deferred("grab_focus")


func close() -> void:
	visible = false


func _clear_skill_buttons() -> void:
	for child in skill_list.get_children():
		skill_list.remove_child(child)
		child.queue_free()


func _get_skill_button_text(
	skill: SkillData,
	remaining_cd: float
) -> String:
	if remaining_cd > 0:
		return "%s  MP:%d  CD:%.1fs" % [
			skill.display_name,
			skill.mp_cost,
			remaining_cd,
		]

	return "%s  MP:%d" % [
		skill.display_name,
		skill.mp_cost,
	]


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
