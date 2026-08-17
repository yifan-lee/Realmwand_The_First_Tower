class_name FloorInfoHUD
extends PanelContainer

@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var desc_label: Label = find_child("DescLabel", true, false) as Label


func _ready() -> void:
	EventBus.floor_changed.connect(_on_floor_changed)


func _on_floor_changed(floor_node: Node) -> void:
	if floor_node == null:
		return
	var title: String = String(floor_node.get("display_name")) if "display_name" in floor_node else ""
	var desc: String = String(floor_node.get("description")) if "description" in floor_node else ""
	set_info(title, desc)


func set_info(title: String, desc: String) -> void:
	if title_label == null:
		title_label = find_child("TitleLabel", true, false) as Label
	if desc_label == null:
		desc_label = find_child("DescLabel", true, false) as Label
	if title_label:
		title_label.text = title
	if desc_label:
		desc_label.text = desc
	
	call_deferred("_update_resting_position")


func _update_resting_position() -> void:
	if is_inside_tree() and scale == Vector2.ONE and get_parent() is EnvironmentInfoArea:
		position = Vector2(0.0, -size.y)
