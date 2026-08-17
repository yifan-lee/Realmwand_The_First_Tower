class_name NpcInteractionManager
extends Node

var _player: Player
var _ui: NpcInteractionUI
var _active_npc: Node


func setup(player: Player, ui: NpcInteractionUI) -> void:
	_player = player
	_ui = ui
	EventBus.npc_interaction_requested.connect(_on_interaction_requested)
	_ui.option_selected.connect(_on_option_selected)
	_ui.option_focused.connect(_on_option_focused)
	_ui.advance_requested.connect(_on_advance_requested)
	_ui.close_requested.connect(_close_interaction)
	_ui.closed.connect(_on_ui_closed)


func is_active() -> bool:
	return _ui != null and _ui.is_open()


func _on_interaction_requested(npc: Node, player: Player) -> void:
	if npc == null or player != _player or is_active():
		return
	if not npc.has_method(&"begin_interaction"):
		push_warning("NPC does not implement begin_interaction().")
		return
	_active_npc = npc
	_player.set_input_enabled(false)
	npc.call(&"begin_interaction", _ui, _player)


func _on_option_selected(option_index: int) -> void:
	if not is_active() or _active_npc == null:
		return
	if _active_npc.has_method(&"handle_dialogue_option"):
		_active_npc.call(&"handle_dialogue_option", option_index, _ui, _player)


func _on_option_focused(option_index: int) -> void:
	if not is_active() or _active_npc == null:
		return
	if _active_npc.has_method(&"handle_dialogue_option_focused"):
		_active_npc.call(&"handle_dialogue_option_focused", option_index, _ui, _player)


func _on_advance_requested() -> void:
	if not is_active() or _active_npc == null:
		return
	if _active_npc.has_method(&"advance_dialogue"):
		_active_npc.call(&"advance_dialogue", _ui, _player)
	else:
		_close_interaction()


func _close_interaction() -> void:
	if not is_active():
		return
	_ui.close()
	_on_ui_closed()


func _on_ui_closed() -> void:
	if _player != null:
		_player.set_input_enabled(true)
	_active_npc = null

