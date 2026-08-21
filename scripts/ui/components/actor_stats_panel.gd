class_name ActorStatsPanel
extends PanelContainer

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
@onready var hp_shield_segment: ColorRect = $MarginContainer/Content/Resources/HpRow/HpBar/HpShieldSegment
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


func set_preview(preview: Variant = null, extra_param: Variant = null) -> void:
	if preview == null:
		_preview = null
		refresh()
		return

	if preview is ActorStatsPreviewData:
		var p_data := preview as ActorStatsPreviewData
		_preview = p_data if p_data.has_any_preview() else null
		refresh()
		return

	if _bound_actor != null:
		var created := ActorStatsFactory.create_preview_from_entry(_bound_actor, preview, extra_param)
		_preview = created if created != null and created.has_any_preview() else null
	else:
		_preview = null

	refresh()


func preview_permanent_increase(stat_id: StringName, amount: float) -> void:
	if _bound_actor is Player and not stat_id.is_empty() and not is_zero_approx(amount):
		var created := ActorStatsFactory.create_preview_from_permanent_increase(_bound_actor as Player, stat_id, amount)
		_preview = created if created != null and created.has_any_preview() else null
	else:
		_preview = null
	refresh()


func clear_preview() -> void:
	_preview = null
	refresh()


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


func refresh() -> void:
	if _bound_actor == null:
		clear_stats()
		return

	var profile := _profile if _profile != null else ActorStatsDisplayProfile.menu()
	_view_data = ActorStatsFactory.create_view_data(
		_bound_actor,
		profile,
		_context,
		_preview
	)
	_render_view_data(_view_data)


func display_stats(view_data: ActorStatsViewData) -> void:
	_view_data = view_data
	_render_view_data(_view_data)


func _render_view_data(view_data: ActorStatsViewData) -> void:
	if view_data == null:
		clear_stats()
		return

	var profile: ActorStatsDisplayProfile = _profile if _profile != null else ActorStatsDisplayProfile.menu()
	var obey_unlocks := profile.obey_feature_unlocks

	# Portrait
	if view_data.portrait != null:
		portrait.texture = view_data.portrait
		portrait.visible = true
	else:
		portrait.texture = null
		portrait.visible = false

	# Name & Description
	name_label.text = view_data.display_name
	name_label.visible = not view_data.display_name.is_empty()
	description_label.text = view_data.description
	description_label.visible = not view_data.description.is_empty()
	header_details.visible = name_label.visible or description_label.visible

	# Progression & CP
	var show_progression := profile.show_progression and view_data.has_progression() and _is_stat_unlocked(&"level", obey_unlocks)
	level_label.visible = show_progression
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
		fp_value.text = _format_resource(
			view_data.current_fp,
			view_data.max_fp,
			view_data.current_fp_delta,
			view_data.max_fp_delta
		)

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

	var effective_hp_max := _view_data.get_effective_hp_max()
	hp_bar.max_value = effective_hp_max
	mp_bar.max_value = maxf(_view_data.get_preview_max_mp(), 1.0)

	# Base HP Bar & Preview
	var preview_hp := _view_data.get_preview_hp()
	hp_bar.value = minf(_view_data.current_hp, preview_hp)

	# Steady State Shield Layer
	if _view_data.current_shield > 0.0 and hp_bar.size.x > 0.0:
		var shield_start := minf(_view_data.current_hp, preview_hp)
		var shield_width := _view_data.current_shield
		hp_shield_segment.position = Vector2(hp_bar.size.x * shield_start / effective_hp_max, 2.0)
		hp_shield_segment.size = Vector2(maxf(2.0, hp_bar.size.x * shield_width / effective_hp_max), maxf(0.0, hp_bar.size.y - 4.0))
		hp_shield_segment.color = UIColors.SHIELD_BAR
		hp_shield_segment.self_modulate = Color.WHITE
		hp_shield_segment.visible = true
	else:
		hp_shield_segment.visible = false

	# HP / Shield Preview Flashing
	if _view_data.has_shield_change():
		if _view_data.current_shield_delta > 0.0:
			# Shield gain preview: flashes immediately after (current_hp + current_shield)
			var preview_start := _view_data.current_hp + _view_data.current_shield
			var preview_width := _view_data.current_shield_delta
			hp_preview_segment.position = Vector2(hp_bar.size.x * preview_start / effective_hp_max, 2.0)
			hp_preview_segment.size = Vector2(maxf(2.0, hp_bar.size.x * preview_width / effective_hp_max), maxf(0.0, hp_bar.size.y - 4.0))
			hp_preview_segment.color = UIColors.PREVIEW_SHIELD
			var flash_tint := Color.WHITE
			flash_tint.a = lerpf(0.2, 1.0, _view_data.get_flash_pulse())
			hp_preview_segment.self_modulate = flash_tint
			hp_preview_segment.visible = true
		else:
			# Shield loss preview: flashes on the reduced portion of shield
			var preview_start := _view_data.current_hp + maxf(0.0, _view_data.current_shield + _view_data.current_shield_delta)
			var preview_width := absf(_view_data.current_shield_delta)
			hp_preview_segment.position = Vector2(hp_bar.size.x * preview_start / effective_hp_max, 2.0)
			hp_preview_segment.size = Vector2(maxf(2.0, hp_bar.size.x * preview_width / effective_hp_max), maxf(0.0, hp_bar.size.y - 4.0))
			hp_preview_segment.color = UIColors.PREVIEW_LOSS
			var flash_tint := Color.WHITE
			flash_tint.a = lerpf(0.2, 1.0, _view_data.get_flash_pulse())
			hp_preview_segment.self_modulate = flash_tint
			hp_preview_segment.visible = true
	elif _view_data.has_hp_change():
		_update_preview_segment(hp_preview_segment, hp_bar, _view_data.current_hp, _view_data.current_hp_delta)
	else:
		hp_preview_segment.visible = false

	# MP Preview
	_update_preview_segment(mp_preview_segment, mp_bar, _view_data.current_mp, _view_data.current_mp_delta)

	# FP Preview
	var profile: ActorStatsDisplayProfile = _profile if _profile != null else ActorStatsDisplayProfile.menu()
	if profile.fp_display_mode == ActorStatsDisplayProfile.FpDisplayMode.PROGRESS_BAR:
		fp_bar.max_value = maxf(_view_data.get_preview_max_fp(), 1.0)
		_update_preview_segment(fp_preview_segment, fp_bar, _view_data.current_fp, _view_data.current_fp_delta)
	else:
		fp_preview_segment.visible = false

	# ATB Preview
	if profile.atb_display_mode == ActorStatsDisplayProfile.AtbDisplayMode.BAR:
		atb_bar.max_value = maxf(_view_data.max_atb, 1.0)
		_update_preview_segment(atb_preview_segment, atb_bar, _view_data.current_atb, _view_data.current_atb_delta)
	else:
		atb_preview_segment.visible = false


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
	segment.color = UIColors.PREVIEW_GAIN if delta > 0.0 else UIColors.PREVIEW_LOSS
	var flash_tint := Color("#FFFFFFFF")
	flash_tint.a = lerpf(0.15, 1.0, _view_data.get_flash_pulse())
	segment.self_modulate = flash_tint
	segment.visible = true


func _hide_preview_segments() -> void:
	hp_shield_segment.visible = false
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
		if shield > 0.0:
			var sign_str := "+" if shield_delta > 0 else ""
			var delta_color: Color = UIColors.PREVIEW_GAIN if shield_delta > 0 else UIColors.PREVIEW_LOSS
			hp_str += " [color=#%s](%.0f [/color][color=#%s](%s%.0f)[/color][color=#%s])[/color]" % [
				UIColors.SHIELD_VALUE.to_html(false),
				shield,
				delta_color.to_html(false),
				sign_str,
				shield_delta,
				UIColors.SHIELD_VALUE.to_html(false)
			]
		else:
			var sign_str := "+" if shield_delta > 0 else ""
			var delta_color: Color = UIColors.PREVIEW_GAIN if shield_delta > 0 else UIColors.PREVIEW_LOSS
			hp_str += " [color=#%s](%s%.0f)[/color]" % [delta_color.to_html(false), sign_str, shield_delta]
	elif shield > 0.0:
		hp_str += " [color=#%s](%.0f)[/color]" % [UIColors.SHIELD_VALUE.to_html(false), shield]

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
		return "[color=#%s]%d[/color]" % [UIColors.TEXT_MAIN.to_html(false), rounded_value]

	var delta_color: Color = UIColors.PREVIEW_GAIN if rounded_delta > 0 else UIColors.PREVIEW_LOSS
	return "[color=#%s]%d[/color] [color=#%s](%+d)[/color]" % [
		UIColors.TEXT_MAIN.to_html(false),
		rounded_value,
		delta_color.to_html(false),
		rounded_delta,
	]


func _format_float_stat(
	value: float,
	delta: float
) -> String:
	if is_zero_approx(delta):
		return "[color=#%s]%.1f[/color]" % [UIColors.TEXT_MAIN.to_html(false), value]

	var delta_color: Color = UIColors.PREVIEW_GAIN if delta > 0 else UIColors.PREVIEW_LOSS
	var sign_str := "+" if delta > 0 else ""
	return "[color=#%s]%.1f[/color] [color=#%s](%s%.1f)[/color]" % [
		UIColors.TEXT_MAIN.to_html(false),
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
	var buff_idx: int = 1
	for active: Dictionary in effects:
		var text: String = String(active.get(&"text", ""))
		if text.is_empty():
			continue

		var polarity_val: int = int(active.get(&"polarity", StatusEffectData.Polarity.BUFF))
		var color: Color = UIColors.BUFF
		if polarity_val == StatusEffectData.Polarity.DEBUFF:
			color = UIColors.DEBUFF
		elif polarity_val == StatusEffectData.Polarity.NEUTRAL:
			color = UIColors.NEUTRAL

		var label := BUFF_LABEL_SCENE.instantiate() as Label
		label.text = "%d. %s" % [buff_idx, text]
		label.modulate = color
		buffs_container.add_child(label)
		buff_idx += 1


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
