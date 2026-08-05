class_name ActorStatsPanel
extends PanelContainer

const PREVIEW_LOSS_COLOR := Color("#FF4155FF")
const PREVIEW_GAIN_COLOR := Color("#32FF7DFF")
const VALUE_COLOR := Color("#D9E5E8FF")

@onready var portrait: TextureRect = $MarginContainer/Content/Header/Portrait
@onready var name_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/NameLabel
@onready var description_label: Label = $MarginContainer/Content/Header/HeaderDetails/DescriptionLabel
@onready var header_details: VBoxContainer = $MarginContainer/Content/Header/HeaderDetails
@onready var level_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/LevelLabel
@onready var experience_row: HBoxContainer = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow
@onready var experience_value: Label = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow/ExperienceValue
@onready var hp_bar: ProgressBar = $MarginContainer/Content/Resources/HpRow/HpBar
@onready var mp_bar: ProgressBar = $MarginContainer/Content/Resources/MpRow/MpBar
@onready var fp_bar: ProgressBar = $MarginContainer/Content/Resources/FpRow/FpBar
@onready var hp_value: RichTextLabel = $MarginContainer/Content/Resources/HpRow/HpValue
@onready var mp_value: RichTextLabel = $MarginContainer/Content/Resources/MpRow/MpValue
@onready var fp_value: RichTextLabel = $MarginContainer/Content/Resources/FpRow/FpValue
@onready var hp_preview_segment: ColorRect = $MarginContainer/Content/Resources/HpRow/HpBar/HpPreviewSegment
@onready var mp_preview_segment: ColorRect = $MarginContainer/Content/Resources/MpRow/MpBar/MpPreviewSegment
@onready var fp_preview_segment: ColorRect = $MarginContainer/Content/Resources/FpRow/FpBar/FpPreviewSegment
@onready var atk_value: RichTextLabel = $MarginContainer/Content/CombatStats/AtkGroup/AtkValue
@onready var def_value: RichTextLabel = $MarginContainer/Content/CombatStats/DefGroup/DefValue
@onready var spd_value: RichTextLabel = $MarginContainer/Content/CombatStats/SpdGroup/SpdValue

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
	description_label.text = view_data.description
	description_label.visible = not view_data.description.is_empty()
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
	description_label.text = ""
	description_label.visible = false
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
	_hide_preview_segments()


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
	_update_preview_segment(hp_preview_segment, hp_bar, _view_data.current_hp, _view_data.current_hp_delta)
	_update_preview_segment(mp_preview_segment, mp_bar, _view_data.current_mp, _view_data.current_mp_delta)
	_update_preview_segment(fp_preview_segment, fp_bar, _view_data.current_fp, _view_data.current_fp_delta)


func _update_preview_segment(
	segment: ColorRect,
	bar: ProgressBar,
	current_value: float,
	delta: float
) -> void:
	if is_zero_approx(delta):
		bar.value = current_value
		segment.visible = false
		return

	var maximum := maxf(bar.max_value, 1.0)
	var preview_value := clampf(current_value + delta, 0.0, maximum)
	bar.value = minf(current_value, preview_value)
	if bar.size.x <= 0.0:
		segment.visible = false
		return
	var segment_start := minf(current_value, preview_value)
	var segment_width := absf(preview_value - current_value)
	segment.position = Vector2(bar.size.x * segment_start / maximum, 2.0)
	segment.size = Vector2(maxf(2.0, bar.size.x * segment_width / maximum), maxf(0.0, bar.size.y - 4.0))
	var flash_tint := Color("#FFFFFFFF")
	flash_tint.a = lerpf(0.15, 1.0, _view_data.get_flash_pulse())
	segment.self_modulate = flash_tint
	segment.visible = true


func _hide_preview_segments() -> void:
	hp_preview_segment.visible = false
	mp_preview_segment.visible = false
	fp_preview_segment.visible = false


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
