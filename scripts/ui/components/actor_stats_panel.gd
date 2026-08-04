class_name ActorStatsPanel
extends PanelContainer

const PREVIEW_LOSS_COLOR := Color("#FF4155FF")
const PREVIEW_GAIN_COLOR := Color("#32FF7DFF")
const VALUE_COLOR := Color("#D9E5E8FF")

@onready var portrait: TextureRect = $MarginContainer/Content/Header/Portrait
@onready var name_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/NameLabel
@onready var header_details: VBoxContainer = $MarginContainer/Content/Header/HeaderDetails
@onready var level_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/LevelLabel
@onready var experience_row: HBoxContainer = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow
@onready var experience_value: Label = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow/ExperienceValue
@onready var hp_bar: ProgressBar = $MarginContainer/Content/Resources/HpRow/HpBar
@onready var mp_bar: ProgressBar = $MarginContainer/Content/Resources/MpRow/MpBar
@onready var fp_bar: ProgressBar = $MarginContainer/Content/Resources/FpRow/FpBar
@onready var hp_value: RichTextLabel = $MarginContainer/Content/Resources/HpRow/HpBar/HpValue
@onready var mp_value: RichTextLabel = $MarginContainer/Content/Resources/MpRow/MpBar/MpValue
@onready var fp_value: RichTextLabel = $MarginContainer/Content/Resources/FpRow/FpBar/FpValue
@onready var atk_value: RichTextLabel = $MarginContainer/Content/CombatStats/AtkRow/AtkValue
@onready var def_value: RichTextLabel = $MarginContainer/Content/CombatStats/DefRow/DefValue
@onready var spd_value: RichTextLabel = $MarginContainer/Content/CombatStats/SpdRow/SpdValue

var _view_data: ActorStatsViewData


func display_stats(
	view_data: ActorStatsViewData
) -> void:
	if view_data == null:
		clear_stats()
		return
	_view_data = view_data

	portrait.texture = view_data.portrait
	portrait.visible = view_data.portrait != null

	name_label.text = view_data.display_name
	var show_progression := view_data.has_progression()
	level_label.visible = show_progression
	experience_row.visible = show_progression
	if show_progression:
		level_label.text = "等级 %d" % view_data.level
		experience_value.text = "%d/%d" % [view_data.experience, view_data.experience_to_next_level]

	_update_resource_bars()
	hp_value.text = _format_resource(view_data.current_hp, view_data.max_hp, view_data.current_hp_delta, view_data.max_hp_delta)
	mp_value.text = _format_resource(view_data.current_mp, view_data.max_mp, view_data.current_mp_delta, view_data.max_mp_delta)
	fp_value.text = _format_resource(view_data.current_fp, view_data.max_fp, view_data.current_fp_delta)

	atk_value.text = _format_stat(
		view_data.atk,
		view_data.atk_delta
	)
	def_value.text = _format_stat(
		view_data.def,
		view_data.def_delta
	)
	spd_value.text = _format_stat(
		view_data.spd,
		view_data.spd_delta
	)


func clear_stats() -> void:
	_view_data = null
	portrait.texture = null
	portrait.visible = false

	name_label.text = ""
	header_details.visible = true
	level_label.visible = false
	experience_row.visible = false
	level_label.text = ""
	experience_value.text = ""
	hp_value.text = ""
	mp_value.text = ""
	fp_value.text = ""
	atk_value.text = ""
	def_value.text = ""
	spd_value.text = ""
	hp_bar.value = 0.0
	mp_bar.value = 0.0
	fp_bar.value = 0.0


func _process(_delta: float) -> void:
	if _view_data != null and _view_data.has_any_preview():
		_update_resource_bars()


func refresh_runtime_resources(
	current_hp: float,
	current_mp: float,
	current_fp: float
) -> void:
	if _view_data == null:
		return

	_view_data.current_hp = current_hp
	_view_data.current_mp = current_mp
	_view_data.current_fp = current_fp
	_update_resource_bars()
	hp_value.text = _format_resource(current_hp, _view_data.max_hp, _view_data.current_hp_delta, _view_data.max_hp_delta)
	mp_value.text = _format_resource(current_mp, _view_data.max_mp, _view_data.current_mp_delta, _view_data.max_mp_delta)
	fp_value.text = _format_resource(current_fp, _view_data.max_fp, _view_data.current_fp_delta)


func _update_resource_bars() -> void:
	hp_bar.max_value = _view_data.get_preview_max_hp()
	mp_bar.max_value = _view_data.get_preview_max_mp()
	fp_bar.max_value = maxf(_view_data.max_fp, 1.0)
	hp_bar.value = _view_data.get_hp_bar_value()
	mp_bar.value = _view_data.get_mp_bar_value()
	fp_bar.value = _view_data.get_fp_bar_value()


func _format_resource(value: float, maximum: float, delta: float, maximum_delta: float = 0.0) -> String:
	return "[right]%s / %s[/right]" % [
		_format_stat(value, delta),
		_format_stat(maximum, maximum_delta),
	]


func _format_stat(
	value: float,
	delta: float
) -> String:
	var rounded_value: int = roundi(value)
	var rounded_delta: int = roundi(delta)

	if rounded_delta == 0:
		return "[color=#%s]%d[/color]" % [VALUE_COLOR.to_html(false), rounded_value]

	var delta_color: Color = PREVIEW_GAIN_COLOR if rounded_delta > 0 else PREVIEW_LOSS_COLOR
	return "[color=#%s]%d[/color] [color=#%s](%+d)[/color]" % [
		VALUE_COLOR.to_html(false),
		rounded_value,
		delta_color.to_html(false),
		rounded_delta,
	]
