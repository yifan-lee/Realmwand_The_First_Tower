class_name FocusableList
extends VBoxContainer

var _rows: Array[Control] = []


func clear_rows() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_rows.clear()


func add_row(row: Control) -> void:
	add_child(row)
	_rows.append(row)


func get_rows() -> Array[Control]:
	return _rows


func is_empty() -> bool:
	return _rows.is_empty()


func focus_first_row(fallback_button_index: int = 0) -> bool:
	if _rows.is_empty():
		return false
	_focus_row(_rows.front(), fallback_button_index)
	return true


func is_first_row_focused() -> bool:
	if _rows.is_empty():
		return false
	var focus_owner := get_viewport().gui_get_focus_owner()
	var first_row = _rows.front()
	if first_row == focus_owner:
		return true
	if first_row.has_method("get_focused_button_index"):
		return first_row.get_focused_button_index(focus_owner) >= 0
	return false


func has_row_focus(focus: Control = null) -> bool:
	var resolved_focus := focus
	if resolved_focus == null:
		resolved_focus = get_viewport().gui_get_focus_owner()
	return get_focused_row_index(resolved_focus) >= 0


func navigate_focus(direction: Vector2i) -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	var current_index := get_focused_row_index(focus_owner)
	if current_index < 0:
		return false
		
	var current_row = _rows[current_index]
	var button_index = 0
	if current_row.has_method("get_focused_button_index"):
		button_index = current_row.get_focused_button_index(focus_owner)
		if button_index < 0:
			button_index = 0
			
	if direction.x != 0:
		if current_row.has_method("focus_button"):
			current_row.focus_button(button_index + direction.x)
			return true
		return false
		
	if direction.y != 0:
		var next_index := current_index + direction.y
		if next_index >= 0 and next_index < _rows.size():
			_focus_row(_rows[next_index], button_index)
			return true
		return false
		
	return false


func get_focused_row_index(focus: Control) -> int:
	for i in range(_rows.size()):
		if _rows[i] == focus:
			return i
		if _rows[i].has_method("get_focused_button_index"):
			if _rows[i].get_focused_button_index(focus) >= 0:
				return i
	return -1


func get_focused_button_index(focus: Control = null) -> int:
	var resolved_focus := focus
	if resolved_focus == null:
		resolved_focus = get_viewport().gui_get_focus_owner()
	var row_index = get_focused_row_index(resolved_focus)
	if row_index >= 0:
		var row = _rows[row_index]
		if row.has_method("get_focused_button_index"):
			return row.get_focused_button_index(resolved_focus)
	return -1


func _focus_row(row: Control, fallback_button_index: int) -> void:
	if row.has_method("focus_button"):
		row.focus_button(fallback_button_index)
	else:
		row.grab_focus()
