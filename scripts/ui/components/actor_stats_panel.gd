class_name ActorStatsPanel
extends PanelContainer

enum FpDisplayMode {
	PROGRESS_BAR,
	RECOVERY_SPEED,
}

@export var fp_display_mode: FpDisplayMode = FpDisplayMode.PROGRESS_BAR

const PREVIEW_LOSS_COLOR := Color("#FF4155FF")
const PREVIEW_GAIN_COLOR := Color("#32FF7DFF")
const VALUE_COLOR := Color("#D9E5E8FF")
const BUFF_LABEL_SCENE := preload("res://scenes/ui/components/buff_label.tscn")
const FEATURE_IDS: Array[StringName] = [
	&"hp",
	&"mp",
	&"fp",
	&"atk",
	&"def",
	&"spd",
]


@onready var portrait: TextureRect = $MarginContainer/Content/Header/Portrait
@onready var name_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/NameLabel
@onready var description_label: Label = $MarginContainer/Content/Header/HeaderDetails/DescriptionLabel
@onready var header_details: VBoxContainer = $MarginContainer/Content/Header/HeaderDetails
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
@onready var buffs_container: VBoxContainer = %BuffsContainer
@onready var level_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/LevelLabel
@onready var experience_row: HBoxContainer = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow
@onready var hp_row: Control = $MarginContainer/Content/Resources/HpRow
@onready var mp_row: Control = $MarginContainer/Content/Resources/MpRow
@onready var fp_row: Control = $MarginContainer/Content/Resources/FpRow
@onready var atk_group: Control = $MarginContainer/Content/CombatStats/AtkGroup
@onready var def_group: Control = $MarginContainer/Content/CombatStats/DefGroup
@onready var spd_group: Control = $MarginContainer/Content/CombatStats/SpdGroup

var _view_data: ActorStatsViewData
var _feature_visibility: Dictionary = {}
var _feature_unlock_state: FeatureUnlockState


func _ready() -> void:
	var feature_unlock_state := (
		get_node_or_null("/root/FeatureUnlocks")
		as FeatureUnlockState
	)

	if feature_unlock_state != null:
		bind_feature_unlock_state(feature_unlock_state)


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
	level_label.visible = (
		show_progression
		# and _is_feature_visible(&"level")
	)

	experience_row.visible = (
		show_progression
		# and _is_feature_visible(&"exp")
	)
	if show_progression:
		level_label.text = "等级 %d" % view_data.level
		experience_value.text = "%d/%d" % [view_data.experience, view_data.experience_to_next_level]

	_update_resource_bars()
	hp_value.text = _format_resource(view_data.current_hp, view_data.max_hp, view_data.current_hp_delta, view_data.max_hp_delta)
	mp_value.text = _format_resource(view_data.current_mp, view_data.max_mp, view_data.current_mp_delta, view_data.max_mp_delta)
	
	if fp_display_mode == FpDisplayMode.RECOVERY_SPEED:
		fp_bar.visible = false
		fp_value.text = "[right]%s /s[/right]" % _format_float_stat(view_data.fp_recovery_spd, view_data.fp_recovery_spd_delta)
	else:
		fp_bar.visible = true
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

	_refresh_buffs(view_data.active_effects)


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
	_refresh_buffs([])


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
	
	if fp_display_mode == FpDisplayMode.RECOVERY_SPEED:
		fp_bar.visible = false
		fp_value.text = "[right]%s /s[/right]" % _format_float_stat(_view_data.fp_recovery_spd, _view_data.fp_recovery_spd_delta)
	else:
		fp_bar.visible = true
		fp_value.text = _format_resource(current_fp, _view_data.max_fp, _view_data.current_fp_delta)


func _update_resource_bars() -> void:
	hp_bar.max_value = _view_data.get_preview_max_hp()
	mp_bar.max_value = _view_data.get_preview_max_mp()
	_update_preview_segment(hp_preview_segment, hp_bar, _view_data.current_hp, _view_data.current_hp_delta)
	_update_preview_segment(mp_preview_segment, mp_bar, _view_data.current_mp, _view_data.current_mp_delta)

	if fp_display_mode == FpDisplayMode.PROGRESS_BAR:
		fp_bar.max_value = maxf(_view_data.max_fp, 1.0)
		_update_preview_segment(fp_preview_segment, fp_bar, _view_data.current_fp, _view_data.current_fp_delta)
	else:
		fp_preview_segment.visible = false


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


func _format_float_stat(
	value: float,
	delta: float
) -> String:
	if is_zero_approx(delta):
		return "[color=#%s]%.1f[/color]" % [VALUE_COLOR.to_html(false), value]

	var delta_color: Color = PREVIEW_GAIN_COLOR if delta > 0 else PREVIEW_LOSS_COLOR
	var sign_str := "+" if delta > 0 else ""
	return "[color=#%s]%.1f[/color] [color=#%s](%s%.1f)[/color]" % [
		VALUE_COLOR.to_html(false),
		value,
		delta_color.to_html(false),
		sign_str,
		delta,
	]


func _refresh_buffs(effects: Array[Dictionary]) -> void:
	for child in buffs_container.get_children():
		child.queue_free()
	
	if effects.is_empty():
		buffs_container.visible = false
		return
		
	buffs_container.visible = true
	for active: Dictionary in effects:
		var effect: ActionEffectData = active.get(&"effect") as ActionEffectData
		if effect == null: continue
		var desc := effect.get_description()
		if desc.is_empty(): continue
		var remaining: int = active.get(&"remaining_count", 0)
		var label := BUFF_LABEL_SCENE.instantiate() as Label
		label.text = "• %s (剩余 %d 次)" % [desc, remaining]
		buffs_container.add_child(label)


func set_feature_visibility(
	feature_id: StringName,
	should_show: bool
) -> void:
	_feature_visibility[feature_id] = should_show
	match feature_id:
		&"hp":
			hp_row.visible = should_show
		&"mp":
			mp_row.visible = should_show
		&"fp":
			fp_row.visible = should_show
		&"atk":
			atk_group.visible = should_show
		&"def":
			def_group.visible = should_show
		&"spd":
			spd_group.visible = should_show
		&"exp":
			experience_row.visible = should_show
		&"level":
			level_label.visible = should_show


func _is_feature_visible(
	feature_id: StringName
) -> bool:
	return _feature_visibility.get(
		feature_id,
		false
	)


func bind_feature_unlock_state(
	feature_unlock_state: FeatureUnlockState
) -> void:
	_feature_unlock_state = feature_unlock_state

	if _feature_unlock_state == null:
		return

	_feature_unlock_state.feature_unlocked.connect(
		_on_feature_unlocked
	)

	for feature_id: StringName in FEATURE_IDS:
		set_feature_visibility(
			feature_id,
			_feature_unlock_state.is_unlocked(feature_id)
		)

func _on_feature_unlocked(
	feature_id: StringName
) -> void:
	set_feature_visibility(
		feature_id,
		true
	)
