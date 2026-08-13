class_name FloorInfoHUD
extends PanelContainer

@onready var title_label: Label = $Content/TitleLabel
@onready var desc_label: Label = $Content/DescLabel

func _ready() -> void:
	title_label.text = ""
	desc_label.text = ""
	
func set_info(title: String, desc: String) -> void:
	title_label.text = title
	desc_label.text = desc

