class_name SelectionDetailPanel
extends PanelContainer

@onready var title_label: Label = (
	$MarginContainer/Content/TitleLabel
)

@onready var description_label: Label = (
	$MarginContainer/Content/DescriptionLabel
)

@onready var property_list: VBoxContainer = (
	$MarginContainer/Content/PropertyList
)

@onready var warning_label: Label = (
	$MarginContainer/Content/WarningLabel
)


func show_detail(
	detail: SelectionDetailData
) -> void:
	title_label.text = detail.title
	description_label.text = detail.description
	warning_label.text = detail.warning

	_clear_property_list()

	for property_text in detail.properties:
		var label := Label.new()
		label.text = property_text
		label.add_theme_font_size_override(
			"font_size",
			28
		)

		property_list.add_child(label)

	visible = true


func clear_detail() -> void:
	title_label.text = ""
	description_label.text = ""
	warning_label.text = ""

	_clear_property_list()
	visible = false


func _clear_property_list() -> void:
	for child in property_list.get_children():
		property_list.remove_child(child)
		child.queue_free()
