class_name CombatantStatusPanel
extends PanelContainer

const PREVIEW_INCREASE_COLOR := Color(0.35, 0.9, 0.45, 1.0)
const PREVIEW_DECREASE_COLOR := Color(1.0, 0.35, 0.35, 1.0)
const HP_PREVIEW_INCREASE_COLOR := Color(0.35, 1.0, 0.45, 1.0)
const MP_PREVIEW_INCREASE_COLOR := Color(0.3, 0.75, 1.0, 1.0)
const PREVIEW_FLASH_ALPHA := 0.3
const PREVIEW_FLASH_DURATION := 0.4

@onready var portrait: TextureRect = (
	$MarginContainer/Content/Portrait
)
@onready var name_label: Label = (
	$MarginContainer/Content/NameLabel
)

@onready var hp_label: Label = (
	$MarginContainer/Content/HPSection/HPValues/HPLabel
)
@onready var hp_preview_label: Label = (
	$MarginContainer/Content/HPSection/HPValues/HPPreviewLabel
)
@onready var hp_bar: ProgressBar = (
	$MarginContainer/Content/HPSection/HPBarContainer/HPBar
)
@onready var hp_preview_bar: ProgressBar = (
	$MarginContainer/Content/HPSection/HPBarContainer/HPPreviewBar
)

@onready var mp_label: Label = (
	$MarginContainer/Content/MPSection/MPValues/MPLabel
)
@onready var mp_preview_label: Label = (
	$MarginContainer/Content/MPSection/MPValues/MPPreviewLabel
)
@onready var mp_bar: ProgressBar = (
	$MarginContainer/Content/MPSection/MPBarContainer/MPBar
)
@onready var mp_preview_bar: ProgressBar = (
	$MarginContainer/Content/MPSection/MPBarContainer/MPPreviewBar
)

@onready var atk_label: Label = (
	$MarginContainer/Content/Stats/ATKLabel
)
@onready var atk_preview_label: Label = (
	$MarginContainer/Content/Stats/ATKPreviewLabel
)
@onready var def_label: Label = (
	$MarginContainer/Content/Stats/DEFLabel
)
@onready var def_preview_label: Label = (
	$MarginContainer/Content/Stats/DEFPreviewLabel
)
@onready var spd_label: Label = (
	$MarginContainer/Content/Stats/SPDLabel
)
@onready var spd_preview_label: Label = (
	$MarginContainer/Content/Stats/SPDPreviewLabel
)

var current_data: CombatantStatusViewData
var preview_flash_tween: Tween
var hp_preview_is_decrease := false
var mp_preview_is_decrease := false



func set_data(data: CombatantStatusViewData) -> void:
	current_data = data
	_refresh()


func show_preview(
	preview: CombatantPreviewData
) -> void:
	_show_preview_values(preview)


func clear_preview() -> void:
	_stop_preview_flash()

	_clear_preview_label(hp_preview_label)
	_clear_preview_label(mp_preview_label)
	_clear_preview_label(atk_preview_label)
	_clear_preview_label(def_preview_label)
	_clear_preview_label(spd_preview_label)

	hp_preview_bar.visible = false
	mp_preview_bar.visible = false
	hp_preview_is_decrease = false
	mp_preview_is_decrease = false

	if current_data != null:
		hp_bar.max_value = current_data.max_hp
		hp_preview_bar.max_value = current_data.max_hp
		hp_bar.value = current_data.current_hp
		mp_bar.max_value = current_data.max_mp
		mp_preview_bar.max_value = current_data.max_mp
		mp_bar.value = current_data.current_mp


func _refresh() -> void:
	if current_data == null:
		return

	portrait.texture = current_data.portrait
	name_label.text = current_data.display_name

	hp_bar.max_value = current_data.max_hp
	hp_preview_bar.max_value = current_data.max_hp
	hp_bar.value = current_data.current_hp
	hp_label.text = "%.0f / %.0f" % [
		current_data.current_hp,
		current_data.max_hp,
	]

	mp_bar.max_value = current_data.max_mp
	mp_preview_bar.max_value = current_data.max_mp
	mp_bar.value = current_data.current_mp
	mp_label.text = "%.0f / %.0f" % [
		current_data.current_mp,
		current_data.max_mp,
	]

	atk_label.text = "%.0f" % current_data.atk
	def_label.text = "%.0f" % current_data.def
	spd_label.text = "%.0f" % current_data.spd

	clear_preview()

func _format_delta(value: float) -> String:
	if is_zero_approx(value):
		return ""

	if value > 0.0:
		return "+%.0f" % value

	return "%.0f" % value

func _set_preview_label(
	label: Label,
	value: float
) -> void:
	label.text = _format_delta(value)

	if is_zero_approx(value):
		label.remove_theme_color_override("font_color")
	elif value > 0.0:
		label.add_theme_color_override(
			"font_color",
			PREVIEW_INCREASE_COLOR
		)
	else:
		label.add_theme_color_override(
			"font_color",
			PREVIEW_DECREASE_COLOR
		)

func _clear_preview_label(label: Label) -> void:
	label.text = ""
	label.remove_theme_color_override("font_color")

func _show_preview_values(
	preview: CombatantPreviewData
) -> void:
	if current_data == null:
		return

	_stop_preview_flash()

	hp_preview_is_decrease = _show_bar_preview(
		hp_bar,
		hp_preview_bar,
		current_data.current_hp,
		maxf(
			current_data.max_hp + preview.max_hp_delta,
			1.0
		),
		preview.hp_delta,
		HP_PREVIEW_INCREASE_COLOR
	)
	mp_preview_is_decrease = _show_bar_preview(
		mp_bar,
		mp_preview_bar,
		current_data.current_mp,
		maxf(
			current_data.max_mp + preview.max_mp_delta,
			1.0
		),
		preview.mp_delta,
		MP_PREVIEW_INCREASE_COLOR
	)

	_set_resource_preview_label(
		hp_preview_label,
		preview.hp_delta,
		preview.max_hp_delta
	)
	_set_resource_preview_label(
		mp_preview_label,
		preview.mp_delta,
		preview.max_mp_delta
	)
	_set_preview_label(
		atk_preview_label,
		preview.atk_delta
	)
	_set_preview_label(
		def_preview_label,
		preview.def_delta
	)
	_set_preview_label(
		spd_preview_label,
		preview.spd_delta
	)

	if hp_preview_is_decrease or mp_preview_is_decrease:
		_start_preview_flash()


func _set_resource_preview_label(
	label: Label,
	current_delta: float,
	max_delta: float
) -> void:
	if not is_zero_approx(max_delta):
		var parts: Array[String] = []

		if not is_zero_approx(current_delta):
			parts.append(_format_delta(current_delta))

		parts.append(
			"Max %s" % _format_delta(max_delta)
		)
		label.text = "  ".join(parts)

		var color_value := max_delta

		if not is_zero_approx(current_delta):
			color_value = current_delta

		if color_value > 0.0:
			label.add_theme_color_override(
				"font_color",
				PREVIEW_INCREASE_COLOR
			)
		else:
			label.add_theme_color_override(
				"font_color",
				PREVIEW_DECREASE_COLOR
			)
		return

	_set_preview_label(label, current_delta)


func _show_bar_preview(
	current_bar: ProgressBar,
	preview_bar: ProgressBar,
	current_value: float,
	max_value: float,
	delta: float,
	increase_color: Color
) -> bool:
	current_bar.max_value = max_value
	preview_bar.max_value = max_value
	preview_bar.modulate.a = 1.0

	if is_zero_approx(delta):
		current_bar.value = current_value
		preview_bar.visible = false
		return false

	var preview_value := clampf(
		current_value + delta,
		0.0,
		max_value
	)
	var is_decrease := delta < 0.0

	if is_decrease:
		current_bar.value = preview_value
		preview_bar.value = current_value
		_set_preview_bar_color(
			preview_bar,
			PREVIEW_DECREASE_COLOR
		)
	else:
		current_bar.value = current_value
		preview_bar.value = preview_value
		_set_preview_bar_color(
			preview_bar,
			increase_color
		)

	preview_bar.visible = true
	return is_decrease


func _set_preview_bar_color(
	bar: ProgressBar,
	color: Color
) -> void:
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5
	bar.add_theme_stylebox_override("fill", fill_style)


func _start_preview_flash() -> void:
	preview_flash_tween = create_tween()
	preview_flash_tween.set_loops()
	preview_flash_tween.tween_method(
		_set_decrease_preview_alpha,
		1.0,
		PREVIEW_FLASH_ALPHA,
		PREVIEW_FLASH_DURATION
	)
	preview_flash_tween.tween_method(
		_set_decrease_preview_alpha,
		PREVIEW_FLASH_ALPHA,
		1.0,
		PREVIEW_FLASH_DURATION
	)


func _stop_preview_flash() -> void:
	if preview_flash_tween != null:
		preview_flash_tween.kill()
		preview_flash_tween = null

	hp_preview_bar.modulate.a = 1.0
	mp_preview_bar.modulate.a = 1.0


func _set_decrease_preview_alpha(alpha: float) -> void:
	if hp_preview_is_decrease:
		hp_preview_bar.modulate.a = alpha

	if mp_preview_is_decrease:
		mp_preview_bar.modulate.a = alpha
