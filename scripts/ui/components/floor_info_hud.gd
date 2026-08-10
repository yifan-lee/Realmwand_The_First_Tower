class_name FloorInfoHUD
extends PanelContainer

@onready var title_label: Label = $Content/TitleLabel
@onready var desc_label: Label = $Content/DescLabel

func _ready() -> void:
	EventBus.floor_changed.connect(_on_floor_changed)
	title_label.text = ""
	desc_label.text = ""
	
func _on_floor_changed(floor: Node) -> void:
	if floor == null:
		return
	title_label.text = floor.get("display_name") if "display_name" in floor else ""
	desc_label.text = floor.get("description") if "description" in floor else ""

