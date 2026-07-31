class_name PlayerStatHUD
extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var hp_value: Label = %HpValue
@onready var hp_bar: ProgressBar = %HpBar
@onready var mp_value: Label = %MpValue
@onready var mp_bar: ProgressBar = %MpBar


func display_stats(
	view_data: ActorStatsViewData
) -> void:
	if view_data == null:
		clear_stats()
		return

	name_label.text = view_data.display_name

	_set_bar(
		hp_bar,
		hp_value,
		view_data.current_hp,
		view_data.max_hp
	)

	_set_bar(
		mp_bar,
		mp_value,
		view_data.current_mp,
		view_data.max_mp
	)


func clear_stats() -> void:
	name_label.text = ""

	_set_bar(hp_bar, hp_value, 0, 1)
	_set_bar(mp_bar, mp_value, 0, 1)


func _set_bar(
	bar: ProgressBar,
	value_label: Label,
	current_value: float,
	maximum_value: float
) -> void:
	var safe_maximum := maxf(
		maximum_value,
		1.0
	)

	var displayed_value := clampf(
		current_value,
		0.0,
		safe_maximum
	)

	bar.max_value = safe_maximum
	bar.value = displayed_value

	value_label.text = "%d / %d" % [
		roundi(displayed_value),
		roundi(safe_maximum),
	]
