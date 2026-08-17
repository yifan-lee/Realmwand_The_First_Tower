@tool
class_name SkillTutor
extends StaticBody2D

enum Step {
	INTRO,
	CHOICES,
	CONFIRM,
	ALREADY_LEARNED,
}

@export_group("Identity")
@export var tutor_id: StringName = &""
@export var npc_name: String = "武艺导师"

@export_group("Visuals")
@export var texture: Texture2D = preload("res://assets/interactables/npc_universal.png"):
	set(value):
		texture = value
		_update_visuals()
@export var sprite_scale: Vector2 = Vector2(0.125, 0.125):
	set(value):
		sprite_scale = value
		_update_visuals()
@export var hframes: int = 1:
	set(value):
		hframes = maxi(1, value)
		_update_visuals()
@export var vframes: int = 1:
	set(value):
		vframes = maxi(1, value)
		_update_visuals()
@export var frame: int = 0:
	set(value):
		frame = maxi(0, value)
		_update_visuals()
@export var offset: Vector2 = Vector2.ZERO:
	set(value):
		offset = value
		_update_visuals()

@export_group("Skill Teaching")
@export var target_skill: SkillData
@export var conflict_skills: Array[SkillData] = []

@export_group("Dialogue Texts")
@export_multiline var normal_prompt: String = "我可以传授你独门技能，只要你愿意潜心修习。"
@export_multiline var conflict_prompt: String = "你所掌握的技艺与这门技能冲突！若想习得新技能，必须先遗忘原有的招式，你可愿意？"
@export_multiline var already_learned_prompt: String = "你已经掌握了这门技能的精髓，去实战中磨砺它吧。"
@export_multiline var confirm_prompt: String = "你确定要领悟这门新技能吗？"

var _current_step: Step = Step.INTRO
var _active_conflicts: Array[SkillData] = []


func _ready() -> void:
	_update_visuals()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	var sprite_node := get_node_or_null("Sprite2D") as Sprite2D
	if sprite_node == null:
		return
	if texture != null:
		sprite_node.texture = texture
	sprite_node.scale = sprite_scale
	sprite_node.hframes = hframes
	sprite_node.vframes = vframes
	sprite_node.frame = frame
	sprite_node.offset = offset


func get_persistent_id() -> String:
	if not tutor_id.is_empty():
		return String(tutor_id)
	return IdGenerator.generate_instance_id(self)


func interact(player: Player) -> void:
	if Engine.is_editor_hint() or player == null:
		return
	EventBus.npc_interaction_requested.emit(self, player)


# 1. 开始对话
func begin_interaction(ui: NpcInteractionUI, player: Player) -> void:
	if target_skill == null:
		ui.open_dialogue(npc_name, "（这位导师似乎还没有准备好要传授的技能...）")
		return

	if player.has_skill(target_skill.id):
		_current_step = Step.ALREADY_LEARNED
		ui.open_dialogue(npc_name, already_learned_prompt)
		ui.show_player_stats(player)
		return

	_current_step = Step.INTRO
	ui.open_dialogue(npc_name, normal_prompt)
	ui.show_player_stats(player)


# 玩家按下确认键推进对话
func advance_dialogue(ui: NpcInteractionUI, player: Player) -> void:
	if _current_step == Step.ALREADY_LEARNED:
		ui.close()
		return

	if _current_step == Step.INTRO:
		_active_conflicts.clear()
		for skill: SkillData in conflict_skills:
			if skill != null and player.has_skill(skill.id):
				_active_conflicts.append(skill)

		_current_step = Step.CHOICES
		_show_choices_step(ui, player)


# 2. 第二阶段：展示选项
func _show_choices_step(ui: NpcInteractionUI, player: Player) -> void:
	var entries: Array[Resource] = [target_skill]
	var labels: Array[String] = ["新技能：%s" % target_skill.display_name]
	var tooltips: Array[String] = [""]
	var disabled: Array[bool] = [false]
	var prompt_text := normal_prompt

	if not _active_conflicts.is_empty():
		prompt_text = conflict_prompt
		for conflict: SkillData in _active_conflicts:
			entries.append(conflict)
			labels.append("冲突技能：%s" % conflict.display_name)
			tooltips.append("")
			disabled.append(true) # 灰色按键，不能按下

	ui.open_choices(npc_name, prompt_text, entries, labels, tooltips, disabled)
	ui.show_player_stats(player)
	if not _active_conflicts.is_empty():
		ui.show_transaction_result(false, "存在冲突技能，领悟新技能将遗忘冲突技能")
	else:
		ui.show_transaction_result(true, "")


# 3. 第三阶段：展示确认
func _show_confirm_step(ui: NpcInteractionUI, player: Player) -> void:
	var prompt_text := confirm_prompt
	if not _active_conflicts.is_empty():
		var conflict_names: Array[String] = []
		for s: SkillData in _active_conflicts:
			conflict_names.append("【%s】" % s.display_name)
		var conflict_str := "、".join(conflict_names)
		prompt_text = "%s\n（注意：学习将永久遗忘冲突技能 %s）" % [confirm_prompt, conflict_str]

	var entries: Array[Resource] = [target_skill]
	var labels: Array[String] = ["确认领悟"]
	var tooltips: Array[String] = [""]
	var disabled: Array[bool] = [false]

	ui.open_choices(npc_name, prompt_text, entries, labels, tooltips, disabled)
	ui.show_player_stats(player)
	ui.show_transaction_result(true, "")


# 移动光标预览技能
func handle_dialogue_option_focused(index: int, ui: NpcInteractionUI, _player: Player) -> void:
	match _current_step:
		Step.CHOICES:
			if not _active_conflicts.is_empty() and index >= 1 and index <= _active_conflicts.size():
				ui.show_transaction_result(false, "冲突技能：学习新技能后将遗忘此技能")
			else:
				ui.show_transaction_result(true, "")

		Step.CONFIRM:
			ui.show_transaction_result(true, "")


# 选项点击处理
func handle_dialogue_option(index: int, ui: NpcInteractionUI, player: Player) -> void:
	match _current_step:
		Step.CHOICES:
			if index == 0:
				# 选择新技能，进入确认阶段
				_current_step = Step.CONFIRM
				_show_confirm_step(ui, player)
			else:
				# 选择取消
				ui.close()

		Step.CONFIRM:
			if index == 0:
				# 确认学习
				ui.close()

				var forgotten_names: Array[String] = []
				for skill: SkillData in _active_conflicts:
					player.forget_skill(skill.id)
					forgotten_names.append("【%s】" % skill.display_name)

				player.learn_skill(target_skill)

				if forgotten_names.is_empty():
					EventBus.system_message_requested.emit("成功领悟了新技能【%s】！" % target_skill.display_name)
				else:
					var forgotten_str := "、".join(forgotten_names)
					EventBus.system_message_requested.emit("遗忘了 %s，成功领悟了新技能【%s】！" % [forgotten_str, target_skill.display_name])
			else:
				# 取消
				ui.close()
