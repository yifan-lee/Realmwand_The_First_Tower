class_name ActorStatsPanel
extends PanelContainer

@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %NameLabel
@onready var hp_value: Label = %HpValue
@onready var mp_value: Label = %MpValue
@onready var atk_value: Label = %AtkValue
@onready var def_value: Label = %DefValue
@onready var spd_value: Label = %SpdValue


func display_stats(
	view_data: ActorStatsViewData
) -> void:
	if view_data == null:
		clear_stats()
		return

	portrait.texture = view_data.portrait
	portrait.visible = view_data.portrait != null

	name_label.text = view_data.display_name

	hp_value.text = "%s / %s" % [
		_format_stat(
			view_data.current_hp,
			view_data.current_hp_delta
		),
		_format_stat(
			view_data.max_hp,
			view_data.max_hp_delta
		),
	]

	mp_value.text = "%s / %s" % [
		_format_stat(
			view_data.current_mp,
			view_data.current_mp_delta
		),
		_format_stat(
			view_data.max_mp,
			view_data.max_mp_delta
		),
	]

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
	portrait.texture = null
	portrait.visible = false

	name_label.text = ""
	hp_value.text = ""
	mp_value.text = ""
	atk_value.text = ""
	def_value.text = ""
	spd_value.text = ""


func _format_stat(
	value: float,
	delta: float
) -> String:
	var rounded_value: int = roundi(value)
	var rounded_delta: int = roundi(delta)

	if rounded_delta == 0:
		return str(rounded_value)

	var sign_text: String = ""

	if rounded_delta > 0:
		sign_text = "+"

	return "%d (%s%d)" % [
		rounded_value,
		sign_text,
		rounded_delta,
	]
