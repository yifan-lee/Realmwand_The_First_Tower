class_name NpcInteractionUI
extends CanvasLayer

signal option_selected(option_index: int)
signal option_focused(option_index: int)
signal advance_requested
signal close_requested
signal closed

enum Mode { CHOICES, DIALOGUE }

const SUCCESS_COLOR := Color("#32FF7DFF")
const ERROR_COLOR := Color("#FF4155FF")

@export var option_row_scene: PackedScene

@onready var interaction_root: Control = $InteractionRoot
@onready var title_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/Title
@onready var stats_panel: ActorStatsPanel = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/ActorStatsPanel
@onready var prompt_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/PromptLabel
@onready var options_scroll: ScrollContainer = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/OptionsScroll
@onready var option_rows: VBoxContainer = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/OptionsScroll/OptionRows
@onready var cancel_button: Button = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/CancelButton
@onready var feedback_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/FeedbackLabel
@onready var hint_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/HintLabel

var _mode: Mode = Mode.CHOICES
var _rows: Array[SelectableListRow] = []
var _selected_index: int = 0


func _ready() -> void:
	cancel_button.pressed.connect(close_requested.emit)
	cancel_button.focus_entered.connect(_select_cancel)


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if _mode == Mode.DIALOGUE:
		if event is InputEventKey and event.pressed and not event.echo:
			advance_requested.emit()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"move_up"):
		_move_selection(-1)
	elif event.is_action_pressed(&"move_down"):
		_move_selection(1)
	elif event.is_action_pressed(&"ui_accept"):
		_activate_selection()
	elif event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"toggle_menu"):
		close_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func open_choices(
	npc_name: String,
	prompt: String,
	entries: Array[Resource],
	labels: Array[String],
	tooltips: Array[String],
	disabled_flags: Array[bool] = []
) -> void:
	_mode = Mode.CHOICES
	title_label.text = npc_name
	prompt_label.text = prompt
	feedback_label.text = ""
	stats_panel.visible = true
	options_scroll.visible = true
	cancel_button.visible = true
	hint_label.text = "↑↓ 选择   确认键兑换   菜单键取消"
	_rebuild_rows(entries, labels, tooltips, disabled_flags)
	_selected_index = 0
	if _selected_index < _rows.size() and _rows[_selected_index].disabled:
		_move_selection(1)
	else:
		_sync_focus()
	interaction_root.visible = true


func open_dialogue(npc_name: String, dialogue: String) -> void:
	_mode = Mode.DIALOGUE
	title_label.text = npc_name
	prompt_label.text = dialogue
	feedback_label.text = ""
	stats_panel.visible = true
	options_scroll.visible = false
	cancel_button.visible = false
	hint_label.text = "按确认键继续   菜单键取消"
	_clear_rows()
	interaction_root.visible = true


func update_choices(labels: Array[String], disabled_flags: Array[bool] = []) -> void:
	for index: int in mini(labels.size(), _rows.size()):
		_rows[index].text = labels[index]
		if index < disabled_flags.size():
			_rows[index].disabled = disabled_flags[index]


func show_player_stats(player: Player) -> void:
	if player == null:
		stats_panel.unbind_actor()
		return
	stats_panel.bind_actor(player, ActorStatsDisplayProfile.menu())
	stats_panel.clear_preview()


func show_player_stat_preview(player: Player, stat_id: StringName = &"", amount: float = 0.0) -> void:
	if player == null:
		stats_panel.unbind_actor()
		return
	stats_panel.bind_actor(player, ActorStatsDisplayProfile.menu())
	var preview_dict := player.get_permanent_stat_increase_preview(stat_id, amount)
	var preview_data := ActorStatsPreviewData.new()
	preview_data.current_hp_delta = preview_dict.get(&"current_hp", player.current_hp) - player.current_hp
	preview_data.max_hp_delta = preview_dict.get(&"max_hp", player.get_max_hp()) - player.get_max_hp()
	preview_data.current_mp_delta = preview_dict.get(&"current_mp", player.current_mp) - player.current_mp
	preview_data.max_mp_delta = preview_dict.get(&"max_mp", player.get_max_mp()) - player.get_max_mp()
	preview_data.atk_delta = preview_dict.get(&"atk", player.get_atk()) - player.get_atk()
	preview_data.def_delta = preview_dict.get(&"def", player.get_def()) - player.get_def()
	preview_data.spd_delta = preview_dict.get(&"spd", player.get_spd()) - player.get_spd()
	preview_data.fp_recovery_spd_delta = preview_dict.get(&"fp_recovery", player.get_fp_recovery_spd()) - player.get_fp_recovery_spd()
	stats_panel.set_preview(preview_data)


func show_transaction_result(success: bool, message: String) -> void:
	feedback_label.text = message
	feedback_label.modulate = SUCCESS_COLOR if success else ERROR_COLOR


func close() -> void:
	interaction_root.visible = false
	_clear_rows()
	stats_panel.unbind_actor()
	closed.emit()


func is_open() -> bool:
	return interaction_root != null and interaction_root.visible


func _rebuild_rows(entries: Array[Resource], labels: Array[String], tooltips: Array[String], disabled_flags: Array[bool]) -> void:
	_clear_rows()
	if option_row_scene == null:
		push_error("NpcInteractionUI requires an option row scene.")
		return
	var count: int = maxi(entries.size(), labels.size())
	for index: int in count:
		var entry: Resource = entries[index] if index < entries.size() else null
		var label := labels[index] if index < labels.size() else ""
		var tooltip := tooltips[index] if index < tooltips.size() else ""
		var icon: Texture2D = entry.get("icon") as Texture2D if entry != null and "icon" in entry else null
		var is_disabled = disabled_flags[index] if index < disabled_flags.size() else false
		var row := option_row_scene.instantiate() as SelectableListRow
		option_rows.add_child(row)
		_rows.append(row)
		row.setup(entry, label, icon, tooltip, is_disabled)
		row.entry_selected.connect(_on_row_selected.bind(index))
		row.entry_focused.connect(_on_row_focused.bind(index))


func _clear_rows() -> void:
	for child: Node in option_rows.get_children():
		option_rows.remove_child(child)
		child.queue_free()
	_rows.clear()


func _move_selection(direction: int) -> void:
	_selected_index = posmod(_selected_index + direction, _rows.size() + 1)
	feedback_label.text = ""
	_sync_focus()
	if _selected_index < _rows.size():
		option_focused.emit(_selected_index)


func _activate_selection() -> void:
	if _selected_index == _rows.size():
		close_requested.emit()
	elif _selected_index >= 0 and _selected_index < _rows.size():
		if not _rows[_selected_index].disabled:
			option_selected.emit(_selected_index)


func _on_row_selected(_entry: Resource, index: int) -> void:
	if index >= 0 and index < _rows.size() and _rows[index].disabled:
		return
	option_selected.emit(index)


func _on_row_focused(_entry: Resource, index: int) -> void:
	_selected_index = index
	feedback_label.text = ""
	option_focused.emit(index)


func _select_cancel() -> void:
	_selected_index = _rows.size()
	feedback_label.text = ""


func _sync_focus() -> void:
	if _selected_index == _rows.size():
		cancel_button.grab_focus()
	elif _selected_index >= 0 and _selected_index < _rows.size():
		_rows[_selected_index].grab_focus()
