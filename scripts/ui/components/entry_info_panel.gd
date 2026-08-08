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

	icon_rect.texture = view_data.icon
	icon_rect.visible = view_data.icon != null

	var has_details := not view_data.detail_lines.is_empty()

	details_separator.visible = has_details
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
