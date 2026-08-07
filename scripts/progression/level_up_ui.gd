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
const STAT_COLORS := {
	&"atk": Color("#FF4155FF"),
	&"def": Color("#FFCD32FF"),
	&"spd": Color("#00F0FFFF"),
}
const GRID_EMPTY_COLOR := Color("#52656DFF")

@onready var level_root: Control = $LevelRoot
@onready var stats_panel: ActorStatsPanel = $LevelRoot/Backdrop/Center/Panel/Margin/Content/ActorStatsPanel
@onready var points_label: Label = $LevelRoot/Backdrop/Center/Panel/Margin/Content/PointsLabel
@onready var confirm_button: Button = $LevelRoot/Backdrop/Center/Panel/Margin/Content/ConfirmButton
@onready var hint_label: Label = $LevelRoot/Backdrop/Center/Panel/Margin/Content/HintLabel
@onready var value_buttons: Array[Button] = [
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/AtkRow/ValueButton,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/DefRow/ValueButton,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/SpdRow/ValueButton,
]
@onready var stat_displays: Array[RichTextLabel] = [
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/AtkRow/ValueButton/StatDisplay,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/DefRow/ValueButton/StatDisplay,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/SpdRow/ValueButton/StatDisplay,
]
@onready var allocation_grids: Array[RichTextLabel] = [
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/AtkRow/AllocationGrid,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/DefRow/AllocationGrid,
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/AllocationRows/SpdRow/AllocationGrid,
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
		value_buttons[index].pressed.connect(_select_row.bind(index))
	confirm_button.pressed.connect(_confirm_allocation)


func _input(event: InputEvent) -> void:
	if not level_root.visible:
		return

	if event.is_action_pressed(&"move_up"):
		_move_selection(-1)
	elif event.is_action_pressed(&"move_down"):
		_move_selection(1)
	elif event.is_action_pressed(&"move_left") and _selected_index < STAT_IDS.size():
		_change_allocation(_selected_index, -1)
	elif event.is_action_pressed(&"move_right") and _selected_index < STAT_IDS.size():
		_change_allocation(_selected_index, 1)
	elif event.is_action_pressed(&"ui_accept") and _selected_index == STAT_IDS.size():
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
	_sync_focus()


func close() -> void:
	level_root.visible = false
	_player = null


func _move_selection(direction: int) -> void:
	if _selected_index == STAT_IDS.size():
		_selected_index = STAT_IDS.size() - 1
	elif direction > 0 and _selected_index == STAT_IDS.size() - 1 and _get_remaining_points() == 0:
		_selected_index = STAT_IDS.size()
	else:
		_selected_index = posmod(_selected_index + direction, STAT_IDS.size())
	_sync_focus()


func _select_row(index: int) -> void:
	_selected_index = index
	_sync_focus()


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
	_sync_focus()


func _confirm_allocation() -> void:
	if _player == null or _get_remaining_points() > 0:
		return
	allocation_confirmed.emit(_allocation.duplicate())


func _get_remaining_points() -> int:
	return _player.unspent_stat_points - _allocation[&"atk"] - _allocation[&"def"] - _allocation[&"spd"]


func _refresh_preview() -> void:
	if _player == null:
		return
	var preview := _player.get_stat_allocation_preview(_allocation)
	points_label.text = "剩余点数：%d" % _get_remaining_points()
	confirm_button.disabled = _get_remaining_points() > 0
	stats_panel.display_stats(_build_stats_view(preview))
	for index: int in STAT_IDS.size():
		var stat_id := STAT_IDS[index]
		var current_value := _get_current_stat(stat_id)
		stat_displays[index].text = "[center][color=#%s]%s[/color] [color=#%s]%d[/color]%s[/center]" % [
			STAT_COLORS[stat_id].to_html(false),
			STAT_DISPLAY_NAMES[stat_id],
			VALUE_COLOR.to_html(false),
			roundi(current_value),
			_format_delta(preview[stat_id] - current_value),
		]
		allocation_grids[index].text = _format_allocation_grid(stat_id)
	hint_label.text = "点数已分配完，可选择完成。" if _get_remaining_points() == 0 else "↑↓ 选择属性   ←→ 分配点数"


func _build_stats_view(preview: Dictionary[StringName, float]) -> ActorStatsViewData:
	var view := ActorStatsViewData.new()
	view.display_name = _player.player_data.display_name
	view.portrait = _player.get_ui_portrait()
	view.level = _player.level
	view.experience = _player.experience
	view.experience_to_next_level = _player.get_experience_for_next_level()
	view.current_hp = _player.current_hp
	view.max_hp = _player.get_max_hp()
	view.current_mp = _player.current_mp
	view.max_mp = _player.get_max_mp()
	view.current_fp = _player.current_fp
	view.max_fp = _player.get_max_fp()
	view.fp_recovery_spd = _player.get_fp_recovery_spd()
	view.atk = _player.get_atk()
	view.def = _player.get_def()
	view.spd = _player.get_spd()
	view.current_hp_delta = preview[&"current_hp"] - view.current_hp
	view.max_hp_delta = preview[&"max_hp"] - view.max_hp
	view.current_mp_delta = preview[&"current_mp"] - view.current_mp
	view.max_mp_delta = preview[&"max_mp"] - view.max_mp
	view.atk_delta = preview[&"atk"] - view.atk
	view.def_delta = preview[&"def"] - view.def
	view.spd_delta = preview[&"spd"] - view.spd
	view.fp_recovery_spd_delta = preview.get(&"fp_recovery", view.fp_recovery_spd) - view.fp_recovery_spd
	return view


func _get_current_stat(stat_id: StringName) -> float:
	match stat_id:
		&"atk": return _player.get_atk()
		&"def": return _player.get_def()
		_: return _player.get_spd()


func _format_allocation_grid(stat_id: StringName) -> String:
	var filled := _allocation[stat_id]
	var total := _player.unspent_stat_points
	return "[right][color=#%s]%s[/color][color=#%s]%s[/color][/right]" % [
		STAT_COLORS[stat_id].to_html(false),
		"■ ".repeat(filled),
		GRID_EMPTY_COLOR.to_html(false),
		"□ ".repeat(maxi(0, total - filled)),
	]


func _format_delta(value: float) -> String:
	if is_zero_approx(value):
		return ""
	var delta_text := "%+.1f" % value if not is_equal_approx(value, roundf(value)) else "%+d" % roundi(value)
	return " [color=#%s](%s)[/color]" % [PREVIEW_GAIN_COLOR.to_html(false), delta_text]


func _sync_focus() -> void:
	for index: int in value_buttons.size():
		value_buttons[index].set_pressed_no_signal(false)
	if _selected_index == STAT_IDS.size():
		confirm_button.grab_focus()
	else:
		value_buttons[_selected_index].grab_focus()
