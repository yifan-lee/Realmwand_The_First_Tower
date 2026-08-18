@tool
extends SceneTree

func _init() -> void:
	print("--- 开始测试 Credit 货币系统 ---")
	
	# 1. 检验 credit.tres 资源配置
	var credit_item := load("res://resources/items/credit.tres") as ItemData
	assert(credit_item != null, "credit.tres 应该加载成功")
	assert(credit_item.id == &"credit", "ID 必须为 &\"credit\"")
	assert(credit_item.item_type == ItemData.ItemType.MATERIAL, "类型必须为 MATERIAL (3)")
	assert(credit_item.icon != null, "图标必须存在")
	print("[PASS] 1. credit.tres 资源属性检验通过")
	
	# 2. 检验怪物 CP 与 Credit 奖励映射
	var enemy_atk := ResourceLoader.load("res://resources/actors/enemy_atk_lv1.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyData
	var enemy_def := ResourceLoader.load("res://resources/actors/enemy_def_lv1.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyData
	var boss_atk := ResourceLoader.load("res://resources/actors/boss_atk.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyData
	
	var atk_cr: int = enemy_atk.get_credit_reward()
	var def_cr: int = enemy_def.get_credit_reward()
	var boss_cr: int = boss_atk.get_credit_reward()
	
	print("enemy_atk (50/40/30) 掉落 Credit: %d (预期 12)" % atk_cr)
	print("enemy_def (60/100/40) 掉落 Credit: %d (预期 20)" % def_cr)
	print("boss_atk (120/100/50) 掉落 Credit: %d (预期 27)" % boss_cr)
	
	assert(atk_cr == 12, "1级攻击怪掉落应为 12")
	assert(def_cr == 20, "1级防御怪掉落应为 20")
	assert(boss_cr == 27, "攻击Boss掉落应为 27")
	print("[PASS] 2. 怪物 CP 动态计算掉落检验通过")
	
	# 3. 实例化 Player 与战斗结算测试
	var player_scene := load("res://scenes/actors/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	player.inventory.clear()
	assert(player.credits == 0, "清空后玩家信用点应为 0")
	
	# 监听系统消息广播
	var captured_msg := ""
	var on_msg := func(msg: String) -> void:
		captured_msg = msg
	EventBus.system_message_requested.connect(on_msg)
	
	# 模拟战斗结算
	var battle_manager_scene := load("res://scenes/battle/battle_manager.tscn") as PackedScene
	var battle_manager := battle_manager_scene.instantiate() as BattleManager
	root.add_child(battle_manager)
	
	var enemy_scene := load("res://scenes/actors/enemies/enemy.tscn") as PackedScene
	var enemy_node := enemy_scene.instantiate() as Enemy
	enemy_node.enemy_data = enemy_atk
	root.add_child(enemy_node)
	
	battle_manager.start_battle(enemy_node, player)
	battle_manager._finish_battle(true)
	
	assert(player.credits == 12, "胜利后玩家信用点应为 12，实际为: %d" % player.credits)
	assert(player.inventory.get_quantity(&"credit") == 12, "背包中 credit 数量应为 12")
	assert("战斗胜利！获得了" in captured_msg and "点信用点" in captured_msg, "系统提示应包含信用点，实际提示: " + captured_msg)
	print("战后系统提示: " + captured_msg)
	print("[PASS] 3. 战后结算与双重提示检验通过")
	
	# 4. HUD 追踪测试
	var hud_scene := load("res://scenes/ui/components/tracked_inventory_hud.tscn") as PackedScene
	var hud := hud_scene.instantiate() as TrackedInventoryHUD
	root.add_child(hud)
	hud.bind_inventory(player.inventory)
	
	var credit_row := hud.get_node("Content/ItemRows/Credit") as TrackedItemRow
	assert(credit_row != null, "HUD 必须包含 Credit 追踪行")
	assert(credit_row.visible == true, "持有 12 个信用点时 Credit 行必须可见")
	assert("12" in credit_row.quantity_label.text, "数量标签应包含 12")
	print("[PASS] 4. TrackedInventoryHUD 追踪与展示检验通过")
	
	# 清理节点
	player.queue_free()
	battle_manager.queue_free()
	enemy_node.queue_free()
	hud.queue_free()
	
	print("--- 全部 Credit 测试 100% 通过！---")
	quit(0)
