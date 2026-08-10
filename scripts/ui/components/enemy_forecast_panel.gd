class_name EnemyForecastPanel
extends PanelContainer

@onready var title_label: Label = %TitleLabel
@onready var entry_info_panel: EntryInfoPanel = %EntryInfoPanel

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")


func display_forecast(skill: SkillData, enemy_name: String) -> void:
	if skill == null:
		_display_basic_attack(enemy_name)
		return

	title_label.text = "%s 即将使用：" % enemy_name
	
	var info := EntryInfoViewData.new()
	info.title = skill.display_name
	info.icon = skill.icon
	info.description = skill.description
	info.detail_lines = skill.get_details()
	
	entry_info_panel.display_info(info)
	visible = true


func _display_basic_attack(enemy_name: String) -> void:
	title_label.text = "%s 即将使用：" % enemy_name
	
	var info := EntryInfoViewData.new()
	info.title = "普通攻击"
	info.description = "对目标造成物理伤害。"
	info.detail_lines = ["造成基础攻击力的伤害。"]
	
	entry_info_panel.display_info(info)
	visible = true


func clear_forecast() -> void:
	visible = false
	entry_info_panel.clear_info()
