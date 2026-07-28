class_name CombatantStatusPanel
extends PanelContainer

const PREVIEW_INCREASE_COLOR := Color(0.35, 0.9, 0.45, 1.0)
const PREVIEW_DECREASE_COLOR := Color(1.0, 0.35, 0.35, 1.0)

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
	$MarginContainer/Content/HPSection/HPBar
)

@onready var mp_label: Label = (
	$MarginContainer/Content/MPSection/MPValues/MPLabel
)
@onready var mp_preview_label: Label = (
	$MarginContainer/Content/MPSection/MPValues/MPPreviewLabel
)
@onready var mp_bar: ProgressBar = (
	$MarginContainer/Content/MPSection/MPBar
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



func set_data(data: CombatantStatusViewData) -> void:
	current_data = data
	_refresh()


func show_preview(
	preview: CombatantPreviewData
) -> void:
	_show_preview_values(preview)


func clear_preview() -> void:
	_clear_preview_label(hp_preview_label)
	_clear_preview_label(mp_preview_label)
	_clear_preview_label(atk_preview_label)
	_clear_preview_label(def_preview_label)
	_clear_preview_label(spd_preview_label)

	if current_data != null:
		hp_bar.value = current_data.current_hp
		mp_bar.value = current_data.current_mp


func _refresh() -> void:
	if current_data == null:
		return

	portrait.texture = current_data.portrait
	name_label.text = current_data.display_name

	hp_bar.max_value = current_data.max_hp
	hp_bar.value = current_data.current_hp
	hp_label.text = "%.0f / %.0f" % [
		current_data.current_hp,
		current_data.max_hp,
	]

	mp_bar.max_value = current_data.max_mp
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

	hp_bar.value = clampf(
		current_data.current_hp + preview.hp_delta,
		0.0,
		current_data.max_hp
	)
	mp_bar.value = clampf(
		current_data.current_mp + preview.mp_delta,
		0.0,
		current_data.max_mp
	)

	_set_preview_label(
		hp_preview_label,
		preview.hp_delta
	)
	_set_preview_label(
		mp_preview_label,
		preview.mp_delta
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
