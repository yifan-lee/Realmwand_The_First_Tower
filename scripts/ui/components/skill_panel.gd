class_name SkillPanel
extends PanelContainer

signal skill_selected(skill: SkillData)

@export var row_scene: PackedScene

@onready var skill_rows: VBoxContainer = (
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
		row.setup(
			skill,
			_build_row_text(skill),
			skill.icon,
			skill.description
		)
		row.entry_selected.connect(
			_on_entry_selected
		)


func _build_row_text(skill: SkillData) -> String:
	var details: Array[String] = []

	if skill.mp_cost > 0.0:
		details.append(
			"MP %.0f" % skill.mp_cost
		)

	if skill.cooldown_seconds > 0.0:
		details.append(
			"%.1fs" % skill.cooldown_seconds
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
