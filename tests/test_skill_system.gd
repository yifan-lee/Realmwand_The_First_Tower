extends Node

func run_test(main: Node) -> void:
	print("--- 开始测试 6 槽位技能系统与 ESC 双面板管理 ---")
	
	var player = main.get_node_or_null("World/Player") as Player
	var esc_menu = main.get_node_or_null("OverlayRoot/EscMenu") as EscMenu
	var battle_ui = main.get_node_or_null("OverlayRoot/BattleUI") as BattleUI
	var battle_manager = main.get_node_or_null("BattleManager") as BattleManager
	
	assert(player != null, "Player 必须存在")
	assert(esc_menu != null, "EscMenu 必须存在")
	assert(battle_ui != null, "BattleUI 必须存在")
	assert(battle_manager != null, "BattleManager 必须存在")
	
	var basic_atk: SkillData = load("res://resources/skills/basic_attack.tres")
	var heavy_strike: SkillData = load("res://resources/skills/heavy_strike.tres")
	var ov_atk: SkillData = load("res://resources/skills/overload_atk.tres")
	var ov_def: SkillData = load("res://resources/skills/overload_def.tres")
	var ov_spd: SkillData = load("res://resources/skills/overload_spd.tres")
	
	# 1. 验证数据互斥组
	assert(ov_atk.exclusive_group == &"overload", "进攻过载互斥组应为 overload")
	assert(ov_def.exclusive_group == &"overload", "过载防御互斥组应为 overload")
	assert(ov_spd.exclusive_group == &"overload", "过载极速互斥组应为 overload")
	print("[PASS] 1. SkillData exclusive_group 数据驱动配置验证通过")
	
	# 2. 验证 Player 6 槽位逻辑与学习自动装备
	player.progression.learned_skills.clear()
	player.progression.equipped_skills = [null, null, null, null, null, null]
	player.learn_skill(basic_atk)
	assert(player.equipped_skills[0] == basic_atk, "新学普通攻击应自动装入槽位 1")
	assert(player.is_skill_equipped(basic_atk.id) == true, "普通攻击应为已装备")
	
	player.learn_skill(ov_atk)
	assert(player.equipped_skills[1] == ov_atk, "新学进攻过载应自动装入槽位 2")
	
	# 3. 验证互斥过载技能携带拦截
	var conflict_check = player.can_equip_skill(ov_def, 2)
	assert(conflict_check.get("allowed") == false, "已有进攻过载时，装入槽位 3 应被拦截")
	assert("冲突" in conflict_check.get("reason", ""), "原因应提示互斥冲突")
	print("[PASS] 2. 互斥过载技能拦截与冲突提示验证通过: " + conflict_check.reason)
	
	# 4. 验证直接替换原互斥槽位允许
	var replace_check = player.can_equip_skill(ov_def, 1)
	assert(replace_check.get("allowed") == true, "直接替换槽位 2 的过载技能应被允许")
	player.equip_skill(ov_def, 1)
	assert(player.equipped_skills[1] == ov_def, "槽位 2 现应为过载防御")
	print("[PASS] 3. 直接替换同组过载技能通过")
	
	# 5. 验证重复技能换位/移动
	player.learn_skill(heavy_strike) # 自动进入 slot 2
	assert(player.equipped_skills[2] == heavy_strike, "重击应自动装入槽位 3")
	player.equip_skill(heavy_strike, 5) # 将重击移至 slot 5
	assert(player.equipped_skills[5] == heavy_strike, "重击应移动至槽位 6")
	assert(player.equipped_skills[2] == null, "原槽位 3 应变为空槽")
	print("[PASS] 4. 重复技能自动移动/换位验证通过")
	
	# 6. 验证卸下技能
	player.unequip_skill(5)
	assert(player.equipped_skills[5] == null, "槽位 6 卸下后应为空")
	assert(player.is_skill_equipped(heavy_strike.id) == false, "重击应显示为未装备")
	print("[PASS] 5. 卸下技能验证通过")
	
	# 7. 验证 ESC 菜单双面板与技能界面交互
	esc_menu.bind_player(player)
	esc_menu.open()
	esc_menu._show_main_page(EscMenu.MainPage.SKILLS, true)
	assert(esc_menu.skill_page.visible == true, "技能页面应可见")
	assert(esc_menu.all_skill_panel.visible == true, "左侧全部技能面板应可见")
	assert(esc_menu.equipped_skill_panel.visible == true, "右侧携带技能面板应可见")
	
	# 模拟在全部面板选中 heavy_strike 并装入槽位 0
	esc_menu._on_all_skill_selected(heavy_strike)
	assert(esc_menu._pending_assign_skill == heavy_strike, "选定技能应暂存")
	esc_menu._on_equipped_slot_selected(0, player.equipped_skills[0])
	assert(player.equipped_skills[0] == heavy_strike, "槽位 1 现应为重击")
	assert(esc_menu._pending_assign_skill == null, "分配后暂存应清空")
	esc_menu.close()
	print("[PASS] 6. ESC 双面板技能装配与交互流程验证通过")
	
	# 8. 验证战斗中技能来源与无可用技能自动跳过
	player.progression.equipped_skills = [basic_atk, null, null, null, null, null]
	var active_skills = player.get_skills()
	assert(active_skills.size() == 1 and active_skills[0] == basic_atk, "get_skills() 仅返回已装备的有效技能")
	
	battle_manager._player = player
	assert(battle_manager._has_usable_player_skills() == true, "普通攻击就绪时应判定为有可用技能")
	
	# 冷却普通攻击
	battle_manager._cooldowns[basic_atk.id] = 2
	assert(battle_manager._has_usable_player_skills() == false, "技能全在 CD 时应判定为无可用技能")
	
	battle_manager._player_atb = 100.0
	battle_manager._auto_skip_player_turn()
	assert(battle_manager._player_atb == 0.0, "自动跳过后 ATB 应重置为 0")
	assert(battle_manager._cooldowns[basic_atk.id] == 1, "自动跳过后冷却应正常倒计时 1 回合")
	print("[PASS] 7. 战斗系统技能读取与无可用技能自动跳过回合验证通过")
	
	# 9. 验证存档持久化
	var save_dict = player.capture_save_data()
	assert(save_dict.has("equipped_skills"), "存档数据必须包含 equipped_skills")
	assert(save_dict["equipped_skills"].size() == 6, "equipped_skills 应包含 6 个槽位记录")
	print("[PASS] 8. 存档持久化字段验证通过")
	
	print("\n>>> 6 槽位技能系统与 ESC 双面板全部测试顺利通过！ <<<")
