@tool
class_name FloorSwitch
extends Area2D

signal state_changed(
	switch_id: StringName,
	is_active: bool
)

enum AttributeType {
	ATK = 0,     ## 红色 (攻击)
	DEF = 1,     ## 蓝色 (防御)
	SPD = 2,     ## 绿色 (速度)
	HP = 3,      ## 金黄 (生命)
	FP = 4,      ## 紫色 (专注)
	MP = 5,      ## 青色 (灵能)
	NEUTRAL = 6, ## 中立 (灰色)
}

const ATLAS_TEXTURE_PATH: String = "res://assets/tileset/tiles_attribute_color.png"
const CELL_SIZE: int = 203
const COL_INACTIVE: int = 3
const COL_ACTIVE: int = 4

@export_group("Identity")
@export var switch_id: StringName = &""

@export_group("Visual & Attribute")
@export var attribute: AttributeType = AttributeType.NEUTRAL:
	set(value):
		attribute = value
		_update_visual()

@export var visual_scale_multiplier: float = 1.0:
	set(value):
		visual_scale_multiplier = value
		_update_visual()

@export_group("State")
@export var is_active: bool = false:
	set(value):
		if is_active != value:
			is_active = value
			_update_visual()
			if not Engine.is_editor_hint():
				state_changed.emit(switch_id, is_active)

@onready var sprite: Sprite2D = $Sprite2D
var _atlas_texture: AtlasTexture


func get_persistent_id() -> String:
	if not switch_id.is_empty():
		return switch_id
	return IdGenerator.generate_instance_id(self)


func _ready() -> void:
	_init_texture()
	_update_visual()


func interact(_player: Node) -> void:
	set_active(not is_active)


func set_active(active: bool) -> void:
	if is_active == active:
		return

	is_active = active


func _init_texture() -> void:
	if _atlas_texture == null:
		_atlas_texture = AtlasTexture.new()
		_atlas_texture.atlas = load(ATLAS_TEXTURE_PATH)

	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D

	if sprite != null and sprite.texture != _atlas_texture:
		sprite.texture = _atlas_texture


func _update_visual() -> void:
	if not is_node_ready() and not Engine.is_editor_hint():
		return

	_init_texture()
	if _atlas_texture != null:
		var col_idx = COL_ACTIVE if is_active else COL_INACTIVE
		var row_idx = clampi(int(attribute), 0, 6)
		_atlas_texture.region = Rect2(
			col_idx * CELL_SIZE,
			row_idx * CELL_SIZE,
			CELL_SIZE,
			CELL_SIZE
		)

	if sprite != null:
		VisualUtils.auto_scale_sprite(sprite, Vector2i(1, 1), visual_scale_multiplier)
