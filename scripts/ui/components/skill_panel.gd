class_name SkillPanel
extends PanelContainer

enum Mode {
	LIST,
	SLOTS,
}

signal skill_selected(skill: SkillData)
signal skill_focused(skill: SkillData)
signal slot_selected(slot_index: int, skill: SkillData)
signal slot_focused(slot_index: int, skill: SkillData)

@export var row_scene: PackedScene

@onready var skill_rows: FocusableList = (
	$MarginContainer/Content/SkillScroll/SkillRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _mode: Mode = Mode.LIST
var _skills: Array[SkillData] = []
var _badges: Dictionary = {}
var _max_slots: int = 6
var _highlighted_index: int = -1
var _highlighted_skill_id: StringName = &""


func display_skills(
	skills: Array[SkillData],
	badges: Dictionary = {}
) -> void:
	_mode = Mode.LIST
	_skills = skills.duplicate()
	_badges = badges.duplicate()
	refresh()


func display_slots(
	slots: Array[SkillData],
	max_slots: int = 6
) -> void:
	_mode = Mode.SLOTS
	_max_slots = max_slots
	_skills.clear()
	for i in range(max_slots):
		if i < slots.size():
			_skills.append(slots[i])
		else:
			_skills.append(null)
	_badges.clear()
	refresh()


func clear_skills() -> void:
	_skills.clear()
	_badges.clear()
	refresh()


func set_empty_text(text: String) -> void:
	if empty_label != null:
		empty_label.text = text


func refresh() -> void:
	var focused_index := skill_rows.get_focused_row_index(get_viewport().gui_get_focus_owner())
	skill_rows.clear_rows()

	if _mode == Mode.LIST:
		empty_label.visible = _skills.is_empty()

		for i in range(_skills.size()):
			var skill: SkillData = _skills[i]
			if skill == null:
				continue
			var row: SelectableListRow = row_scene.instantiate() as SelectableListRow
			if row == null:
				push_error("SkillPanel row_scene has an invalid root.")
				return

			skill_rows.add_row(row)
			var trailing_text: String = _get_badge_text(skill)
			row.setup(
				skill,
				_build_row_text(skill),
				skill.icon,
				skill.description,
				false,
				trailing_text
			)
			row.entry_selected.connect(_on_row_selected.bind(i))
			row.entry_focused.connect(_on_row_focused.bind(i))
	else:
		empty_label.visible = false
		for i in range(_max_slots):
			var skill: SkillData = _skills[i] if i < _skills.size() else null
			var row: SelectableListRow = row_scene.instantiate() as SelectableListRow
			if row == null:
				push_error("SkillPanel row_scene has an invalid root.")
				return

			skill_rows.add_row(row)
			var row_text := ""
			var row_icon: Texture2D = null
			var row_tooltip := ""
			var trailing_text := ""

			if skill != null:
				row_text = "[槽位 %d] %s" % [i + 1, skill.display_name]
				row_icon = skill.icon
				row_tooltip = skill.description
			else:
				row_text = "[槽位 %d] <空槽位>" % [i + 1]
				row_tooltip = "未装备技能"
				row.modulate = Color(1.0, 1.0, 1.0, 0.6)

			row.setup(
				skill,
				row_text,
				row_icon,
				row_tooltip,
				false,
				trailing_text
			)
			row.entry_selected.connect(_on_row_selected.bind(i))
			row.entry_focused.connect(_on_row_focused.bind(i))

	_apply_highlights()

	if focused_index >= 0 and not skill_rows.is_empty():
		var target_index := clampi(focused_index, 0, skill_rows.get_rows().size() - 1)
		skill_rows.get_rows()[target_index].grab_focus()
	elif focused_index >= 0 and skill_rows.is_empty():
		get_viewport().gui_release_focus()


func set_highlighted_skill(skill_id: StringName) -> void:
	_highlighted_skill_id = skill_id
	_highlighted_index = -1
	_apply_highlights()


func set_highlighted_slot(slot_index: int) -> void:
	_highlighted_index = slot_index
	_highlighted_skill_id = &""
	_apply_highlights()


func clear_highlight() -> void:
	_highlighted_skill_id = &""
	_highlighted_index = -1
	_apply_highlights()


func _apply_highlights() -> void:
	var rows = skill_rows.get_rows()
	for i in range(rows.size()):
		var row = rows[i]
		var is_highlighted := false
		if _highlighted_index >= 0 and i == _highlighted_index:
			is_highlighted = true
		elif not _highlighted_skill_id.is_empty() and i < _skills.size() and _skills[i] != null:
			if _skills[i].id == _highlighted_skill_id:
				is_highlighted = true

		if is_highlighted:
			row.self_modulate = Color("#ffe066")
		else:
			row.self_modulate = Color(1.0, 1.0, 1.0, 1.0)


func update_availability(usability_check: Callable, cd_check: Callable = Callable()) -> void:
	var rows = skill_rows.get_rows()
	for i in range(_skills.size()):
		if i < rows.size():
			var skill: SkillData = _skills[i]
			if skill == null:
				continue
			var is_usable: bool = usability_check.call(skill)
			rows[i].disabled = false
			rows[i].modulate = Color(1.0, 1.0, 1.0, 1.0) if is_usable else Color(1.0, 1.0, 1.0, 0.5)
			var text = _build_row_text(skill)
			if not cd_check.is_null():
				var cd: int = cd_check.call(skill)
				if cd > 0:
					text += " (CD: %d)" % cd
			rows[i].text = text


func get_skill_row(skill_id: StringName) -> Control:
	var rows = skill_rows.get_rows()
	for i in range(_skills.size()):
		if _skills[i] != null and _skills[i].id == skill_id and i < rows.size():
			return rows[i]
	return null


func focus_first_row() -> bool:
	return skill_rows.focus_first_row()


func focus_row_at(index: int) -> bool:
	return skill_rows.focus_row_at(index)


func get_focused_row_index() -> int:
	return skill_rows.get_focused_row_index(get_viewport().gui_get_focus_owner())


func has_row_focus(focus: Control = null) -> bool:
	return skill_rows.has_row_focus(focus)


func get_rows() -> Array[Control]:
	return skill_rows.get_rows()


func _get_badge_text(skill: SkillData) -> String:
	if skill == null:
		return ""
	if _badges.has(skill.id):
		return String(_badges[skill.id])
	if _badges.has(skill):
		return String(_badges[skill])
	return ""


func _build_row_text(skill: SkillData) -> String:
	return skill.display_name


func _on_row_selected(entry: Resource, index: int) -> void:
	var skill: SkillData = entry as SkillData
	if _mode == Mode.SLOTS:
		slot_selected.emit(index, skill)
	else:
		if skill != null:
			skill_selected.emit(skill)


func _on_row_focused(entry: Resource, index: int) -> void:
	var skill: SkillData = entry as SkillData
	if _mode == Mode.SLOTS:
		slot_focused.emit(index, skill)
	else:
		if skill != null:
			skill_focused.emit(skill)

