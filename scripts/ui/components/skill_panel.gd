class_name SkillPanel
extends PanelContainer

signal skill_selected(skill: SkillData)
signal skill_focused(skill: SkillData)

@export var row_scene: PackedScene

@onready var skill_rows: VBoxContainer = (
	$MarginContainer/Content/SkillScroll/SkillRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _skills: Array[SkillData] = []
var _rows: Array[SelectableListRow] = []


func display_skills(
	skills: Array[SkillData]
) -> void:
	_skills = skills.duplicate()
	refresh()


func clear_skills() -> void:
	_skills.clear()
	refresh()


func refresh() -> void:
	_rows.clear()
	for child: Node in skill_rows.get_children():
		skill_rows.remove_child(child)
		child.queue_free()

	_skills.sort_custom(_sort_skills)
	empty_label.visible = _skills.is_empty()

	for skill: SkillData in _skills:
		var row: SelectableListRow = (
			row_scene.instantiate()
			as SelectableListRow
		)

		if row == null:
			push_error(
				"SkillPanel row_scene has an invalid root."
			)
			return

		skill_rows.add_child(row)
		_rows.append(row)
		row.setup(
			skill,
			_build_row_text(skill),
			skill.icon,
			skill.description
		)
		row.entry_selected.connect(
			_on_entry_selected
		)
		row.entry_focused.connect(
			_on_entry_focused
		)

func update_availability(usability_check: Callable) -> void:
	for i in range(_skills.size()):
		if i < _rows.size():
			var skill: SkillData = _skills[i]
			_rows[i].disabled = not usability_check.call(skill)


func focus_first_skill() -> bool:
	if _rows.is_empty():
		return false
	_rows.front().grab_focus()
	return true


func is_first_skill_focused() -> bool:
	return (
		not _rows.is_empty()
		and get_viewport().gui_get_focus_owner() == _rows.front()
	)


func has_skill_focus(focus: Control = null) -> bool:
	var resolved_focus := focus
	if resolved_focus == null:
		resolved_focus = get_viewport().gui_get_focus_owner()
	return _focused_row_index(resolved_focus) >= 0


func navigate_skill_focus(direction: int) -> bool:
	var current_index := _focused_row_index(
		get_viewport().gui_get_focus_owner()
	)
	if current_index < 0:
		return false
	var next_index := clampi(
		current_index + direction,
		0,
		_rows.size() - 1
	)
	_rows[next_index].grab_focus()
	return true


func _focused_row_index(focus: Control) -> int:
	for index: int in _rows.size():
		if focus == _rows[index]:
			return index
	return -1


func _build_row_text(skill: SkillData) -> String:
	return skill.display_name


func _sort_skills(
	left: SkillData,
	right: SkillData
) -> bool:
	if left.unlock_level == right.unlock_level:
		return left.display_name < right.display_name

	return left.unlock_level < right.unlock_level


func _on_entry_selected(entry: Resource) -> void:
	var skill: SkillData = entry as SkillData

	if skill != null:
		skill_selected.emit(skill)


func _on_entry_focused(entry: Resource) -> void:
	var skill: SkillData = entry as SkillData
	if skill != null:
		skill_focused.emit(skill)
