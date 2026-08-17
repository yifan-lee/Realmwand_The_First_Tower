class_name ActorStatsPanel
extends PanelContainer

const PREVIEW_LOSS_COLOR := Color("#FF4155FF")
const PREVIEW_GAIN_COLOR := Color("#32FF7DFF")
const PREVIEW_SHIELD_COLOR := Color("#00E5FFFF")
const SHIELD_VALUE_COLOR := Color("#50C8FFFF")
const VALUE_COLOR := Color("#D9E5E8FF")
const BUFF_LABEL_SCENE := preload("res://scenes/ui/components/buff_label.tscn")
const FEATURE_IDS: Array[StringName] = [
	&"hp",
	&"mp",
	&"fp",
	&"atk",
	&"def",
	&"spd",
	&"exp",
	&"level",
]

@onready var portrait: TextureRect = $MarginContainer/Content/Header/Portrait
@onready var name_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/NameLabel
@onready var level_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/LevelLabel
@onready var cp_label: Label = $MarginContainer/Content/Header/HeaderDetails/TitleRow/CpLabel
@onready var description_label: Label = $MarginContainer/Content/Header/HeaderDetails/DescriptionLabel
@onready var header_details: VBoxContainer = $MarginContainer/Content/Header/HeaderDetails
@onready var experience_row: HBoxContainer = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow
@onready var experience_value: Label = $MarginContainer/Content/Header/HeaderDetails/ExperienceRow/ExperienceValue

@onready var hp_row: Control = $MarginContainer/Content/Resources/HpRow
@onready var hp_bar: ProgressBar = $MarginContainer/Content/Resources/HpRow/HpBar
@onready var hp_preview_segment: ColorRect = $MarginContainer/Content/Resources/HpRow/HpBar/HpPreviewSegment
@onready var hp_value: RichTextLabel = $MarginContainer/Content/Resources/HpRow/HpValue

@onready var mp_row: Control = $MarginContainer/Content/Resources/MpRow
@onready var mp_bar: ProgressBar = $MarginContainer/Content/Resources/MpRow/MpBar
@onready var mp_preview_segment: ColorRect = $MarginContainer/Content/Resources/MpRow/MpBar/MpPreviewSegment
@onready var mp_value: RichTextLabel = $MarginContainer/Content/Resources/MpRow/MpValue

@onready var fp_row: Control = $MarginContainer/Content/Resources/FpRow
@onready var fp_bar: ProgressBar = $MarginContainer/Content/Resources/FpRow/FpBar
@onready var fp_preview_segment: ColorRect = $MarginContainer/Content/Resources/FpRow/FpBar/FpPreviewSegment
@onready var fp_value: RichTextLabel = $MarginContainer/Content/Resources/FpRow/FpValue

@onready var atb_row: Control = $MarginContainer/Content/Resources/AtbRow
@onready var atb_bar: ProgressBar = $MarginContainer/Content/Resources/AtbRow/AtbBar
@onready var atb_preview_segment: ColorRect = $MarginContainer/Content/Resources/AtbRow/AtbBar/AtbPreviewSegment
@onready var atb_value: RichTextLabel = $MarginContainer/Content/Resources/AtbRow/AtbValue

@onready var atk_group: Control = $MarginContainer/Content/CombatStats/AtkGroup
@onready var atk_value: RichTextLabel = $MarginContainer/Content/CombatStats/AtkGroup/AtkValue
@onready var def_group: Control = $MarginContainer/Content/CombatStats/DefGroup
@onready var def_value: RichTextLabel = $MarginContainer/Content/CombatStats/DefGroup/DefValue
@onready var spd_group: Control = $MarginContainer/Content/CombatStats/SpdGroup
@onready var spd_value: RichTextLabel = $MarginContainer/Content/CombatStats/SpdGroup/SpdValue

@onready var buffs_separator: HSeparator = $MarginContainer/Content/BuffsSeparator
@onready var buffs_container: VBoxContainer = %BuffsContainer

var _bound_actor: Node
var _profile: ActorStatsDisplayProfile
var _context: ActorStatsContext
var _preview: ActorStatsPreviewData
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


func _exit_tree() -> void:
	_unbind_signal_only()


func bind_actor(
	actor: Node,
	profile: ActorStatsDisplayProfile = null,
	context: ActorStatsContext = null
) -> void:
	if _bound_actor != null and _bound_actor != actor:
		_unbind_signal_only()

	_bound_actor = actor
	_profile = profile if profile != null else ActorStatsDisplayProfile.menu()
	_context = context
	_preview = null

	if _bound_actor == null:
		clear_stats()
		return

	if _bound_actor.has_signal(&"stats_changed") and not _bound_actor.stats_changed.is_connected(_on_actor_stats_changed):
		_bound_actor.stats_changed.connect(_on_actor_stats_changed)

	refresh()


func set_context(context: ActorStatsContext) -> void:
	_context = context
	refresh()


func set_preview(preview: ActorStatsPreviewData) -> void:
	_preview = preview
	refresh()


func clear_preview() -> void:
	if _preview == null:
		return
	_preview = null
	refresh()


func refresh() -> void:
	if _bound_actor == null:
		if _view_data != null:
			_render_view_data(_view_data)
		return

	_view_data = ActorStatsFactory.create_view_data(_bound_actor, _profile, _context, _preview)
	_render_view_data(_view_data)


func unbind_actor() -> void:
	_unbind_signal_only()
	_bound_actor = null
	_profile = null
	_context = null
	_preview = null
	clear_stats()


func _unbind_signal_only() -> void:
	if _bound_actor != null and is_instance_valid(_bound_actor):
		if _bound_actor.has_signal(&"stats_changed") and _bound_actor.stats_changed.is_connected(_on_actor_stats_changed):
			_bound_actor.stats_changed.disconnect(_on_actor_stats_changed)


func _on_actor_stats_changed() -> void:
	refresh()


func display_stats(view_data: ActorStatsViewData) -> void:
	if view_data == null:
		clear_stats()
		return
	_view_data = view_data
	_render_view_data(view_data)


func _render_view_data(view_data: ActorStatsViewData) -> void:
	var profile: ActorStatsDisplayProfile = _profile if _profile != null else ActorStatsDisplayProfile.menu()

	# Portrait
	portrait.texture = view_data.portrait
	portrait.visible = profile.show_portrait and view_data.portrait != null

	# Name & Description
	name_label.text = view_data.display_name
	name_label.visible = profile.show_name and not view_data.display_name.is_empty()
	description_label.text = view_data.description
	description_label.visible = profile.show_description and not view_data.description.is_empty()

	# Progression & CP
	var show_progression: bool = profile.show_progression and view_data.has_progression()
	var obey_unlocks: bool = profile.obey_feature_unlocks

	level_label.visible = show_progression and _is_stat_unlocked(&"level", obey_unlocks)
	experience_row.visible = show_progression and _is_stat_unlocked(&"exp", obey_unlocks)

	if show_progression:
		level_label.text = "等级 %d" % view_data.level
		experience_value.text = "%d/%d" % [view_data.experience, view_data.experience_to_next_level]

	cp_label.visible = profile.show_cp and not show_progression and view_data.cp > 0.0 and _is_stat_unlocked(&"cp", obey_unlocks)
	if cp_label.visible:
		cp_label.text = "CP %.0f" % view_data.cp

	# Resources Visibility & Formatting
	hp_row.visible = _is_stat_unlocked(&"hp", obey_unlocks)
	mp_row.visible = _is_stat_unlocked(&"mp", obey_unlocks)
	fp_row.visible = profile.fp_display_mode != ActorStatsDisplayProfile.FpDisplayMode.HIDDEN and _is_stat_unlocked(&"fp", obey_unlocks)
	atb_row.visible = profile.atb_display_mode == ActorStatsDisplayProfile.AtbDisplayMode.BAR

	_update_resource_bars()

	hp_value.text = _format_hp_resource(
		view_data.current_hp,
		view_data.current_shield,
		view_data.max_hp,
		view_data.current_hp_delta,
		view_data.current_shield_delta,
		view_data.max_hp_delta
	)
	mp_value.text = _format_resource(
		view_data.current_mp,
		view_data.max_mp,
		view_data.current_mp_delta,
		view_data.max_mp_delta
	)

	if profile.fp_display_mode == ActorStatsDisplayProfile.FpDisplayMode.RECOVERY_SPEED:
		fp_bar.visible = false
		fp_value.text = "[right]%s /s[/right]" % _format_float_stat(view_data.fp_recovery_spd, view_data.fp_recovery_spd_delta)
	else:
		fp_bar.visible = true
		fp_value.text = _format_resource(view_data.current_fp, view_data.max_fp, view_data.current_fp_delta)

	if atb_row.visible:
		atb_value.text = _format_resource(view_data.current_atb, view_data.max_atb, view_data.current_atb_delta)

	# Combat Stats
	atk_group.visible = _is_stat_unlocked(&"atk", obey_unlocks)
	def_group.visible = _is_stat_unlocked(&"def", obey_unlocks)
	spd_group.visible = _is_stat_unlocked(&"spd", obey_unlocks)

	atk_value.text = _format_stat(view_data.atk, view_data.atk_delta)
	def_value.text = _format_stat(view_data.def, view_data.def_delta)
	spd_value.text = _format_stat(view_data.spd, view_data.spd_delta)

	# Buffs
	if profile.show_buffs:
		_refresh_buffs(view_data.active_effects)
	else:
		buffs_separator.visible = false
		_refresh_buffs([])


func clear_stats() -> void:
	_view_data = null
	portrait.texture = null
	portrait.visible = false

	name_label.text = ""
	description_label.text = ""
	description_label.visible = false
	header_details.visible = true
	level_label.visible = false
	cp_label.visible = false
	experience_row.visible = false
	level_label.text = ""
	cp_label.text = ""
	experience_value.text = ""

	hp_value.text = ""
	mp_value.text = ""
	fp_value.text = ""
	atb_value.text = ""
	atk_value.text = ""
	def_value.text = ""
	spd_value.text = ""

	hp_bar.value = 0.0
	mp_bar.value = 0.0
	fp_bar.value = 0.0
	atb_bar.value = 0.0

	_hide_preview_segments()
	_refresh_buffs([])


func _process(_delta: float) -> void:
	if _view_data != null and _view_data.has_any_preview():
		_update_resource_bars()


func _update_resource_bars() -> void:
	if _view_data == null:
		return

	hp_bar.max_value = _view_data.get_preview_max_hp()
	mp_bar.max_value = _view_data.get_preview_max_mp()

	if _view_data.has_shield_change() and _view_data.current_shield_delta > 0.0:
		_update_shield_preview_segment(hp_preview_segment, hp_bar, _view_data.current_hp, _view_data.current_shield_delta)
	else:
		_update_preview_segment(hp_preview_segment, hp_bar, _view_data.current_hp, _view_data.current_hp_delta)

	_update_preview_segment(mp_preview_segment, mp_bar, _view_data.current_mp, _view_data.current_mp_delta)

	var profile: ActorStatsDisplayProfile = _profile if _profile != null else ActorStatsDisplayProfile.menu()
	if profile.fp_display_mode == ActorStatsDisplayProfile.FpDisplayMode.PROGRESS_BAR:
		fp_bar.max_value = maxf(_view_data.max_fp, 1.0)
		_update_preview_segment(fp_preview_segment, fp_bar, _view_data.current_fp, _view_data.current_fp_delta)
	else:
		fp_preview_segment.visible = false

	if profile.atb_display_mode == ActorStatsDisplayProfile.AtbDisplayMode.BAR:
		atb_bar.max_value = maxf(_view_data.max_atb, 1.0)
		_update_preview_segment(atb_preview_segment, atb_bar, _view_data.current_atb, _view_data.current_atb_delta)
	else:
		atb_preview_segment.visible = false


func _update_shield_preview_segment(
	segment: ColorRect,
	bar: ProgressBar,
	current_value: float,
	shield_delta: float
) -> void:
	var maximum := maxf(bar.max_value, 1.0)
	bar.value = current_value
	if bar.size.x <= 0.0:
		segment.visible = false
		return
	var segment_start := current_value
	var preview_value := minf(current_value + shield_delta, maximum)
	var segment_width := maxf(preview_value - current_value, 2.0)
	segment.position = Vector2(bar.size.x * segment_start / maximum, 2.0)
	segment.size = Vector2(maxf(2.0, bar.size.x * segment_width / maximum), maxf(0.0, bar.size.y - 4.0))
	segment.color = PREVIEW_SHIELD_COLOR
	var flash_tint := Color("#FFFFFFFF")
	flash_tint.a = lerpf(0.2, 1.0, _view_data.get_flash_pulse())
	segment.self_modulate = flash_tint
	segment.visible = true


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
	segment.color = PREVIEW_GAIN_COLOR if delta > 0.0 else PREVIEW_LOSS_COLOR
	var flash_tint := Color("#FFFFFFFF")
	flash_tint.a = lerpf(0.15, 1.0, _view_data.get_flash_pulse())
	segment.self_modulate = flash_tint
	segment.visible = true


func _hide_preview_segments() -> void:
	hp_preview_segment.visible = false
	mp_preview_segment.visible = false
	fp_preview_segment.visible = false
	atb_preview_segment.visible = false


func _format_hp_resource(
	value: float,
	shield: float,
	maximum: float,
	delta: float,
	shield_delta: float,
	maximum_delta: float = 0.0
) -> String:
	var hp_str := _format_stat(value, delta)
	if not is_zero_approx(shield_delta):
		hp_str += " [color=#%s](+%.0f 护盾)[/color]" % [PREVIEW_SHIELD_COLOR.to_html(false), shield_delta]
	elif shield > 0.0:
		hp_str += " [color=#%s](+%.0f 盾)[/color]" % [SHIELD_VALUE_COLOR.to_html(false), shield]

	return "[right]%s / %s[/right]" % [
		hp_str,
		_format_stat(maximum, maximum_delta),
	]


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
		buffs_separator.visible = false
		buffs_container.visible = false
		return

	buffs_separator.visible = true
	buffs_container.visible = true
	for active: Dictionary in effects:
		var custom_text: String = String(active.get(&"text", ""))
		if not custom_text.is_empty():
			var label := BUFF_LABEL_SCENE.instantiate() as Label
			label.text = "• " + custom_text
			buffs_container.add_child(label)
			continue

		var effect: ActionEffectData = active.get(&"effect") as ActionEffectData
		if effect == null: continue
		var desc := effect.get_description()
		if desc.is_empty(): continue
		var remaining: int = active.get(&"remaining_count", 0)
		var label := BUFF_LABEL_SCENE.instantiate() as Label
		if remaining > 0:
			label.text = "• %s (剩余 %d 次)" % [desc, remaining]
		else:
			label.text = "• %s" % desc
		buffs_container.add_child(label)


func _is_stat_unlocked(feature_id: StringName, obey_unlocks: bool) -> bool:
	if not obey_unlocks:
		return true
	if _feature_unlock_state == null:
		return true
	return _feature_unlock_state.is_unlocked(feature_id)


func set_feature_visibility(
	feature_id: StringName,
	should_show: bool
) -> void:
	_feature_visibility[feature_id] = should_show
	if _view_data != null:
		_render_view_data(_view_data)


func bind_feature_unlock_state(
	feature_unlock_state: FeatureUnlockState
) -> void:
	_feature_unlock_state = feature_unlock_state
	if _feature_unlock_state == null:
		return

	if not _feature_unlock_state.feature_unlocked.is_connected(_on_feature_unlocked):
		_feature_unlock_state.feature_unlocked.connect(_on_feature_unlocked)

	if _view_data != null:
		_render_view_data(_view_data)


func _on_feature_unlocked(_feature_id: StringName) -> void:
	if _view_data != null:
		_render_view_data(_view_data)
