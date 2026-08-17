@tool
class_name SkillTutor
extends StaticBody2D

enum DialogueMode {
	ALREADY_LEARNED,
	NORMAL_LEARN,
	FORGET_AND_LEARN,
}

@export_group("Identity")
@export var tutor_id: StringName = &""
@export var npc_name: String = "武艺导师"

@export_group("Skill Teaching")
@export var target_skill: SkillData
@export var conflict_skills: Array[SkillData] = []

@export_group("Dialogue Texts")
@export_multiline var normal_prompt: String = "我可以传授你独门技能，只要你愿意潜心修习。"
@export_multiline var conflict_prompt: String = "你所掌握的技艺与这门技能冲突！若想习得新技能，必须先遗忘原有的招式，你可愿意？"
@export_multiline var already_learned_prompt: String = "你已经掌握了这门技能的精髓，去实战中磨砺它吧。"

var _current_mode: DialogueMode = DialogueMode.NORMAL_LEARN
var _active_conflicts: Array[SkillData] = []


func get_persistent_id() -> String:
	if not tutor_id.is_empty():
		return String(tutor_id)
	return IdGenerator.generate_instance_id(self)


func interact(player: Player) -> void:
	if Engine.is_editor_hint() or player == null:
		return
	EventBus.npc_interaction_requested.emit(self, player)


func begin_interaction(ui: NpcInteractionUI, player: Player) -> void:
	if target_skill == null:
		ui.open_dialogue(npc_name, "（这位导师似乎还没有准备好要传授的技能...）")
		return

	# 1. 检查是否已经学会目标技能
	if player.has_skill(target_skill.id):
		_current_mode = DialogueMode.ALREADY_LEARNED
		ui.open_choices(
			npc_name,
			already_learned_prompt,
			[target_skill],
			["离开"],
			[target_skill.description],
			[false]
		)
		return

	# 2. 检查是否有冲突技能
	_active_conflicts.clear()
	for skill: SkillData in conflict_skills:
		if skill != null and player.has_skill(skill.id):
			_active_conflicts.append(skill)

	if not _active_conflicts.is_empty():
		# 分支 C：存在冲突技能，需要先遗忘
		_current_mode = DialogueMode.FORGET_AND_LEARN
		var conflict_names: Array[String] = []
		for skill in _active_conflicts:
			conflict_names.append("【%s】" % skill.display_name)
		
		var conflict_str := "、".join(conflict_names)
		var prompt := "%s\n（需遗忘：%s）" % [conflict_prompt, conflict_str]
		var learn_label := "遗忘 %s 并习得【%s】" % [conflict_str, target_skill.display_name]
		
		ui.open_choices(
			npc_name,
			prompt,
			[target_skill],
			[learn_label, "我再考虑一下"],
			[target_skill.description, ""],
			[false, false]
		)
	else:
		# 分支 B：无冲突技能，直接学习
		_current_mode = DialogueMode.NORMAL_LEARN
		var learn_label := "学习【%s】" % target_skill.display_name
		ui.open_choices(
			npc_name,
			normal_prompt,
			[target_skill],
			[learn_label, "稍后再说"],
			[target_skill.description, ""],
			[false, false]
		)


func handle_dialogue_option(index: int, ui: NpcInteractionUI, player: Player) -> void:
	if index != 0:
		ui.close()
		return

	match _current_mode:
		DialogueMode.ALREADY_LEARNED:
			ui.close()

		DialogueMode.NORMAL_LEARN:
			if target_skill != null:
				player.learn_skill(target_skill)
				ui.show_transaction_result(true, "领悟了新技能：【%s】！" % target_skill.display_name)
				_current_mode = DialogueMode.ALREADY_LEARNED
				ui.open_choices(
					npc_name,
					already_learned_prompt,
					[target_skill],
					["离开"],
					[target_skill.description],
					[false]
				)

		DialogueMode.FORGET_AND_LEARN:
			var forgotten_names: Array[String] = []
			for skill: SkillData in _active_conflicts:
				player.forget_skill(skill.id)
				forgotten_names.append("【%s】" % skill.display_name)

			if target_skill != null:
				player.learn_skill(target_skill)

			var forgotten_str := "、".join(forgotten_names)
			var msg := "遗忘了 %s，成功习得了【%s】！" % [forgotten_str, target_skill.display_name]
			ui.show_transaction_result(true, msg)
			_current_mode = DialogueMode.ALREADY_LEARNED
			ui.open_choices(
				npc_name,
				already_learned_prompt,
				[target_skill],
				["离开"],
				[target_skill.description],
				[false]
			)


func handle_dialogue_option_focused(_index: int, _ui: NpcInteractionUI, _player: Player) -> void:
	pass
