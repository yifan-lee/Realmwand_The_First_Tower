class_name LevelUpUI
extends CanvasLayer

signal allocation_confirmed(allocation: Dictionary[StringName, int])

const STAT_IDS: Array[StringName] = [&"atk", &"def", &"spd"]
const STAT_DISPLAY_NAMES: Dictionary[StringName, String] = {
	&"atk": "攻击",
	&"def": "防御",
	&"spd": "速度",
}
const VALUE_COLOR := Color("#D9E5E8FF")
const PREVIEW_GAIN_COLOR := Color("#32FF7DFF")
const PREVIEW_LOSS_COLOR := Color("#FF4155FF")
const STAT_COLORS := {
	&"hp": Color("#32FF7DFF"),
	&"mp": Color("#AA5AFFFF"),
	&"fp": Color("#FF822DFF"),
	&"atk": Color("#FF4155FF"),
	&"def": Color("#FFCD32FF"),
	&"spd": Color("#00F0FFFF"),
}

@onready var level_root: Control = $LevelRoot
@onready var points_label: Label = $LevelRoot/Backdrop/Center/Panel/Margin/Content/PointsLabel
@onready var hp_label: RichTextLabel = $LevelRoot/Backdrop/Center/Panel/Margin/Content/ResourcePreview/HpLabel
@onready var mp_label: RichTextLabel = $LevelRoot/Backdrop/Center/Panel/Margin/Content/ResourcePreview/MpLabel
@onready var fp_label: RichTextLabel = $LevelRoot/Backdrop/Center/Panel/Margin/Content/ResourcePreview/FpLabel
@onready var hint_label: Label = $LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/HintLabel
@onready var value_buttons: Array[Button] = [
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/AtkRow/ValueButton,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/DefRow/ValueButton,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/SpdRow/ValueButton,
]
@onready var stat_displays: Array[RichTextLabel] = [
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/AtkRow/ValueButton/StatDisplay,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/DefRow/ValueButton/StatDisplay,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/SpdRow/ValueButton/StatDisplay,
]

var _player: Player
var _allocation: Dictionary[StringName, int] = {
	&"atk": 0,
	&"def": 0,
	&"spd": 0,
}
var _selected_index := 0


func _ready() -> void:
	for index: int in STAT_IDS.size():
		var row_path := "LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationCenter/AllocationBlock/AllocationRows/%sRow" % STAT_IDS[index].capitalize()
		(get_node(row_path + "/MinusButton") as Button).pressed.connect(_change_allocation.bind(index, -1))
		(get_node(row_path + "/PlusButton") as Button).pressed.connect(_change_allocation.bind(index, 1))


func _unhandled_input(event: InputEvent) -> void:
	if not level_root.visible:
		return

	if event.is_action_pressed(&"move_up"):
		_select_row(-1)
	elif event.is_action_pressed(&"move_down"):
		_select_row(1)
	elif event.is_action_pressed(&"move_left"):
		_change_allocation(_selected_index, -1)
	elif event.is_action_pressed(&"move_right"):
		_change_allocation(_selected_index, 1)
	elif event.is_action_pressed(&"ui_accept"):
		_confirm_allocation()
	else:
		return
	get_viewport().set_input_as_handled()


func open(player: Player) -> void:
	_player = player
	_allocation = {&"atk": 0, &"def": 0, &"spd": 0}
	_selected_index = 0
	level_root.visible = true
	_refresh_preview()
	value_buttons[_selected_index].grab_focus()


func close() -> void:
	level_root.visible = false
	_player = null


func _select_row(direction: int) -> void:
	_selected_index = posmod(_selected_index + direction, STAT_IDS.size())
	value_buttons[_selected_index].grab_focus()


func _change_allocation(index: int, direction: int) -> void:
	if _player == null:
		return
	var stat_id := STAT_IDS[index]
	var next_value := _allocation[stat_id] + direction
	if next_value < 0:
		return
	if direction > 0 and _get_remaining_points() <= 0:
		return
	_allocation[stat_id] = next_value
	_refresh_preview()
	value_buttons[index].grab_focus()


func _confirm_allocation() -> void:
	if _player == null:
		return
	if _get_remaining_points() > 0:
		hint_label.text = "请先分配完所有点数"
		return
	allocation_confirmed.emit(_allocation.duplicate())


func _get_remaining_points() -> int:
	return _player.unspent_stat_points - _allocation[&"atk"] - _allocation[&"def"] - _allocation[&"spd"]


func _refresh_preview() -> void:
	if _player == null:
		return
	var preview := _player.get_stat_allocation_preview(_allocation)
	points_label.text = "剩余点数：%d" % _get_remaining_points()
	hp_label.text = _format_resource("生命", &"hp", _player.current_hp, _player.get_max_hp(), preview[&"current_hp"], preview[&"max_hp"])
	mp_label.text = _format_resource("魔力", &"mp", _player.current_mp, _player.get_max_mp(), preview[&"current_mp"], preview[&"max_mp"])
	fp_label.text = _format_recovery(_player.get_fp_recovery_spd(), preview[&"fp_recovery"])
	for index: int in STAT_IDS.size():
		var stat_id := STAT_IDS[index]
		var current_value := _get_current_stat(stat_id)
		stat_displays[index].text = "[center][color=#%s]%s[/color]    [color=#%s]%d[/color]%s[/center]" % [
			STAT_COLORS[stat_id].to_html(false),
			STAT_DISPLAY_NAMES[stat_id],
			VALUE_COLOR.to_html(false),
			roundi(current_value),
			_format_delta(preview[stat_id] - current_value),
		]
	hint_label.text = "↑↓ 选择属性   ←→ 分配点数   确认键确认"


func _get_current_stat(stat_id: StringName) -> float:
	match stat_id:
		&"atk": return _player.get_atk()
		&"def": return _player.get_def()
		_: return _player.get_spd()


func _format_resource(label: String, color_key: StringName, current: float, maximum: float, preview_current: float, preview_maximum: float) -> String:
	return "[center][color=#%s]%s[/color] [color=#%s]%d[/color]%s/[color=#%s]%d[/color]%s[/center]" % [
		STAT_COLORS[color_key].to_html(false),
		label,
		VALUE_COLOR.to_html(false),
		roundi(current),
		_format_delta(preview_current - current),
		VALUE_COLOR.to_html(false),
		roundi(maximum),
		_format_delta(preview_maximum - maximum),
	]


func _format_recovery(current: float, preview: float) -> String:
	return "[center][color=#%s]专注[/color] [color=#%s]%.1f[/color]%s[color=#%s]/秒[/color][/center]" % [
		STAT_COLORS[&"fp"].to_html(false),
		VALUE_COLOR.to_html(false),
		current,
		_format_delta(preview - current),
		VALUE_COLOR.to_html(false),
	]


func _format_delta(value: float) -> String:
	if is_zero_approx(value):
		return ""
	var delta_color := PREVIEW_GAIN_COLOR if value > 0.0 else PREVIEW_LOSS_COLOR
	var delta_text := "%+.1f" % value if not is_equal_approx(value, roundf(value)) else "%+d" % roundi(value)
	return " [color=#%s](%s)[/color]" % [delta_color.to_html(false), delta_text]
