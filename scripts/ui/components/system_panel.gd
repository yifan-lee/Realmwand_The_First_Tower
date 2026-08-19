class_name SystemPanel
extends PanelContainer

signal save_loaded

const SAVE_SLOT_ROW_SCENE := preload("res://scenes/ui/components/save_slot_row.tscn")

@onready var save_name_input: LineEdit = $MarginContainer/Content/InputRow/SaveNameInput
@onready var create_button: Button = $MarginContainer/Content/InputRow/CreateButton
@onready var import_button: Button = $MarginContainer/Content/InputRow/ImportButton
@onready var save_rows: FocusableList = $MarginContainer/Content/SaveScroll/SaveRows
@onready var empty_label: Label = $MarginContainer/Content/EmptyLabel
@onready var status_label: Label = $MarginContainer/Content/StatusLabel

var _save_manager: SaveManager


func _ready() -> void:
	create_button.pressed.connect(_on_create_pressed)
	if import_button != null:
		import_button.pressed.connect(_on_import_pressed)
	save_name_input.text_submitted.connect(_on_name_submitted)



func bind_save_manager(save_manager: SaveManager) -> void:
	if _save_manager != null and _save_manager.saves_changed.is_connected(refresh_saves):
		_save_manager.saves_changed.disconnect(refresh_saves)
	_save_manager = save_manager
	if _save_manager != null:
		_save_manager.saves_changed.connect(refresh_saves)
	refresh_saves()


func refresh_saves() -> void:
	var focus_owner: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var had_panel_focus: bool = has_control_focus(focus_owner) if focus_owner != null else false
	var focused_row_index: int = save_rows.get_focused_row_index(focus_owner) if focus_owner != null else -1
	var focused_button_index: int = save_rows.get_focused_button_index(focus_owner) if focus_owner != null else 0
	if focused_button_index < 0:
		focused_button_index = 0

	save_rows.clear_rows()
	var saves: Array[Dictionary] = []
	if _save_manager != null:
		saves = _save_manager.list_saves()
	for save_data: Dictionary in saves:
		var row := SAVE_SLOT_ROW_SCENE.instantiate() as SaveSlotRow
		save_rows.add_row(row)
		row.display_save(save_data)
		row.load_requested.connect(_on_load_requested)
		row.overwrite_requested.connect(_on_overwrite_requested)
		row.delete_requested.connect(_on_delete_requested)
	empty_label.visible = save_rows.is_empty()

	if had_panel_focus:
		if focused_row_index >= 0:
			if not save_rows.is_empty():
				var target_index := clampi(focused_row_index, 0, save_rows.get_rows().size() - 1)
				save_rows.focus_row_at(target_index, focused_button_index)
			else:
				create_button.grab_focus()


func focus_first_control() -> void:
	save_name_input.grab_focus()


func has_control_focus(focus: Control) -> bool:
	if focus == save_name_input or focus == create_button or focus == import_button:
		return true
	return save_rows.has_row_focus(focus)


func navigate_focus(direction: Vector2i) -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus == save_name_input:
		if direction.x > 0:
			create_button.grab_focus()
		elif direction.y > 0 and not save_rows.is_empty():
			save_rows.focus_first_row(0)
		elif direction.y < 0:
			return false
		return true

	if focus == create_button:
		if direction.x < 0:
			save_name_input.grab_focus()
		elif direction.x > 0 and import_button != null:
			import_button.grab_focus()
		elif direction.y > 0 and not save_rows.is_empty():
			save_rows.focus_first_row(1)
		elif direction.y < 0:
			return false
		return true

	if focus == import_button:
		if direction.x < 0:
			create_button.grab_focus()
		elif direction.y > 0 and not save_rows.is_empty():
			save_rows.focus_first_row(2)
		elif direction.y < 0:
			return false
		return true

	if save_rows.has_row_focus(focus):
		if not save_rows.navigate_focus(direction):
			if direction.y < 0:
				var button_index = save_rows.get_focused_button_index(focus)
				if button_index == 2 and import_button != null:
					import_button.grab_focus()
				elif button_index >= 1:
					create_button.grab_focus()
				else:
					save_name_input.grab_focus()
		return true

	return false


func _on_import_pressed() -> void:
	if _save_manager == null:
		return
	var text := DisplayServer.clipboard_get().strip_edges()
	if text.is_empty():
		status_label.text = "❌ 导入失败：剪贴板为空！请先在 Google Sheet 中复制存档 JSON。"
		return
	if _save_manager.import_save_from_json_string(text):
		status_label.text = "✔ 成功从剪贴板导入存档！已加载角色与关卡数据。"
		save_loaded.emit()
	else:
		status_label.text = "❌ 导入失败：剪贴板中的内容不是合法的存档 JSON 数据。"



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
