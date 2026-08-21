extends Node

func run_test(main: Node) -> void:
	print("--- 开始测试技能学习教程系统与定制提示 ---")
	
	var player = main.get_node_or_null("World/Player") as Player
	var tut_mgr = main.get_node_or_null("TutorialManager") as TutorialManager
	var tut_ui = main.get_node_or_null("OverlayRoot/TutorialUI") as TutorialUI
	var battle_manager = main.get_node_or_null("BattleManager") as BattleManager
	
	assert(player != null, "Player 必须存在")
	assert(tut_mgr != null, "TutorialManager 必须存在")
	assert(tut_ui != null, "TutorialUI 必须存在")
	assert(battle_manager != null, "BattleManager 必须存在")
	
	var basic_atk: SkillData = load("res://resources/skills/basic_attack.tres")
	var ov_atk: SkillData = load("res://resources/skills/overload_atk.tres")
	var kick_off: SkillData = load("res://resources/skills/kick_off.tres")
	var hard_attack: SkillData = load("res://resources/skills/hard_attack.tres")
	
	# 重置教程状态和已学技能
	tut_mgr.completed_tutorials.clear()
	tut_mgr.active_tutorial = null
	tut_ui.hide_prompt()
	player.progression.learned_skills.clear()
	player.progression.equipped_skills = [null, null, null, null, null, null]
	
	# 1. 验证 TutorialUI 节点与 RichTextLabel 支持
	assert(tut_ui.message_label is RichTextLabel, "TutorialUI message_label 必须是 RichTextLabel")
	assert(tut_ui.message_label.bbcode_enabled == true, "message_label 必须启用 bbcode_enabled")
	print("[PASS] 1. TutorialUI RichTextLabel 与 BBCode 配置验证通过")
	
	# 2. 验证学习普通技能（进攻过载）触发通用教程弹窗
	player.learn_skill(ov_atk)
	assert(tut_mgr.active_tutorial != null, "学习新技能应激活教程")
	assert(tut_mgr.active_tutorial is SkillLearnedTutorial, "普通技能应激活 SkillLearnedTutorial")
	assert(tut_ui.tutorial_root.visible == true, "TutorialUI 应该弹窗显示")
	assert("学会技能【进攻过载】，在菜单界面查看。" in tut_ui.message_label.text, "提示文案应为通用格式: " + tut_ui.message_label.text)
	
	# 验证按键独占拦截：非确认键被拦截且不关闭
	var dummy_event = InputEventKey.new()
	dummy_event.keycode = KEY_SPACE
	dummy_event.pressed = true
	tut_ui._input(dummy_event)
	assert(tut_ui.tutorial_root.visible == true, "非 ui_accept 按键不应关闭教程弹窗")
	
	# 模拟确认键关闭
	tut_ui._wait_for_confirmation = false
	tut_ui.confirmed.emit()
	assert(tut_ui.tutorial_root.visible == false, "确认后教程应关闭")
	assert(tut_mgr.completed_tutorials.has(&"skill_learned_Overload ATK"), "已完成列表应记录该技能的教学")
	print("[PASS] 2. 通用技能学习教程弹窗、文案与确认关闭验证通过")
	
	# 3. 验证学习打断技能（kick_off）触发专属富文本教程
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	player.learn_skill(kick_off)
	
	assert(tut_mgr.active_tutorial != null, "学习 kick_off 应激活专属打断教程")
	assert(tut_mgr.active_tutorial.tutorial_id == &"interrupt_tutorial", "激活的教程 ID 应为 interrupt_tutorial")
	assert(tut_ui.tutorial_root.visible == true, "TutorialUI 应该弹窗显示")
	assert("可以打断敌方的吟唱" in tut_ui.message_label.text, "文案必须包含打断说明: " + tut_ui.message_label.text)
	assert("[color=#ff4d4f]" in tut_ui.message_label.text, "文案必须包含红色 BBCode 高亮: " + tut_ui.message_label.text)
	
	# 模拟确认
	tut_ui._wait_for_confirmation = false
	tut_ui.confirmed.emit()
	assert(tut_ui.tutorial_root.visible == false, "确认后打断教程应关闭")
	assert(tut_mgr.completed_tutorials.has(&"interrupt_tutorial"), "已完成列表应记录 interrupt_tutorial")
	print("[PASS] 3. 专属打断技能红色富文本教学弹窗验证通过")
	
	# 4. 验证强力攻击（hard_attack）战斗时 FP 教学流程
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	player.learn_skill(hard_attack)
	# 关闭学习时的通用弹窗
	if tut_ui.tutorial_root.visible:
		tut_ui._wait_for_confirmation = false
		tut_ui.confirmed.emit()
	
	# 模拟进入战斗触发 fp_skill_tutorial
	EventBus.game_event.emit(&"battle_started", null)
	assert(tut_mgr.active_tutorial != null and tut_mgr.active_tutorial.tutorial_id == &"fp_skill_tutorial", "进入战斗应触发 fp_skill_tutorial")
	assert(tut_ui.tutorial_root.visible == true, "FP 教程应弹出提示")
	assert("FP（专注）" in tut_ui.message_label.text, "FP 教程第一步应介绍专注")
	
	# FP 教程 Step 1 确认
	tut_ui._wait_for_confirmation = false
	tut_ui.confirmed.emit()
	assert("【强力攻击】技能伤害很高，但会消耗 FP。" in tut_ui.message_label.text, "FP 教程第二步应介绍强力攻击技能消耗")
	
	# FP 教程 Step 2 确认完成
	tut_ui._wait_for_confirmation = false
	tut_ui.confirmed.emit()
	assert(tut_ui.tutorial_root.visible == false, "FP 教程完成后应关闭")
	assert(tut_mgr.completed_tutorials.has(&"fp_skill_tutorial"), "已完成列表应记录 fp_skill_tutorial")
	print("[PASS] 4. 强力攻击战斗中 FP 教学多步骤指引验证通过")
	
	# 5. 验证已学技能不重复触发学习教程
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	EventBus.game_event.emit(&"skill_learned", ov_atk)
	assert(tut_mgr.active_tutorial == null, "已记录完成的技能教程不应重复触发")
	print("[PASS] 5. 重复触发防护验证通过")
	
	print("\n>>> 技能学习教程系统全部测试顺利通过！ <<<")
