class_name EnemyForecastPanel
extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var entry_info_panel: EntryInfoPanel = %EntryInfoPanel

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")


func display_forecast(skill: SkillData, enemy_name: String, active_effects: Array[Dictionary] = []) -> void:
	title_label.text = "%s 状态与行动：" % enemy_name
	
	var info := EntryInfoViewData.new()
	var details: Array[String] = []

	# 1. 先展示 Buff / 状态与被动
	if not active_effects.is_empty():
		details.append("【当前状态】")
		var eff_idx: int = 1
		for eff in active_effects:
			var eff_text: String = eff.get("text", "")
			if not eff_text.is_empty():
				details.append("%d. %s" % [eff_idx, eff_text])
				eff_idx += 1

	# 2. 再展示对方将要使用的技能
	if skill != null:
		info.title = skill.display_name
		info.icon = skill.icon
		info.description = skill.description
		
		var skill_details = skill.get_details()
		if not details.is_empty():
			details.append("\n【即将使用】")
		details.append_array(skill_details)
	else:
		info.title = "普通攻击"
		info.description = "对目标造成物理伤害。"
		if not details.is_empty():
			details.append("\n【即将使用】")
		details.append("类别：物理")
		details.append("\n【效果】")
		details.append("1. 对敌方造成基础物理伤害")
		details.append("\n【消耗】")
		details.append("1. 无消耗")
		
	info.detail_lines = details
	entry_info_panel.display_info(info)
	visible = true


func clear_forecast() -> void:
	visible = false
	entry_info_panel.clear_info()
