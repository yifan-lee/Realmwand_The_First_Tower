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
			["📖 查看已掌握技能：【%s】（%s）" % [target_skill.display_name, target_skill.get_type_name()]],
			[_format_skill_detailed(target_skill, "【已掌握】")],
			[false]
		)
		ui.show_transaction_result(true, _format_skill_summary(target_skill, "【已掌握技能】"))
		return

	# 2. 检查是否有冲突技能
	_active_conflicts.clear()
	for skill: SkillData in conflict_skills:
		if skill != null and player.has_skill(skill.id):
			_active_conflicts.append(skill)

	if not _active_conflicts.is_empty():
		# 分支 C：存在冲突技能，明确列出冲突并提供预览
		_current_mode = DialogueMode.FORGET_AND_LEARN
		var conflict_names: Array[String] = []
		for skill in _active_conflicts:
			conflict_names.append("【%s】" % skill.display_name)
		
		var conflict_str := "、".join(conflict_names)
		var prompt := "%s\n【冲突技能（将遗忘）】：%s\n【将要习得】：【%s】\n可在下方预览各项技能详情并选择：" % [
			conflict_prompt,
			conflict_str,
			target_skill.display_name
		]
		
		var entries: Array[Resource] = [target_skill, target_skill]
		var labels: Array[String] = [
			"⚡ 确认传授：遗忘 %s 并习得【%s】" % [conflict_str, target_skill.display_name],
			"📖 预览新技能：【%s】（%s）" % [target_skill.display_name, target_skill.get_type_name()]
		]
		var tooltips: Array[String] = [
			"遗忘 %s，领悟【%s】\n\n%s" % [conflict_str, target_skill.display_name, _format_skill_detailed(target_skill, "【新技能】")],
			_format_skill_detailed(target_skill, "【将要习得】")
		]
		var disabled: Array[bool] = [false, false]
		
		for conflict_skill: SkillData in _active_conflicts:
			entries.append(conflict_skill)
			labels.append("❌ 预览冲突技能：【%s】（%s）" % [conflict_skill.display_name, conflict_skill.get_type_name()])
			tooltips.append(_format_skill_detailed(conflict_skill, "【冲突将被遗忘】"))
			disabled.append(false)
		
		ui.open_choices(
			npc_name,
			prompt,
			entries,
			labels,
			tooltips,
			disabled
		)
		ui.show_transaction_result(false, "注意：此传授将永久遗忘 %s，并习得【%s】！" % [conflict_str, target_skill.display_name])
	else:
		# 分支 B：无冲突技能，直接学习
		_current_mode = DialogueMode.NORMAL_LEARN
		var prompt := "%s\n【将要习得】：【%s】（%s）" % [
			normal_prompt,
			target_skill.display_name,
			target_skill.get_type_name()
		]
		var entries: Array[Resource] = [target_skill, target_skill]
		var labels: Array[String] = [
			"⚡ 确认传授：习得【%s】" % target_skill.display_name,
			"📖 预览技能详情：【%s】（%s）" % [target_skill.display_name, target_skill.get_type_name()]
		]
		var tooltips: Array[String] = [
			_format_skill_detailed(target_skill, "【新技能】"),
			_format_skill_detailed(target_skill, "【技能详情】")
		]
		var disabled: Array[bool] = [false, false]
		
		ui.open_choices(
			npc_name,
			prompt,
			entries,
			labels,
			tooltips,
			disabled
		)
		ui.show_transaction_result(true, _format_skill_summary(target_skill, "【可学技能】"))


func handle_dialogue_option(index: int, ui: NpcInteractionUI, player: Player) -> void:
	match _current_mode:
		DialogueMode.ALREADY_LEARNED:
			if target_skill != null:
				ui.show_transaction_result(true, _format_skill_summary(target_skill, "【已掌握】"))

		DialogueMode.NORMAL_LEARN:
			if index == 0:
				if target_skill != null:
					player.learn_skill(target_skill)
					ui.show_transaction_result(true, "领悟了新技能：【%s】！" % target_skill.display_name)
					_current_mode = DialogueMode.ALREADY_LEARNED
					ui.open_choices(
						npc_name,
						already_learned_prompt,
						[target_skill],
						["📖 查看已掌握技能：【%s】（%s）" % [target_skill.display_name, target_skill.get_type_name()]],
						[_format_skill_detailed(target_skill, "【已掌握】")],
						[false]
					)
			elif index == 1:
				if target_skill != null:
					ui.show_transaction_result(true, _format_skill_summary(target_skill, "【新技能详情】"))

		DialogueMode.FORGET_AND_LEARN:
			if index == 0:
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
					["📖 查看已掌握技能：【%s】（%s）" % [target_skill.display_name, target_skill.get_type_name()]],
					[_format_skill_detailed(target_skill, "【已掌握】")],
					[false]
				)
			elif index == 1:
				if target_skill != null:
					ui.show_transaction_result(true, _format_skill_summary(target_skill, "【将要习得】"))
			else:
				var conflict_idx := index - 2
				if conflict_idx >= 0 and conflict_idx < _active_conflicts.size():
					var conflict_skill := _active_conflicts[conflict_idx]
					ui.show_transaction_result(false, _format_skill_summary(conflict_skill, "【将被遗忘】"))


func handle_dialogue_option_focused(index: int, ui: NpcInteractionUI, _player: Player) -> void:
	match _current_mode:
		DialogueMode.ALREADY_LEARNED:
			if target_skill != null:
				ui.show_transaction_result(true, _format_skill_summary(target_skill, "【已掌握】"))

		DialogueMode.NORMAL_LEARN:
			if index == 0:
				if target_skill != null:
					ui.show_transaction_result(true, "准备传授：【%s】\n%s" % [target_skill.display_name, _format_skill_summary(target_skill)])
			elif index == 1:
				if target_skill != null:
					ui.show_transaction_result(true, _format_skill_summary(target_skill, "【将要习得】"))

		DialogueMode.FORGET_AND_LEARN:
			var conflict_names: Array[String] = []
			for skill in _active_conflicts:
				conflict_names.append("【%s】" % skill.display_name)
			var conflict_str := "、".join(conflict_names)

			if index == 0:
				ui.show_transaction_result(false, "注意：此操作将遗忘 %s，并习得【%s】！" % [conflict_str, target_skill.display_name])
			elif index == 1:
				if target_skill != null:
					ui.show_transaction_result(true, _format_skill_summary(target_skill, "【将要习得】"))
			else:
				var conflict_idx := index - 2
				if conflict_idx >= 0 and conflict_idx < _active_conflicts.size():
					var conflict_skill := _active_conflicts[conflict_idx]
					ui.show_transaction_result(false, _format_skill_summary(conflict_skill, "【将被遗忘】"))


func _format_skill_summary(skill: SkillData, prefix: String = "") -> String:
	if skill == null:
		return ""
	var parts: Array[String] = []
	if not prefix.is_empty():
		parts.append("%s 【%s】（%s）" % [prefix, skill.display_name, skill.get_type_name()])
	else:
		parts.append("【%s】（%s）" % [skill.display_name, skill.get_type_name()])
	
	if not skill.description.is_empty():
		parts.append("说明：%s" % skill.description)
	
	var cost_strs: Array[String] = []
	for cost: ActionCostData in skill.costs:
		var d := cost.get_description()
		if not d.is_empty():
			cost_strs.append(d)
	if not cost_strs.is_empty():
		parts.append("消耗：%s" % "，".join(cost_strs))
		
	var effect_strs: Array[String] = []
	for eff: ActionEffectData in skill.effects:
		var d := eff.get_description()
		if not d.is_empty():
			effect_strs.append(d)
	if not effect_strs.is_empty():
		parts.append("效果：%s" % "；".join(effect_strs))
		
	return " | ".join(parts)


func _format_skill_detailed(skill: SkillData, title_prefix: String = "") -> String:
	if skill == null:
		return ""
	var lines: Array[String] = []
	if not title_prefix.is_empty():
		lines.append("%s 【%s】（%s技能）" % [title_prefix, skill.display_name, skill.get_type_name()])
	else:
		lines.append("【%s】（%s技能）" % [skill.display_name, skill.get_type_name()])
		
	if not skill.description.is_empty():
		lines.append("【描述】%s" % skill.description)
	
	var cost_strs: Array[String] = []
	for cost: ActionCostData in skill.costs:
		var d := cost.get_description()
		if not d.is_empty():
			cost_strs.append(d)
	if not cost_strs.is_empty():
		lines.append("【消耗】%s" % "，".join(cost_strs))
		
	var effect_strs: Array[String] = []
	for eff: ActionEffectData in skill.effects:
		var d := eff.get_description()
		if not d.is_empty():
			effect_strs.append(d)
	if not effect_strs.is_empty():
		lines.append("【效果】%s" % "；".join(effect_strs))
		
	return "\n".join(lines)
