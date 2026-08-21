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
	
		
	# Pause the battle ATB timer
	if _manager._battle_manager != null:
		_manager._battle_manager.pause_battle()
	
	_ui.show_prompt("遭遇敌人！战斗即将开始。\n\n[color=#8EA3AA]按确认键继续[/color]", true)
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
			_ui.show_prompt_at("这是你的 HP（生命），归零则战斗失败。\n\n[color=#8EA3AA]按确认键继续[/color]", target, true)
			
		Step.HP:
			current_step = Step.ATK
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"atk")
			var target: Control = null
			if battle_ui != null and battle_ui.player_stats != null:
				target = battle_ui.player_stats.atk_group
			_ui.show_prompt_at("ATK（攻击）决定了你的基础物理伤害。\n\n[color=#8EA3AA]按确认键继续[/color]", target, true)

		Step.ATK:
			current_step = Step.DEF
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"def")
			var target: Control = null
			if battle_ui != null and battle_ui.player_stats != null:
				target = battle_ui.player_stats.def_group
			_ui.show_prompt_at("DEF（防御）决定了你受到的物理伤害减免。\n伤害计算公式大约是 atk * 技能威力 / def\n\n[color=#8EA3AA]按确认键继续[/color]", target, true)

		Step.DEF:
			current_step = Step.ATB
			if _manager._feature_unlock_state != null:
				_manager._feature_unlock_state.unlock(&"spd")
			var target: Control = null
			if battle_ui != null and battle_ui.shared_atb_track != null:
				target = battle_ui.shared_atb_track
			_ui.show_prompt_at("SPD（速度）决定 ATB 读条速度。\n当标记到达右侧即可行动！\n每次行动需要花费的时间大约是 200 / spd\n\n[color=#8EA3AA]按确认键继续[/color]", target, true)

		Step.ATB:
			current_step = Step.FINISH
			if _ui.confirmed.is_connected(_on_ui_confirmed):
				_ui.confirmed.disconnect(_on_ui_confirmed)
				
			_ui.hide_prompt()
			
			
			# Resume battle
			if _manager._battle_manager != null:
				_manager._battle_manager.resume_battle()
			
			complete()
