@tool
class_name FloorDoor
extends StaticBody2D

signal state_changed(
	door_id: StringName,
	is_open: bool
)

enum AttributeType {
	ATK = 0,     ## 红色 (攻击)
	DEF = 1,     ## 蓝色 (防御)
	SPD = 2,     ## 绿色 (速度)
	HP = 3,      ## 金黄 (生命)
	FP = 4,      ## 紫色 (特技/专注)
	MP = 5,      ## 青色 (魔法)
	NEUTRAL = 6, ## 中立 (灰色)
}

const ATLAS_TEXTURE_PATH: String = "res://assets/tileset/tiles_attribute_color.png"
const CELL_SIZE: int = 203
const COL_LOCKED: int = 0
const COL_OPEN: int = 1

@export_group("Identity")
@export var door_id: StringName = &""

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
@export var is_open: bool = false:
	set(value):
		if is_open != value:
			is_open = value
			_update_visual()
			_update_collision()
			if not Engine.is_editor_hint():
				state_changed.emit(door_id, is_open)

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
var _atlas_texture: AtlasTexture


func get_persistent_id() -> String:
	if not door_id.is_empty():
		return door_id
	return IdGenerator.generate_instance_id(self)


func _ready() -> void:
	_init_texture()
	_update_visual()
	_update_collision()


func interact(_player: Node) -> void:
	if not is_open:
		EventBus.system_message_requested.emit("这扇门紧锁着，需要通过机关打开。")


func set_open(open: bool) -> void:
	if is_open == open:
		return

	is_open = open


func open() -> void:
	set_open(true)


func close() -> void:
	set_open(false)


func _init_texture() -> void:
	if _atlas_texture == null:
		_atlas_texture = AtlasTexture.new()
		_atlas_texture.atlas = load(ATLAS_TEXTURE_PATH)

	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D

	if sprite != null and sprite.texture != _atlas_texture:
		sprite.texture = _atlas_texture


func _update_collision() -> void:
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D

	if collision_shape != null:
		if Engine.is_editor_hint():
			collision_shape.disabled = is_open
		else:
			collision_shape.set_deferred("disabled", is_open)


func _update_visual() -> void:
	if not is_node_ready() and not Engine.is_editor_hint():
		return

	_init_texture()
	if _atlas_texture != null:
		var col_idx = COL_OPEN if is_open else COL_LOCKED
		var row_idx = clampi(int(attribute), 0, 6)
		_atlas_texture.region = Rect2(
			col_idx * CELL_SIZE,
			row_idx * CELL_SIZE,
			CELL_SIZE,
			CELL_SIZE
		)

	if sprite != null:
		VisualUtils.auto_scale_sprite(sprite, Vector2i(1, 1), visual_scale_multiplier)
