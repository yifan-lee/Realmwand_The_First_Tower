class_name NpcInteractionUI
extends CanvasLayer

signal option_selected(option_index: int)
signal option_focused(option_index: int)
signal advance_requested
signal close_requested
signal closed

enum Mode {CHOICES, DIALOGUE}

@export var option_row_scene: PackedScene

@onready var interaction_root: Control = $InteractionRoot
@onready var title_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/Title
@onready var stats_panel: ActorStatsPanel = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/ActorStatsPanel
@onready var prompt_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/PromptLabel
@onready var options_scroll: ScrollContainer = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/OptionsScroll
@onready var option_rows: VBoxContainer = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/OptionsScroll/OptionRows
@onready var feedback_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/DialoguePanel/DialogueMargin/DialogueContent/FeedbackLabel
@onready var hint_label: Label = $InteractionRoot/Backdrop/Center/Panel/Margin/Content/HintLabel
@onready var selection_detail_panel: EntryInfoPanel = $InteractionRoot/SelectionDetailPanel

var _mode: Mode = Mode.CHOICES
var _rows: Array[SelectableListRow] = []
var _selected_index: int = 0
var _input_gate = preload("res://scripts/ui/components/ui_input_gate.gd").new()


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if not _input_gate.filter_event(event):
		get_viewport().set_input_as_handled()
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
	disabled_flags: Array[bool] = [],
	trailing_texts: Array[String] = []
) -> void:
	_input_gate.reset_gate()
	_mode = Mode.CHOICES
	title_label.text = npc_name
	prompt_label.text = prompt
	feedback_label.text = ""
	stats_panel.visible = true
	options_scroll.visible = true
	hint_label.text = "↑↓ 选择   确认键兑换   菜单键取消"
	_rebuild_rows(entries, labels, tooltips, disabled_flags, trailing_texts)
	_selected_index = 0
	if _selected_index < _rows.size() and _rows[_selected_index].disabled:
		_move_selection(1)
	else:
		_sync_focus()
	interaction_root.visible = true


func open_dialogue(npc_name: String, dialogue: String) -> void:
	_input_gate.reset_gate()
	_mode = Mode.DIALOGUE
	title_label.text = npc_name
	prompt_label.text = dialogue
	feedback_label.text = ""
	stats_panel.visible = true
	options_scroll.visible = false
	if selection_detail_panel != null:
		selection_detail_panel.clear_info()
	hint_label.text = "按确认键继续   菜单键取消"
	_clear_rows()
	interaction_root.visible = true


func update_choices(labels: Array[String], disabled_flags: Array[bool] = [], trailing_texts: Array[String] = []) -> void:
	var entry_count := _rows.size() - 1
	for index: int in mini(labels.size(), entry_count):
		_rows[index].text = labels[index]
		if index < disabled_flags.size():
			_rows[index].disabled = disabled_flags[index]
		if index < trailing_texts.size() and _rows[index].trailing_label != null:
			_rows[index].trailing_label.text = trailing_texts[index]
			_rows[index].trailing_label.visible = not trailing_texts[index].is_empty()


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
	stats_panel.preview_permanent_increase(stat_id, amount)


func show_transaction_result(success: bool, message: String) -> void:
	feedback_label.text = message
	feedback_label.modulate = UIColors.ACCENT_SUCCESS if success else UIColors.ACCENT_DANGER


func show_entry_detail(entry: Variant) -> void:
	if selection_detail_panel != null:
		if entry is SkillData:
			selection_detail_panel.display_skill(entry as SkillData)
		elif entry is ItemData:
			selection_detail_panel.display_item(entry as ItemData)
		elif entry is EntryInfoViewData:
			selection_detail_panel.display_info(entry as EntryInfoViewData)
		else:
			selection_detail_panel.clear_info()

	stats_panel.set_preview(entry)


func close() -> void:
	interaction_root.visible = false
	_clear_rows()
	stats_panel.unbind_actor()
	if selection_detail_panel != null:
		selection_detail_panel.clear_info()
	closed.emit()


func is_open() -> bool:
	return interaction_root != null and interaction_root.visible


func _rebuild_rows(
	entries: Array[Resource],
	labels: Array[String],
	tooltips: Array[String],
	disabled_flags: Array[bool],
	trailing_texts: Array[String] = []
) -> void:
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
		var trailing := trailing_texts[index] if index < trailing_texts.size() else ""
		var row := option_row_scene.instantiate() as SelectableListRow
		option_rows.add_child(row)
		_rows.append(row)
		row.setup(entry, label, icon, tooltip, is_disabled, trailing)
		row.entry_selected.connect(_on_row_selected.bind(index))
		row.entry_focused.connect(_on_row_focused.bind(index))

	# 取消选项作为同级别的最后一行选项
	var cancel_row := option_row_scene.instantiate() as SelectableListRow
	option_rows.add_child(cancel_row)
	_rows.append(cancel_row)
	var cancel_index := _rows.size() - 1
	cancel_row.setup(null, "取消", null, "", false)
	cancel_row.entry_selected.connect(func(_e): close_requested.emit())
	cancel_row.entry_focused.connect(func(_e):
		_selected_index = cancel_index
		feedback_label.text = ""
		show_entry_detail(null)
	)


func _clear_rows() -> void:
	for child: Node in option_rows.get_children():
		option_rows.remove_child(child)
		child.queue_free()
	_rows.clear()


func _move_selection(direction: int) -> void:
	if _rows.is_empty():
		return
	_selected_index = posmod(_selected_index + direction, _rows.size())
	feedback_label.text = ""
	_sync_focus()
	if _selected_index < _rows.size() - 1:
		option_focused.emit(_selected_index)


func _activate_selection() -> void:
	if _selected_index == _rows.size() - 1:
		close_requested.emit()
	elif _selected_index >= 0 and _selected_index < _rows.size() - 1:
		if not _rows[_selected_index].disabled:
			option_selected.emit(_selected_index)


func _on_row_selected(_entry: Resource, index: int) -> void:
	if index >= 0 and index < _rows.size() and _rows[index].disabled:
		return
	if index == _rows.size() - 1:
		close_requested.emit()
		return
	option_selected.emit(index)


func _on_row_focused(entry: Resource, index: int) -> void:
	_selected_index = index
	feedback_label.text = ""
	show_entry_detail(entry)
	if index < _rows.size() - 1:
		option_focused.emit(index)


func _sync_focus() -> void:
	if _selected_index >= 0 and _selected_index < _rows.size():
		_rows[_selected_index].grab_focus()
		var entry: Resource = _rows[_selected_index].entry_data if _rows[_selected_index] != null else null
		show_entry_detail(entry)
