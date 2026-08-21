class_name SkillLearnedTutorial
extends BaseTutorial

const EXCLUDED_SKILL_IDS: Array[StringName] = [
	&"kick_off", # Has dedicated interrupt_tutorial with custom rich text
]

var _current_skill: SkillData = null


func _init() -> void:
	tutorial_id = &"skill_learned_tutorial"


func should_trigger(event_name: StringName, event_data: Variant) -> bool:
	if event_name == &"skill_learned" and event_data is SkillData:
		var skill: SkillData = event_data as SkillData
		if skill.id in EXCLUDED_SKILL_IDS:
			return false
		var specific_id := StringName("skill_learned_" + String(skill.id))
		if _manager != null and specific_id in _manager.completed_tutorials:
			return false
		_current_skill = skill
		return true
	return false


func start() -> void:
	if _current_skill == null:
		complete()
		return
	
	_ui.show_prompt("学会技能【%s】，在菜单界面查看。" % _current_skill.display_name, true)
	if not _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.connect(_on_ui_confirmed)


func handle_event(_event_name: StringName, _event_data: Variant) -> void:
	pass


func _on_ui_confirmed() -> void:
	if _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.disconnect(_on_ui_confirmed)
	_ui.hide_prompt()
	
	if _manager != null and _current_skill != null:
		var specific_id := StringName("skill_learned_" + String(_current_skill.id))
		if not specific_id in _manager.completed_tutorials:
			_manager.completed_tutorials.append(specific_id)
	
	_current_skill = null
	complete()
