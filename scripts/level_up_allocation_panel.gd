class_name LevelUpAllocationPanel
extends Control

signal allocation_completed

const ATTRIBUTES: Array[StringName] = [
	&"max_hp",
	&"max_mp",
	&"atk",
	&"def",
	&"spd",
]

@onready var title_label: Label = (
	$Panel/Margin/Content/Title
)
@onready var points_label: Label = (
	$Panel/Margin/Content/PointsLabel
)
@onready var status_panel: CombatantStatusPanel = (
	$Panel/Margin/Content/Body/StatusPanel
)
@onready var confirm_button: Button = (
	$Panel/Margin/Content/ConfirmButton
)

var player_data: Player
var points_to_allocate: int = 0
var allocations: Dictionary = {}
var count_labels: Dictionary = {}
var minus_buttons: Dictionary = {}
var plus_buttons: Dictionary = {}


func _ready() -> void:
	var rows := {
		&"max_hp": $Panel/Margin/Content/Body/Allocation/HPRow,
		&"max_mp": $Panel/Margin/Content/Body/Allocation/MPRow,
		&"atk": $Panel/Margin/Content/Body/Allocation/ATKRow,
		&"def": $Panel/Margin/Content/Body/Allocation/DEFRow,
		&"spd": $Panel/Margin/Content/Body/Allocation/SPDRow,
	}

	for attribute: StringName in ATTRIBUTES:
		var row: HBoxContainer = rows[attribute]
		var minus_button: Button = row.get_node("MinusButton")
		var plus_button: Button = row.get_node("PlusButton")

		count_labels[attribute] = row.get_node("CountLabel")
		minus_buttons[attribute] = minus_button
		plus_buttons[attribute] = plus_button
		minus_button.pressed.connect(
			_change_allocation.bind(attribute, -1)
		)
		plus_button.pressed.connect(
			_change_allocation.bind(attribute, 1)
		)

	confirm_button.pressed.connect(_confirm_allocation)


func open(player: Player) -> void:
	player_data = player
	points_to_allocate = player_data.unspent_attribute_points
	allocations.clear()

	for attribute: StringName in ATTRIBUTES:
		allocations[attribute] = 0

	title_label.text = "Level Up!  Level %d" % player_data.level
	status_panel.set_data(
		CombatantStatusViewData.from_player(player_data)
	)
	visible = true
	_refresh()
	(plus_buttons[&"max_hp"] as Button).grab_focus()


func _change_allocation(
	attribute: StringName,
	change: int
) -> void:
	var current_value: int = allocations[attribute]

	if change > 0 and _get_remaining_points() <= 0:
		return

	if change < 0 and current_value <= 0:
		return

	allocations[attribute] = current_value + change
	_refresh()


func _refresh() -> void:
	var remaining_points := _get_remaining_points()
	points_label.text = (
		"Points remaining: %d"
		% remaining_points
	)

	for attribute: StringName in ATTRIBUTES:
		var count: int = allocations[attribute]
		(count_labels[attribute] as Label).text = str(count)
		(minus_buttons[attribute] as Button).disabled = count <= 0
		(plus_buttons[attribute] as Button).disabled = (
			remaining_points <= 0
		)

	confirm_button.disabled = remaining_points != 0
	status_panel.show_preview(_build_preview())


func _get_remaining_points() -> int:
	var allocated_points := 0

	for attribute: StringName in ATTRIBUTES:
		allocated_points += int(allocations.get(attribute, 0))

	return points_to_allocate - allocated_points


func _build_preview() -> CombatantPreviewData:
	var preview := CombatantPreviewData.new()
	var balance := Player.BATTLE_BALANCE

	preview.hp_delta = (
		int(allocations[&"max_hp"])
		* balance.hp_per_point
	)
	preview.max_hp_delta = preview.hp_delta
	preview.mp_delta = (
		int(allocations[&"max_mp"])
		* balance.mp_per_point
	)
	preview.max_mp_delta = preview.mp_delta
	preview.atk_delta = (
		int(allocations[&"atk"])
		* balance.atk_per_point
	)
	preview.def_delta = (
		int(allocations[&"def"])
		* balance.def_per_point
	)
	preview.spd_delta = (
		int(allocations[&"spd"])
		* balance.spd_per_point
	)
	return preview


func _confirm_allocation() -> void:
	if (
		player_data == null
		or _get_remaining_points() != 0
		or not player_data.spend_attribute_points(allocations)
	):
		return

	status_panel.clear_preview()
	visible = false
	allocation_completed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if (
		not visible
		or not event.is_action_pressed("ui_cancel")
	):
		return

	get_viewport().set_input_as_handled()
