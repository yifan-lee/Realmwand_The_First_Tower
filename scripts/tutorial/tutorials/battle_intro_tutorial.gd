extends BaseTutorial

enum Step {
	INIT,
	INTRO,
	HP,
	ATK,
	DEF,
	ATB,
	FINISH
}

var current_step: Step = Step.INIT


func _init() -> void:
	tutorial_id = &"battle_intro_tutorial"


func should_trigger(event_name: StringName, _event_data: Variant) -> bool:
	# Trigger on the first time battle_started is fired
	if event_name == &"battle_started":
		return true
	return false


func start() -> void:
	current_step = Step.INTRO
	
	if _manager._player != null:
		
	# Pause the battle ATB timer
	if _manager._battle_manager != null:
		_manager._battle_manager.pause_battle()
	
	_ui.show_prompt("遭遇敌人！战斗即将开始。", true)
	if not _ui.confirmed.is_connected(_on_ui_confirmed):
		_ui.confirmed.connect(_on_ui_confirmed)


func handle_event(_event_name: StringName, _event_data: Variant) -> void:
	pass


func _on_ui_confirmed() -> void:
	var battle_ui: BattleUI = null
	if _manager._battle_manager != null:
		battle_ui = _manager._battle_manager._battle_ui

	match current_step:
		Step.INTRO:
			current_step = Step.HP
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"hp")
			var target: Control = null
			if battle_ui != null and battle_ui.player_stats != null:
				target = battle_ui.player_stats.hp_row
			_ui.show_prompt_at("这是你的 HP (生命值)，归零则战斗失败。", target, true)
			
		Step.HP:
			current_step = Step.ATK
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"atk")
			var target: Control = null
			if battle_ui != null and battle_ui.player_stats != null:
				target = battle_ui.player_stats.atk_group
			_ui.show_prompt_at("ATK 决定了你的基础物理伤害。", target, true)

		Step.ATK:
			current_step = Step.DEF
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"def")
			var target: Control = null
			if battle_ui != null and battle_ui.player_stats != null:
				target = battle_ui.player_stats.def_group
			_ui.show_prompt_at("DEF 决定了你受到的物理伤害减免。", target, true)

		Step.DEF:
			current_step = Step.ATB
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"spd")
			var target: Control = null
			if battle_ui != null and battle_ui.shared_atb_track != null:
				target = battle_ui.shared_atb_track
			_ui.show_prompt_at("SPD 决定 ATB 读条速度。当标记到达右侧，即可行动！", target, true)

		Step.ATB:
			current_step = Step.FINISH
			if _ui.confirmed.is_connected(_on_ui_confirmed):
				_ui.confirmed.disconnect(_on_ui_confirmed)
				
			_ui.hide_prompt()
			
			if _manager._player != null:
			
			# Resume battle
			if _manager._battle_manager != null:
				_manager._battle_manager.resume_battle()
			
			complete()
