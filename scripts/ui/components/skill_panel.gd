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


func focus_first_skill() -> bool:
	if _rows.is_empty():
		return false
	_rows.front().grab_focus()
	return true


func _build_row_text(skill: SkillData) -> String:
	var details: Array[String] = []

	if skill.fp_cost > 0.0:
		details.append(
			"专注 %.0f" % skill.fp_cost
		)

	if skill.mp_cost > 0.0:
		details.append(
			"魔力 %.0f" % skill.mp_cost
		)

	if skill.cooldown_seconds > 0.0:
		details.append(
			"%.1f秒" % skill.cooldown_seconds
		)

	if skill.cast_time > 0.0:
		details.append(
			"吟唱 %.0f%%" % (skill.cast_time * 100.0)
		)

	if details.is_empty():
		return skill.display_name

	return "%s  %s" % [
		skill.display_name,
		" / ".join(details),
	]


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
