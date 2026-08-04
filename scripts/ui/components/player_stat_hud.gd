class_name PlayerStatHUD
extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var hp_value: Label = %HpValue
@onready var hp_bar: ProgressBar = %HpBar
@onready var mp_value: Label = %MpValue
@onready var mp_bar: ProgressBar = %MpBar
@onready var fp_value: Label = %FpValue
@onready var fp_bar: ProgressBar = %FpBar

var _current_view: ActorStatsViewData


func _process(_delta: float) -> void:
	if _current_view == null or not _current_view.has_any_preview():
		return
	_update_bars()


func display_stats(
	view_data: ActorStatsViewData
) -> void:
	_current_view = view_data
	if view_data == null:
		clear_stats()
		return

	name_label.text = view_data.display_name
	_update_bars()


func _update_bars() -> void:
	if _current_view == null:
		return
	_set_bar(
		hp_bar,
		hp_value,
		_current_view.current_hp,
		_current_view.max_hp,
		_current_view.get_hp_bar_value(),
		_current_view.current_hp_delta
	)
	_set_bar(
		mp_bar,
		mp_value,
		_current_view.current_mp,
		_current_view.max_mp,
		_current_view.get_mp_bar_value(),
		_current_view.current_mp_delta
	)
	_set_bar(
		fp_bar,
		fp_value,
		_current_view.current_fp,
		_current_view.max_fp,
		_current_view.get_fp_bar_value(),
		_current_view.current_fp_delta
	)


func clear_stats() -> void:
	_current_view = null
	name_label.text = ""

	_set_bar(hp_bar, hp_value, 0, 1)
	_set_bar(mp_bar, mp_value, 0, 1)
	_set_bar(fp_bar, fp_value, 0, 1)


func _set_bar(
	bar: ProgressBar,
	value_label: Label,
	current_value: float,
	maximum_value: float,
	bar_value: float = -1.0,
	delta_value: float = 0.0
) -> void:
	var safe_maximum := maxf(
		maximum_value,
		1.0
	)

	var effective_bar_value := current_value
	if bar_value >= 0.0:
		effective_bar_value = bar_value

	var displayed_value := clampf(
		effective_bar_value,
		0.0,
		safe_maximum
	)

	bar.max_value = safe_maximum
	bar.value = displayed_value

	var base_int := roundi(clampf(current_value, 0.0, safe_maximum))
	if not is_zero_approx(delta_value):
		var target_int := roundi(clampf(current_value + delta_value, 0.0, safe_maximum))
		value_label.text = "%d->%d / %d" % [base_int, target_int, roundi(safe_maximum)]
	else:
		value_label.text = "%d / %d" % [
			base_int,
			roundi(safe_maximum),
		]
