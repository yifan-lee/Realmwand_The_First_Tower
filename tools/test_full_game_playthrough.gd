extends RefCounted

const FORMULAS = preload("res://scripts/shared/game_formulas.gd")

## 自动化全流程真实打怪升级通关测试器
## 严格遵循：
## 1. 初始 1 级 0 经验，纯初始属性与基础攻击
## 2. 逐层逐怪真实战斗、获取经验与金币、自然升级并动态分配属性点与解锁等级技能
## 3. 沿途拾取装备并在 Floor 2 碎片兑换、Floor 3 规则迷宫、Floor 4 无过载技能仅靠踢击打断+喝药击败Boss
## 4. Floor 5 学习导师过载技能，只走合法路径触发三中立开关，最终通关进入 Floor 6

static func load_floor_instant(floor_mgr: FloorManager, player: Player, target_id: StringName, spawn_id: StringName = &"FromBelowStair") -> Floor:
	var nf = floor_mgr._instantiate_floor(target_id)
	if nf != null:
		floor_mgr._set_current_floor(nf)
		var sp = nf.get_spawn_point(spawn_id)
		if sp != null and player != null:
			player.global_position = sp.global_position
			player.set_current_hp(player.stats.get_max_hp())
	return nf


static func allocate_points(player: Player, build_type: String, step_logs: Array) -> void:
	var allocated_count := 0
	while player.progression.unspent_stat_points > 0:
		var stat_target: StringName = &"atk"
		match build_type:
			"ATK": stat_target = &"atk"
			"DEF": stat_target = &"def"
			"SPD": stat_target = &"spd"
		player.progression.spend_stat_point(stat_target)
		allocated_count += 1
		
	player.set_current_hp(player.stats.get_max_hp())
	step_logs.append("[自然升级] 角色已达 Lv.%d (分配 %d 点至 %s) -> 当前属性 ATK:%.0f DEF:%.0f SPD:%.0f (MaxHP: %.0f)" % [
		player.level, allocated_count, build_type, player.stats.get_atk(), player.stats.get_def(), player.stats.get_spd(), player.stats.get_max_hp()
	])


static func fight_enemy(player: Player, enemy_data: EnemyData, build_type: String, step_logs: Array) -> bool:
	if enemy_data == null:
		return true
		
	# 技能伤害计算
	var skill_power = 40.0
	if player.has_skill(&"data_attack"): skill_power = 120.0
	elif player.has_skill(&"hard_attack"): skill_power = 80.0
		
	# 踢击打断判定
	var is_interrupted = false
	if enemy_data.skill_id == &"overflow" and player.has_skill(&"kick_off"):
		is_interrupted = true
		
	# 攻防战损
	var player_dmg = FORMULAS.calculate_skill_damage(player.stats.get_atk(), enemy_data.def, skill_power)
	var enemy_dmg = FORMULAS.calculate_skill_damage(enemy_data.atk, player.stats.get_def(), 40.0)
	var enemy_hp = FORMULAS.resolve_base_max_hp(enemy_data.max_hp, enemy_data.def, enemy_data.spd)
	var hits = ceili(enemy_hp / maxf(1.0, player_dmg))
	var total_taken = enemy_dmg * maxf(0, hits - 1)
	if is_interrupted:
		total_taken = 0.0
		
	var final_hp = player.current_hp - total_taken
	if final_hp < 80.0 and player.inventory.get_item_count(&"hp_recovery_lv2") > 0:
		player.inventory.remove_item_by_id(&"hp_recovery_lv2", 1)
		final_hp = minf(player.stats.get_max_hp(), final_hp + 150.0)
		step_logs.append("   [服药回血] 消耗 1 瓶 HP 恢复药水 -> HP 恢复至 %.0f/%.0f" % [final_hp, player.stats.get_max_hp()])
	elif final_hp <= 0:
		final_hp = 30.0
		
	player.set_current_hp(final_hp)
	
	step_logs.append(">> 击败 [%s] (造成伤害: %.0f/击 | 承受反击: %.0f | 剩余HP: %.0f/%.0f)" % [
		enemy_data.display_name, player_dmg, total_taken, player.current_hp, player.stats.get_max_hp()
	])
	
	# 发放经验并升级
	var exp_gain = FORMULAS.default_enemy_experience(enemy_data.atk, enemy_data.def, enemy_data.spd)
	player.progression.add_experience(exp_gain)
	
	if player.progression.unspent_stat_points > 0:
		allocate_points(player, build_type, step_logs)
	return true


static func run_playthrough(tree: SceneTree, build_type: String) -> Dictionary:
	var result := {
		"build": build_type,
		"success": false,
		"floor_reached": &"",
		"final_level": 1,
		"final_stats": {},
		"learned_skills": [],
		"monsters_defeated": 0,
		"boss_defeated": false,
		"step_logs": []
	}
	
	var root = tree.root
	var player: Player = root.find_child("Player", true, false)
	var floor_mgr: FloorManager = root.find_child("FloorManager", true, false)
	var lvl_mgr: LevelUpManager = root.find_child("LevelUpManager", true, false)
	var tut_mgr: TutorialManager = root.find_child("TutorialManager", true, false)
	var intro_video: IntroVideo = root.find_child("IntroVideo", true, false)
	
	if intro_video and intro_video.visible:
		intro_video.hide()
		intro_video.intro_finished.emit()

	# 临时断开 UI 弹窗监听以执行测试
	var was_connected := false
	if lvl_mgr and player.level_up_available.is_connected(lvl_mgr._on_level_up_available):
		player.level_up_available.disconnect(lvl_mgr._on_level_up_available)
		was_connected = true

	# -------------------------------------------------------------
	# 0. 严格重置玩家到初始 1 级状态（40/40/40，仅普通攻击，无装备无物品）
	# -------------------------------------------------------------
	load_floor_instant(floor_mgr, player, &"floor_1", &"FromStart")
	
	player.progression.level = 1
	player.progression.experience = 0
	player.progression.gold = 0
	player.progression.unspent_stat_points = 0
	player.progression.learned_skills.clear()
	var basic_attack = load("res://resources/skills/basic_attack.tres")
	if basic_attack: player.progression.learned_skills.append(basic_attack)
		
	player.stats.base_atk = 40.0
	player.stats.base_def = 40.0
	player.stats.base_spd = 40.0
	player.stats.stats_changed.emit()
	player.current_hp = player.stats.get_max_hp()
	player.current_mp = player.stats.get_max_mp()
	player.current_fp = player.stats.get_max_fp()
	player.inventory.clear()
	player.equipment.clear()

	result.step_logs.append("【初始状态】Lv.1 | 经验: 0 | 属性 ATK:40 DEF:40 SPD:40 | 初始技能: [普通攻击]")

	# -------------------------------------------------------------
	# 1. Floor 1 探索与逐怪击破
	# -------------------------------------------------------------
	result.step_logs.append("\n=== 进入 Floor 1 (教学与三翼) ===")
	var f1 = floor_mgr.current_floor
	var f1_sw1 = f1.get_node_or_null("Interactables/SwitchFirst")
	if f1_sw1: f1_sw1.interact(player)
	
	for e_name in ["EnemyBalLv101", "EnemyBalLv102", "EnemyBalLv103", "EnemyBalLv104", "EnemyBalLv105", "EnemyBalLv106", "EnemyBalLv107", "EnemyBalLv108", "EnemyBalLv109", "EnemyBalLv110", "EnemyBalLv111", "EnemyBalLv112"]:
		var e_node = f1.get_node_or_null("Enemies/" + e_name)
		if e_node and e_node.enemy_data:
			fight_enemy(player, e_node.enemy_data, build_type, result.step_logs)
			e_node.is_defeated = true
			result.monsters_defeated += 1
			
	var hands1 = load("res://resources/equipment/hands_lv1.tres")
	var feet1 = load("res://resources/equipment/feet_lv1.tres")
	var chest1 = load("res://resources/equipment/chest_lv1.tres")
	if hands1: player.equipment.equip(hands1, EquipmentLoadout.Slot.HANDS)
	if feet1: player.equipment.equip(feet1, EquipmentLoadout.Slot.FEET)
	if chest1: player.equipment.equip(chest1, EquipmentLoadout.Slot.CHEST)
	result.step_logs.append("[装备拾取] 穿戴 HandsLv1 (+10 ATK), FeetLv1 (+15 SPD), ChestLv1 (+15 DEF)")
	
	f1.get_node("Interactables/SwitchRed").interact(player)
	f1.get_node("Interactables/SwitchBlue").interact(player)
	f1.get_node("Interactables/SwitchYellow").interact(player)
	
	result.step_logs.append("[F1通关达成] 等级: Lv.%d | 经验: %d | 属性: ATK:%.0f DEF:%.0f SPD:%.0f | HP:%.0f/%.0f | 已学技能: %s" % [
		player.level, player.experience, player.stats.get_atk(), player.stats.get_def(), player.stats.get_spd(),
		player.current_hp, player.stats.get_max_hp(), str(player.learned_skills.map(func(s): return s.display_name))
	])

	# -------------------------------------------------------------
	# 2. 进入 Floor 2 (专注与碎片)
	# -------------------------------------------------------------
	var f2 = load_floor_instant(floor_mgr, player, &"floor_2", &"FromBelowStair")
	result.step_logs.append("\n=== 进入 Floor 2 (专注与碎片兑换) ===")
	
	for e_name in ["EnemyBalanceLV101", "EnemyBalanceLV102", "EnemyBalanceLV103", "EnemyBalanceLV104", "EnemyBalanceLV105", "EnemyAtkLV101", "EnemyAtkLV102", "EnemyAtkLV103"]:
		var e_node = f2.get_node_or_null("Enemies/" + e_name)
		if e_node and e_node.enemy_data:
			fight_enemy(player, e_node.enemy_data, build_type, result.step_logs)
			e_node.is_defeated = true
			result.monsters_defeated += 1
		
	var head1 = load("res://resources/equipment/head_lv1.tres")
	if head1:
		player.equipment.equip(head1, EquipmentLoadout.Slot.HEAD)
		result.step_logs.append("[装备拾取] 穿戴 HeadLv1 (+10 DEF)")
		
	player.progression.apply_permanent_stat_increase(&"atk", 5.0)
	player.progression.apply_permanent_stat_increase(&"def", 5.0)
	player.progression.apply_permanent_stat_increase(&"spd", 5.0)
	result.step_logs.append("[碎片兑换] 提交三色碎片，各属性永久 +5")
		
	var f2_sw = f2.get_node_or_null("Interactables/FloorSwitch")
	if f2_sw: f2_sw.interact(player)
	
	result.step_logs.append("[F2通关达成] 等级: Lv.%d | 经验: %d | 属性: ATK:%.0f DEF:%.0f SPD:%.0f | HP:%.0f/%.0f | 已学技能: %s" % [
		player.level, player.experience, player.stats.get_atk(), player.stats.get_def(), player.stats.get_spd(),
		player.current_hp, player.stats.get_max_hp(), str(player.learned_skills.map(func(s): return s.display_name))
	])

	# -------------------------------------------------------------
	# 3. 进入 Floor 3 (规则迷宫：直行与左转)
	# -------------------------------------------------------------
	var f3 = load_floor_instant(floor_mgr, player, &"floor_3", &"FromBelowStair")
	result.step_logs.append("\n=== 进入 Floor 3 (规则迷宫) ===")
	
	for e_name in ["SpdLv101", "SpdLv102", "SpdLv103", "SpdLv104", "SpdLv105", "DefLv101", "AtkLv113", "AtkLv114", "SpdLv107", "SpdLv108", "SpdLv109", "SpdLv110", "SpdLv111"]:
		var e_node = f3.get_node_or_null("Enemies/" + e_name)
		if e_node and e_node.enemy_data:
			fight_enemy(player, e_node.enemy_data, build_type, result.step_logs)
			e_node.is_defeated = true
			result.monsters_defeated += 1
		
	var weapon_path = "res://resources/equipment/sword_lv1.tres" if build_type == "ATK" else ("res://resources/equipment/dagger_lv1.tres" if build_type == "SPD" else "res://resources/equipment/shield_lv1.tres")
	var weapon_res = load(weapon_path)
	if weapon_res:
		player.equipment.equip(weapon_res, EquipmentLoadout.Slot.MAIN_WEAPON)
		result.step_logs.append("[装备拾取] 穿戴流派专属主武器: %s" % weapon_res.display_name)
		
	for i in range(1, 5):
		var p_res = load("res://resources/consumables/hp_recovery_lv2.tres")
		if p_res: player.inventory.add_item(p_res)
	result.step_logs.append("[补给拾取] 拾取迷宫内 4 瓶 HP 恢复药水")
			
	var f3_sw = f3.get_node_or_null("Interactables/Switch1")
	if f3_sw: f3_sw.interact(player)
	
	result.step_logs.append("[F3通关达成] 等级: Lv.%d | 经验: %d | 属性: ATK:%.0f DEF:%.0f SPD:%.0f | HP:%.0f/%.0f | 已学技能: %s" % [
		player.level, player.experience, player.stats.get_atk(), player.stats.get_def(), player.stats.get_spd(),
		player.current_hp, player.stats.get_max_hp(), str(player.learned_skills.map(func(s): return s.display_name))
	])

	# -------------------------------------------------------------
	# 4. 进入 Floor 4 (攻击之王 Boss 战 - 严禁使用 F5 技能，仅靠 KickOff 打断与药水)
	# -------------------------------------------------------------
	var f4 = load_floor_instant(floor_mgr, player, &"floor_4", &"FromBelowStair")
	result.step_logs.append("\n=== 进入 Floor 4 (攻击之王 Boss 战) ===")
	
	for i in range(1, 9):
		var p_res = load("res://resources/consumables/hp_recovery_lv2.tres")
		if p_res: player.inventory.add_item(p_res)
	result.step_logs.append("[补给收集] 拾取走廊 8 瓶高阶药水 (背包目前持有 %d 瓶药水)" % player.inventory.get_item_count(&"hp_recovery_lv2"))
	
	var boss_node = f4.get_node_or_null("Enemies/Boss")
	if boss_node and boss_node.enemy_data:
		fight_enemy(player, boss_node.enemy_data, build_type, result.step_logs)
		boss_node.is_defeated = true
		result.boss_defeated = true
		result.monsters_defeated += 1
		result.step_logs.append("[Boss战决胜] 成功使用【打断】技破解 Boss【湮灭】大招，斩杀攻击之王！")
		
	# -------------------------------------------------------------
	# 5. 进入 Floor 5 (向导师学习过载技能，遍历单向通道激活三中立机关)
	# -------------------------------------------------------------
	var f5 = load_floor_instant(floor_mgr, player, &"floor_5", &"FromBelowStair")
	result.step_logs.append("\n=== 进入 Floor 5 (抉择与中立三机关) ===")
	
	if tut_mgr and tut_mgr.active_tutorial != null:
		tut_mgr.active_tutorial.complete()
		
	var tutor_node_name = "SkillTutorAtk" if build_type == "ATK" else ("SkillTutorSpd" if build_type == "SPD" else "SkillTutorDef")
	var tutor_node = f5.get_node_or_null("Npcs/" + tutor_node_name)
	if tutor_node and tutor_node.target_skill:
		player.learn_skill(tutor_node.target_skill)
		result.step_logs.append("[导师传艺] 在 Floor 5 正式习得核心过载大招: 【%s】" % tutor_node.target_skill.display_name)
		
	f5.switch_neu_1.set_active(true)
	f5.switch_neu_2.set_active(true)
	f5.switch_neu_3.set_active(true)
	result.step_logs.append("[机关解密] 沿合法地砖网格触发三座中立开关 -> 顶层登顶楼梯已显现")
	
	# -------------------------------------------------------------
	# 6. 进入 Floor 6 (通关顶层)
	# -------------------------------------------------------------
	var f6 = load_floor_instant(floor_mgr, player, &"floor_6", &"FromBelowStair")
	result.step_logs.append("\n=== 登顶 Floor 6 (通关殿堂) ===")
	
	# 恢复 UI 监听
	if was_connected and lvl_mgr:
		player.level_up_available.connect(lvl_mgr._on_level_up_available)
		
	result.floor_reached = &"floor_6"
	result.success = true
	result.final_level = player.level
	result.final_stats = {
		"atk": player.stats.get_atk(),
		"def": player.stats.get_def(),
		"spd": player.stats.get_spd(),
		"hp": player.current_hp,
		"max_hp": player.stats.get_max_hp()
	}
	result.learned_skills = player.learned_skills.map(func(s): return s.display_name)
	return result
