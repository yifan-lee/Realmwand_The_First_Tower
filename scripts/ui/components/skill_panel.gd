class_name SkillPanel
extends PanelContainer

signal skill_selected(skill: SkillData)
signal skill_focused(skill: SkillData)

@export var row_scene: PackedScene

@onready var skill_rows: FocusableList = (
	$MarginContainer/Content/SkillScroll/SkillRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _skills: Array[SkillData] = []


func display_skills(
	skills: Array[SkillData]
) -> void:
	_skills = skills.duplicate()
	refresh()


func clear_skills() -> void:
	_skills.clear()
	refresh()


func refresh() -> void:
	var focused_index := skill_rows.get_focused_row_index(get_viewport().gui_get_focus_owner())
	skill_rows.clear_rows()

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

		skill_rows.add_row(row)
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

	if focused_index >= 0 and not skill_rows.is_empty():
		var target_index := clampi(focused_index, 0, skill_rows.get_rows().size() - 1)
		skill_rows.get_rows()[target_index].grab_focus()
	elif focused_index >= 0 and skill_rows.is_empty():
		get_viewport().gui_release_focus()


func update_availability(usability_check: Callable, cd_check: Callable = Callable()) -> void:
	var rows = skill_rows.get_rows()
	for i in range(_skills.size()):
		if i < rows.size():
			var skill: SkillData = _skills[i]
			rows[i].disabled = not usability_check.call(skill)
			var text = _build_row_text(skill)
			if not cd_check.is_null():
				var cd = cd_check.call(skill)
				if cd > 0:
					text += " (CD: %d)" % cd
			rows[i].text = text


func get_skill_row(skill_id: StringName) -> Control:
	var rows = skill_rows.get_rows()
	for i in range(_skills.size()):
		if _skills[i].id == skill_id and i < rows.size():
			return rows[i]
	return null


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
