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
	
	# 6. 验证首次获得装备：非阻塞分步引导（wait_for_confirmation == false）
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	var test_equip: EquipmentData = EquipmentData.new()
	test_equip.id = &"test_sword"
	test_equip.display_name = "测试铁剑"
	test_equip.item_type = ItemData.ItemType.EQUIPMENT
	test_equip.slot_type = EquipmentData.EquipmentSlotType.WEAPON
	
	EventBus.game_event.emit(&"item_added", test_equip)
	assert(tut_mgr.active_tutorial != null and tut_mgr.active_tutorial.tutorial_id == &"equipment_tutorial", "首次获得装备应触发 equipment_tutorial")
	assert(tut_ui.tutorial_root.visible == true, "应弹出装备提示")
	assert(tut_ui._wait_for_confirmation == false, "装备指引第一步必须非阻塞（wait_for_confirmation == false）")
	assert("按 ESC 键打开菜单" in tut_ui.message_label.text, "步骤1文案验证: " + tut_ui.message_label.text)
	
	# 步骤 2: 打开菜单
	EventBus.game_event.emit(&"menu_opened", null)
	assert(tut_ui._wait_for_confirmation == false, "装备指引第二步必须非阻塞")
	assert("移动焦点到新获得的装备上" in tut_ui.message_label.text, "步骤2文案验证: " + tut_ui.message_label.text)
	
	# 步骤 3: 焦点移至装备
	EventBus.game_event.emit(&"item_focused", test_equip)
	assert(tut_ui._wait_for_confirmation == false, "装备指引第三步必须非阻塞")
	assert("按下确认键即可穿戴该装备" in tut_ui.message_label.text, "步骤3文案验证: " + tut_ui.message_label.text)
	
	# 步骤 4: 穿戴装备完成
	EventBus.game_event.emit(&"item_equipped", test_equip)
	assert(tut_ui.tutorial_root.visible == false, "穿戴完成后教程应关闭")
	assert(tut_mgr.completed_tutorials.has(&"equipment_tutorial"), "已完成列表应记录 equipment_tutorial")
	print("[PASS] 6. 首次获得装备全流程非阻塞分步引导验证通过")
	
	# 7. 验证后续获得装备：模态通知弹窗（wait_for_confirmation == true）
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	var test_armor: EquipmentData = EquipmentData.new()
	test_armor.id = &"test_shield"
	test_armor.display_name = "合金重盾"
	test_armor.item_type = ItemData.ItemType.EQUIPMENT
	test_armor.slot_type = EquipmentData.EquipmentSlotType.CHEST
	
	EventBus.game_event.emit(&"item_added", test_armor)
	assert(tut_mgr.active_tutorial != null and tut_mgr.active_tutorial.tutorial_id == &"equipment_acquired_tutorial", "后续获得装备应触发 equipment_acquired_tutorial")
	assert(tut_ui.tutorial_root.visible == true, "应弹出装备获得通知")
	assert(tut_ui._wait_for_confirmation == true, "后续装备获得通知必须为模态确认（wait_for_confirmation == true）")
	assert("获得新装备【合金重盾】！可在 ESC 菜单中查看并穿戴。" in tut_ui.message_label.text, "通知文案验证: " + tut_ui.message_label.text)
	
	# 按确认键关闭通知
	tut_ui._wait_for_confirmation = false
	tut_ui.confirmed.emit()
	assert(tut_ui.tutorial_root.visible == false, "确认后通知弹窗应立即关闭")
	print("[PASS] 7. 后续获得装备简洁模态通知弹窗验证通过")
	
	# 8. 验证首次获得 HP 药水：非阻塞背包使用分步引导
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	var hp_potion: ItemData = ItemData.new()
	hp_potion.id = &"hp_recovery_lv1"
	hp_potion.display_name = "HP恢复药水"
	hp_potion.item_type = ItemData.ItemType.CONSUMABLE
	
	EventBus.game_event.emit(&"item_added", hp_potion)
	assert(tut_mgr.active_tutorial != null and tut_mgr.active_tutorial.tutorial_id == &"hp_item_tutorial", "首次获得HP药水应触发 hp_item_tutorial")
	assert(tut_ui._wait_for_confirmation == false, "HP药水第一步必须非阻塞")
	assert("按 ESC 键打开背包" in tut_ui.message_label.text, "HP药水步骤1文案: " + tut_ui.message_label.text)
	
	EventBus.game_event.emit(&"menu_opened", null)
	assert(tut_ui._wait_for_confirmation == false, "HP药水第二步必须非阻塞")
	assert("将焦点移动到药水上" in tut_ui.message_label.text, "HP药水步骤2文案: " + tut_ui.message_label.text)
	
	EventBus.game_event.emit(&"item_focused", hp_potion)
	assert(tut_ui._wait_for_confirmation == false, "HP药水第三步必须非阻塞")
	assert("在背包中使用该药水恢复生命" in tut_ui.message_label.text, "HP药水步骤3文案: " + tut_ui.message_label.text)
	
	EventBus.game_event.emit(&"item_selected", hp_potion)
	assert(tut_ui.tutorial_root.visible == false, "使用后教程应关闭")
	assert(tut_mgr.completed_tutorials.has(&"hp_item_tutorial"), "已完成列表应记录 hp_item_tutorial")
	print("[PASS] 8. 首次获得 HP 药水背包使用分步引导验证通过")
	
	# 9. 验证首次获得 FP 药水：非阻塞打开背包 + 模态自由动作说明
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	var fp_potion: ItemData = ItemData.new()
	fp_potion.id = &"fp_recovery_lv1"
	fp_potion.display_name = "FP恢复药水"
	fp_potion.item_type = ItemData.ItemType.CONSUMABLE
	
	EventBus.game_event.emit(&"item_added", fp_potion)
	assert(tut_mgr.active_tutorial != null and tut_mgr.active_tutorial.tutorial_id == &"fp_item_tutorial", "首次获得FP药水应触发 fp_item_tutorial")
	assert(tut_ui._wait_for_confirmation == false, "FP药水第一步必须非阻塞")
	
	EventBus.game_event.emit(&"menu_opened", null)
	assert(tut_ui._wait_for_confirmation == true, "FP药水第二步自由动作说明必须为模态确认")
	assert("Free Action" in tut_ui.message_label.text, "FP药水步骤2文案: " + tut_ui.message_label.text)
	
	tut_ui._wait_for_confirmation = false
	tut_ui.confirmed.emit()
	assert(tut_ui.tutorial_root.visible == false, "确认后FP药水教程应关闭")
	assert(tut_mgr.completed_tutorials.has(&"fp_item_tutorial"), "已完成列表应记录 fp_item_tutorial")
	print("[PASS] 9. 首次获得 FP 药水自由动作说明教学验证通过")
	
	# 10. 验证后续再次获得 HP/FP 药水：不再触发任何教程
	tut_ui.hide_prompt()
	tut_mgr.active_tutorial = null
	EventBus.game_event.emit(&"item_added", hp_potion)
	assert(tut_mgr.active_tutorial == null, "后续获得HP药水不应触发任何教程")
	EventBus.game_event.emit(&"item_added", fp_potion)
	assert(tut_mgr.active_tutorial == null, "后续获得FP药水不应触发任何教程")
	print("[PASS] 10. 物品后续获取零打扰验证通过")
	
	print("\n>>> 技能/装备/物品教程系统全部测试顺利通过！ <<<")
