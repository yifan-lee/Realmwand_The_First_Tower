@tool
class_name FloorPortal
extends Area2D

signal state_changed(portal_id: StringName, is_active: bool)

enum AttributeType {
	ATK = 0,     ## 红色 (攻击)
	DEF = 1,     ## 蓝色 (防御)
	SPD = 2,     ## 绿色 (速度)
	HP = 3,      ## 金黄 (生命)
	FP = 4,      ## 紫色 (特技/专注)
	MP = 5,      ## 青色 (魔法)
	NEUTRAL = 6, ## 中立 (灰色)
}

const ATLAS_TEXTURE_PATH: String = "res://assets/tileset/tiles_attribute_7x7.png"
const CELL_SIZE: int = 203
const COL_ACTIVE: int = 5    ## 第6列 (激活态传送门)
const COL_INACTIVE: int = 6  ## 第7列 (未激活态传送门)

@export_group("Identity")
@export var portal_id: StringName = &""

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
@export var is_active: bool = true:
	set(value):
		if is_active != value:
			is_active = value
			_update_visual()
			if not Engine.is_editor_hint():
				state_changed.emit(portal_id, is_active)

@export_group("Destination")
@export var target_floor_id: StringName = &""  ## 目标楼层ID（留空则默认同层传送）
@export var target_spawn_id: StringName = &""  ## 目标出生点/标记点ID
@export var target_position: Vector2 = Vector2.ZERO  ## 备选直接目标世界坐标

@onready var sprite: Sprite2D = $Sprite2D
@onready var trigger_shape: CollisionShape2D = $CollisionShape2D

var _atlas_texture: AtlasTexture
var _is_teleporting: bool = false


func get_persistent_id() -> String:
	if not portal_id.is_empty():
		return portal_id
	return IdGenerator.generate_instance_id(self)


func _ready() -> void:
	_init_texture()
	_update_visual()

	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)


func set_active(active: bool) -> void:
	is_active = active


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint() or not is_active or _is_teleporting:
		return

	var player := body as Player
	if player == null:
		return

	_is_teleporting = true

	if player.movement.is_moving:
		await player.movement.movement_finished

	if not is_instance_valid(player):
		_is_teleporting = false
		return

	if player.global_position.distance_to(global_position) > 20.0:
		_is_teleporting = false
		return

	# 1. 优先通过 target_spawn_id 触发统一传送（target_floor_id 为空即默认同层）
	if not target_spawn_id.is_empty() or not target_floor_id.is_empty():
		EventBus.floor_change_requested.emit(target_floor_id, target_spawn_id)
	# 2. 备选直接世界坐标同层传送
	elif target_position != Vector2.ZERO:
		player.set_input_enabled(false)
		EventBus.screen_fade_out_started.emit()
		await EventBus.screen_fade_out_finished
		player.global_position = target_position
		EventBus.screen_fade_in_with_info_started.emit("", "")
		await EventBus.screen_fade_in_finished
		player.set_input_enabled(true)
	else:
		push_error("Portal '%s' has no target_spawn_id or target_position configured." % get_persistent_id())

	_is_teleporting = false


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
