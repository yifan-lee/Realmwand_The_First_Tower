class_name TutorialManager
extends Node

var completed_tutorials: Array[StringName] = []
var all_tutorials: Array[BaseTutorial] = []
var active_tutorial: BaseTutorial = null

var _player: Player
var _esc_menu: EscMenu
var _tutorial_ui: TutorialUI
var _feature_unlock_state: FeatureUnlockState
var _battle_manager: BattleManager


func setup(
	player: Player,
	esc_menu: EscMenu,
	tutorial_ui: TutorialUI,
	feature_unlock_state: FeatureUnlockState,
	battle_manager: BattleManager
) -> void:
	_player = player
	_esc_menu = esc_menu
	_tutorial_ui = tutorial_ui
	_feature_unlock_state = feature_unlock_state
	_battle_manager = battle_manager

	EventBus.game_event.connect(_on_game_event)
	
	# Temporary mapping of existing signals to EventBus for backwards compatibility
	# In the future, these modules should emit EventBus.game_event directly.
	if _player != null:
		_player.inventory.item_added.connect(func(item, _amount): EventBus.game_event.emit(&"item_added", item))
		_player.equipment.item_equipped.connect(func(_slot, item): EventBus.game_event.emit(&"item_equipped", item))
		_player.skill_learned.connect(func(skill): EventBus.game_event.emit(&"skill_learned", skill))
	
	if _esc_menu != null:
		_esc_menu.opened.connect(func(): EventBus.game_event.emit(&"menu_opened", null))
		_esc_menu.inventory_panel.item_focused.connect(func(item): EventBus.game_event.emit(&"item_focused", item))
		_esc_menu.inventory_panel.item_selected.connect(func(item): EventBus.game_event.emit(&"item_selected", item))
		
	if _battle_manager != null:
		_battle_manager.battle_started.connect(func(enemy): EventBus.game_event.emit(&"battle_started", enemy))
		_battle_manager.player_turn_started.connect(func(): EventBus.game_event.emit(&"player_turn_started", null))
	
	_load_tutorials()


func _load_tutorials() -> void:
	# Note: In a larger game, we could automatically scan the tutorials directory.
	var tut1 = preload("res://scripts/tutorial/tutorials/equipment_tutorial.gd").new()
	var tut2 = preload("res://scripts/tutorial/tutorials/battle_intro_tutorial.gd").new()
	var tut3 = preload("res://scripts/tutorial/tutorials/fp_skill_tutorial.gd").new()
	var tut4 = preload("res://scripts/tutorial/tutorials/mp_skill_tutorial.gd").new()
	var tut5 = preload("res://scripts/tutorial/tutorials/hp_item_tutorial.gd").new()
	var tut6 = preload("res://scripts/tutorial/tutorials/fp_item_tutorial.gd").new()
	var tut7 = preload("res://scripts/tutorial/tutorials/interrupt_tutorial.gd").new()
	var tut8 = preload("res://scripts/tutorial/tutorials/cast_time_tutorial.gd").new()
	all_tutorials.append(tut1)
	all_tutorials.append(tut2)
	all_tutorials.append(tut3)
	all_tutorials.append(tut4)
	all_tutorials.append(tut5)
	all_tutorials.append(tut6)
	all_tutorials.append(tut7)
	all_tutorials.append(tut8)
	
	for tut in all_tutorials:
		tut.setup(self, _tutorial_ui)
		tut.tutorial_completed.connect(_on_tutorial_completed)
		add_child(tut)


func _on_game_event(event_name: StringName, event_data: Variant) -> void:
	if active_tutorial != null:
		active_tutorial.handle_event(event_name, event_data)
		return
		
	for tut in all_tutorials:
		if tut.tutorial_id in completed_tutorials:
			continue
		
		if tut.should_trigger(event_name, event_data):
			active_tutorial = tut
			if _player != null:
				_player.lock_movement(&"tutorial")
			active_tutorial.start()
			break


func _on_tutorial_completed(tutorial_id: StringName) -> void:
	if not tutorial_id in completed_tutorials:
		completed_tutorials.append(tutorial_id)
	active_tutorial = null
	if _player != null:
		_player.unlock_movement(&"tutorial")


func capture_save_data() -> Dictionary:
	return {
		"completed_tutorials": completed_tutorials,
		"feature_unlocks": (
			_feature_unlock_state.capture_save_data()
			if _feature_unlock_state != null
			else []
		),
	}


func restore_save_data(data: Variant) -> void:
	completed_tutorials.clear()
	active_tutorial = null
	
	if data is Dictionary:
		var loaded_tutorials = data.get("completed_tutorials", [])
		for tut_id in loaded_tutorials:
			completed_tutorials.append(StringName(tut_id))
			
		if _feature_unlock_state != null:
			_feature_unlock_state.restore_save_data(
				data.get("feature_unlocks", [])
			)
