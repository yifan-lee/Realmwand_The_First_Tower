@tool
class_name OneWayPassage
extends StaticBody2D

enum AttributeType {
	ATK = 0,     ## 红色 (攻击)
	DEF = 1,     ## 蓝色 (防御)
	SPD = 2,     ## 绿色 (速度)
	HP = 3,      ## 金黄 (生命)
	FP = 4,      ## 紫色 (特技/专注)
	MP = 5,      ## 青色 (魔法)
	NEUTRAL = 6, ## 中立 (米白/灰色)
}

enum PassageDirection {
	UP = 0,      ## 向上通道（从下方进入，顺势向上推一格）
	DOWN = 1,    ## 向下通道（从上方进入，顺势向下推一格）
	LEFT = 2,    ## 向左通道（从右方进入，顺势向左推一格）
	RIGHT = 3,   ## 向右通道（从左方进入，顺势向右推一格）
}

const ATLAS_TEXTURE_PATH: String = "res://assets/tileset/one_way_channels_7x4.png"
const CELL_SIZE: int = 203
const GRID_SIZE: float = 32.0
const SLIDE_DURATION: float = 0.16

@export_group("Identity")
@export var passage_id: StringName = &""

@export_group("Visual & Attribute")
@export var attribute: AttributeType = AttributeType.NEUTRAL:
	set(value):
		attribute = value
		_update_visual()

@export var direction: PassageDirection = PassageDirection.LEFT:
	set(value):
		direction = value
		_update_visual()
		_update_collision_barriers()

@export var visual_scale_multiplier: float = 1.0:
	set(value):
		visual_scale_multiplier = value
		_update_visual()

@onready var sprite: Sprite2D = $Sprite2D
@onready var trigger_area: Area2D = $TriggerArea
@onready var barrier_top: CollisionShape2D = $BarrierTop
@onready var barrier_bottom: CollisionShape2D = $BarrierBottom
@onready var barrier_left: CollisionShape2D = $BarrierLeft
@onready var barrier_right: CollisionShape2D = $BarrierRight

var _atlas_texture: AtlasTexture
var _is_sliding_player: bool = false


func get_persistent_id() -> String:
	if not passage_id.is_empty():
		return passage_id
	return IdGenerator.generate_instance_id(self)


func _ready() -> void:
	_init_texture()
	_update_visual()
	_update_collision_barriers()
	
	if not Engine.is_editor_hint():
		if trigger_area == null:
			trigger_area = get_node_or_null("TriggerArea") as Area2D
		if trigger_area != null and not trigger_area.body_entered.is_connected(_on_trigger_area_body_entered):
			trigger_area.body_entered.connect(_on_trigger_area_body_entered)


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
		var col_idx = int(direction)
		var row_idx = clampi(int(attribute), 0, 6)
		_atlas_texture.region = Rect2(
			col_idx * CELL_SIZE,
			row_idx * CELL_SIZE,
			CELL_SIZE,
			CELL_SIZE
		)

	if sprite != null:
		VisualUtils.auto_scale_sprite(sprite, Vector2i(1, 1), visual_scale_multiplier)


func _update_collision_barriers() -> void:
	if barrier_top == null: barrier_top = get_node_or_null("BarrierTop") as CollisionShape2D
	if barrier_bottom == null: barrier_bottom = get_node_or_null("BarrierBottom") as CollisionShape2D
	if barrier_left == null: barrier_left = get_node_or_null("BarrierLeft") as CollisionShape2D
	if barrier_right == null: barrier_right = get_node_or_null("BarrierRight") as CollisionShape2D

	var is_top_disabled = (direction == PassageDirection.DOWN)
	var is_bottom_disabled = (direction == PassageDirection.UP)
	var is_left_disabled = (direction == PassageDirection.RIGHT)
	var is_right_disabled = (direction == PassageDirection.LEFT)

	if Engine.is_editor_hint():
		if barrier_top: barrier_top.disabled = is_top_disabled
		if barrier_bottom: barrier_bottom.disabled = is_bottom_disabled
		if barrier_left: barrier_left.disabled = is_left_disabled
		if barrier_right: barrier_right.disabled = is_right_disabled
	else:
		if barrier_top: barrier_top.set_deferred("disabled", is_top_disabled)
		if barrier_bottom: barrier_bottom.set_deferred("disabled", is_bottom_disabled)
		if barrier_left: barrier_left.set_deferred("disabled", is_left_disabled)
		if barrier_right: barrier_right.set_deferred("disabled", is_right_disabled)


func get_push_direction_vector() -> Vector2:
	match direction:
		PassageDirection.UP:
			return Vector2.UP
		PassageDirection.DOWN:
			return Vector2.DOWN
		PassageDirection.LEFT:
			return Vector2.LEFT
		PassageDirection.RIGHT:
			return Vector2.RIGHT
	return Vector2.ZERO


func _on_trigger_area_body_entered(body: Node2D) -> void:
	if not (body is Player) or _is_sliding_player:
		return
	var player = body as Player
	call_deferred("_handle_player_slide", player)


func _handle_player_slide(player: Player) -> void:
	if _is_sliding_player or player == null:
		return

	if player.movement.is_moving:
		await player.movement.movement_finished

	if player.global_position.distance_to(global_position) > 16.0:
		return

	_is_sliding_player = true
	var push_dir := get_push_direction_vector()
	var target_pos := global_position + push_dir * GRID_SIZE

	player.set_input_enabled(false)
	player.movement.is_moving = true
	player.movement.facing_direction = push_dir
	player.movement.play_directional_animation(&"walk")

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player, "global_position", target_pos, SLIDE_DURATION)

	await tween.finished

	player.global_position = target_pos
	player.movement.is_moving = false
	player.set_input_enabled(true)
	player.movement.play_directional_animation(&"idle")
	player.movement.movement_finished.emit()
	_is_sliding_player = false
