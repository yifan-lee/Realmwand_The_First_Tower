@tool
class_name DialogueNpc
extends StaticBody2D

var _texture: Texture2D = preload("res://assets/interactables/npc_universal.png")
var _sprite_scale: Vector2 = Vector2(0.125, 0.125)

@export_group("Visuals")
@export var texture: Texture2D:
	get:
		return _texture
	set(value):
		_texture = value
		_update_visuals()
@export var sprite_scale: Vector2:
	get:
		return _sprite_scale
	set(value):
		_sprite_scale = value
		_update_visuals()


@export_group("Identity")
@export var npc_name: String = "旅人"

@export_group("Dialogue")
@export var triggers_game_clear: bool = false
@export_multiline var dialogue_lines: Array[String] = [
	"你好，年轻的冒险者。",
	"这座高塔隐藏着许多古老的秘密……",
	"前面的道路充满凶险，请务必小心行事！"
]
@export_multiline var repeat_dialogue_lines: Array[String] = [
	"愿塔中的微光庇护你的前行。"
]
@export var show_stats: bool = false

var _current_line_index: int = 0
var _has_completed_first_time: bool = false


func interact(player: Player) -> void:
	if Engine.is_editor_hint() or player == null:
		return
	EventBus.npc_interaction_requested.emit(self, player)


func _ready() -> void:
	_update_visuals()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	var sprite_node := get_node_or_null("Sprite2D") as Sprite2D
	if sprite_node == null:
		return
	if texture != null:
		sprite_node.texture = texture
	sprite_node.scale = sprite_scale


# 1. 首次打开或再次对话
func begin_interaction(ui: NpcInteractionUI, player: Player) -> void:
	_current_line_index = 0
	var lines := _get_active_lines()
	if lines.is_empty():
		ui.close()
		return

	ui.open_dialogue(npc_name, lines[_current_line_index])
	if show_stats:
		ui.show_player_stats(player)
	else:
		ui.stats_panel.visible = false


# 2. 玩家按确认键推进到下一段
func advance_dialogue(ui: NpcInteractionUI, player: Player) -> void:
	_current_line_index += 1
	var lines := _get_active_lines()

	if _current_line_index < lines.size():
		ui.open_dialogue(npc_name, lines[_current_line_index])
		if show_stats:
			ui.show_player_stats(player)
		else:
			ui.stats_panel.visible = false
	else:
		# 对话结束
		_has_completed_first_time = true
		ui.close()
		if triggers_game_clear:
			EventBus.game_clear_triggered.emit()


func _get_active_lines() -> Array[String]:
	if _has_completed_first_time and not repeat_dialogue_lines.is_empty():
		return repeat_dialogue_lines
	return dialogue_lines
