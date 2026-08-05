class_name SystemPanel
extends PanelContainer

signal save_loaded

const SAVE_SLOT_ROW_SCENE := preload("res://scenes/ui/components/save_slot_row.tscn")

@onready var save_name_input: LineEdit = $MarginContainer/Content/InputRow/SaveNameInput
@onready var create_button: Button = $MarginContainer/Content/InputRow/CreateButton
@onready var save_rows: VBoxContainer = $MarginContainer/Content/SaveScroll/SaveRows
@onready var empty_label: Label = $MarginContainer/Content/EmptyLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var _save_manager: SaveManager
var _rows: Array[SaveSlotRow] = []


func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	save_name_input.text_submitted.connect(_on_name_submitted)


func bind_save_manager(save_manager: SaveManager) -> void:
	if _save_manager != null and _save_manager.saves_changed.is_connected(refresh_saves):
		_save_manager.saves_changed.disconnect(refresh_saves)
	_save_manager = save_manager
	if _save_manager != null:
		_save_manager.saves_changed.connect(refresh_saves)
	refresh_saves()


func refresh_saves() -> void:
	for row: SaveSlotRow in _rows:
		row.queue_free()
	_rows.clear()
	var saves: Array[Dictionary] = []
	if _save_manager != null:
		saves = _save_manager.list_saves()
	for save_data: Dictionary in saves:
		# Runtime-only: row count depends on the user's save files.
		var row := SAVE_SLOT_ROW_SCENE.instantiate() as SaveSlotRow
		save_rows.add_child(row)
		row.display_save(save_data)
		row.load_requested.connect(_on_load_requested)
		row.overwrite_requested.connect(_on_overwrite_requested)
		row.delete_requested.connect(_on_delete_requested)
		_rows.append(row)
	empty_label.visible = _rows.is_empty()


func focus_first_control() -> void:
	if not _rows.is_empty():
		_rows.front().focus_first_button()
	else:
		save_name_input.grab_focus()


func _on_name_submitted(_text: String) -> void:
	_on_create_pressed()


func _on_create_pressed() -> void:
	if _save_manager == null:
		return
	var save_name := save_name_input.text.strip_edges()
	if save_name.is_empty():
		status_label.text = "请先输入存档名称。"
		save_name_input.grab_focus()
		return
	if _save_manager.create_save(save_name):
		status_label.text = "已创建存档：%s" % save_name
		save_name_input.clear()
	else:
		status_label.text = "创建存档失败。"


func _on_load_requested(slot_id: String) -> void:
	if _save_manager != null and _save_manager.load_save(slot_id):
		status_label.text = "读取成功。"
		save_loaded.emit()
	else:
		status_label.text = "读取存档失败。"


func _on_overwrite_requested(slot_id: String) -> void:
	if _save_manager != null and _save_manager.overwrite_save(slot_id):
		status_label.text = "已覆盖存档。"
	else:
		status_label.text = "覆盖存档失败。"


func _on_delete_requested(slot_id: String) -> void:
	if _save_manager != null and _save_manager.delete_save(slot_id):
		status_label.text = "已删除存档。"
	else:
		status_label.text = "删除存档失败。"
