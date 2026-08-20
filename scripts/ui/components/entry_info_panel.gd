class_name EntryInfoPanel
extends PanelContainer

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var details_separator: Control = %DetailsSeparator
@onready var details_label: RichTextLabel = %DetailsLabel


func display_info(
	view_data: EntryInfoViewData
) -> void:
	if view_data == null:
		clear_info()
		return

	visible = true

	title_label.text = view_data.title
	description_label.text = view_data.description
	description_label.visible = not view_data.description.is_empty()

	icon_rect.texture = view_data.icon
	icon_rect.visible = view_data.icon != null

	var has_details := not view_data.detail_lines.is_empty()

	details_separator.visible = has_details and description_label.visible
	details_label.visible = has_details
	details_label.text = "\n".join(view_data.detail_lines)


func clear_info() -> void:
	visible = false
	title_label.text = ""
	description_label.text = ""

	icon_rect.texture = null
	icon_rect.visible = false

	details_label.text = ""
	details_label.visible = false
	details_separator.visible = false


func display_skill(skill: SkillData, fallback_to_basic_attack: bool = false) -> void:
	if skill == null:
		if fallback_to_basic_attack:
			var default_view := EntryInfoViewData.new()
			default_view.title = "普通攻击"
			default_view.description = "对目标造成基础物理伤害。"
			default_view.detail_lines = [
				"类别：物理",
				"\n【效果】",
				"1. 对目标造成基础物理伤害"
			]
			display_info(default_view)
		else:
			clear_info()
		return
	var view := EntryInfoViewData.new()
	view.title = skill.display_name
	view.icon = skill.icon
	view.description = ""
	view.detail_lines = skill.get_details()
	display_info(view)


func display_item(item: ItemData) -> void:
	if item == null:
		clear_info()
		return
		
	var details: Array[String] = []
	if item is EquipmentData:
		var equip := item as EquipmentData
		if equip.max_hp_bonus != 0: details.append("最大生命: %+d" % int(equip.max_hp_bonus))
		if equip.max_mp_bonus != 0: details.append("最大法力: %+d" % int(equip.max_mp_bonus))
		if equip.atk_bonus != 0: details.append("物理攻击: %+d" % int(equip.atk_bonus))
		if equip.def_bonus != 0: details.append("物理防御: %+d" % int(equip.def_bonus))
		if equip.spd_bonus != 0: details.append("速度: %+d" % int(equip.spd_bonus))
	elif item != null and not item.effects.is_empty():
		for effect in item.effects:
			if effect != null:
				var res_name = "生命" if effect.resource_type == ActionEffectData.ResourceType.HP else ("法力" if effect.resource_type == ActionEffectData.ResourceType.MP else "FP")
				details.append("恢复%s: +%d" % [res_name, int(effect.value)])
		
	var view := EntryInfoViewData.new()
	view.title = item.display_name
	view.icon = item.icon
	view.description = item.description
	view.detail_lines = details
	display_info(view)
