@tool
extends SceneTree

const EVENT_BUS_SCRIPT = preload("res://scripts/autoload/event_bus.gd")

func _init() -> void:
	print("=== 开始测试通关结算、战报生成与 100% 存档导入复现系统 ===")
	
	# 初始化全局 EventBus 单例（若处于单脚本无头测试环境）
	var event_bus: Node = null
	if root.has_node("EventBus"):
		event_bus = root.get_node("EventBus")
	else:
		event_bus = EVENT_BUS_SCRIPT.new()
		event_bus.name = "EventBus"
		root.add_child(event_bus)
	
	# 1. 实例化主游戏核心节点
	var player_scene := load("res://scenes/actors/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player
	root.add_child(player)
	
	var floor_manager := FloorManager.new()
	floor_manager.name = "FloorManager"
	var world_node := Node2D.new()
	world_node.name = "World"
	root.add_child(world_node)
	root.add_child(floor_manager)
	
	# 设置初始状态
	player.level = 5
	player.experience = 80
	player.stat_points = 3
	player.stats.base_atk = 75.0
	player.stats.base_def = 65.0
	player.stats.base_spd = 55.0
	
	var credit_item := load("res://resources/items/credit.tres") as ItemData
	var red_frag := load("res://resources/items/red_fragment.tres") as ItemData
	player.inventory.add_item(credit_item, 150)
	player.inventory.add_item(red_frag, 3)
	
	var save_manager := SaveManager.new()
	save_manager.name = "SaveManager"
	root.add_child(save_manager)
	save_manager.setup(player, floor_manager, null)
	
	# 2. 检验战报文本生成
	var summary := save_manager.generate_clear_summary_text()
	print("生成的战报摘要预览：\n", summary)
	assert(summary.contains("Lv.5"), "战报应包含等级 Lv.5")
	assert(summary.contains("75"), "战报应包含攻击力 75")
	assert(summary.contains("150 Credits"), "战报应包含 150 Credits")
	print("[PASS] 1. 战报摘要生成校验通过")
	
	# 3. 检验 100% 存档导出与导入复现
	var exported_json := save_manager.export_save_json_string("测试通关存档")
	assert(not exported_json.is_empty(), "导出 JSON 不能为空")
	print("导出的完整存档 JSON 长度: %d 字符" % exported_json.length())
	
	# 故意篡改/重置玩家属性
	player.level = 1
	player.experience = 0
	player.stat_points = 0
	player.stats.base_atk = 10.0
	player.stats.base_def = 10.0
	player.stats.base_spd = 10.0
	player.inventory.clear()
	assert(player.level == 1, "重置后应为 1 级")
	assert(player.credits == 0, "重置后信用点应为 0")
	
	# 执行一键导入复现
	var import_success := save_manager.import_save_from_json_string(exported_json)
	assert(import_success, "从 JSON 字符串导入存档必须成功")
	
	# 断言 100% 还原玩家数据
	assert(player.level == 5, "导入后等级应恢复为 5")
	assert(player.experience == 80, "导入后经验应恢复为 80")
	assert(player.stat_points == 3, "导入后未分配点数应恢复为 3")
	assert(player.stats.base_atk == 75.0, "导入后基础攻击力应恢复为 75")
	assert(player.stats.base_def == 65.0, "导入后基础防御力应恢复为 65")
	assert(player.stats.base_spd == 55.0, "导入后基础速度应恢复为 55")
	assert(player.credits == 150, "导入后信用点应恢复为 150")
	assert(player.inventory.get_quantity(&"red_fragment") == 3, "导入后红色碎片应恢复为 3")
	print("[PASS] 2. 100% 存档导出与复现导入校验通过")
	
	# 4. 检验 DialogueNpc 通关触发信号
	var clear_triggered := false
	var on_clear := func() -> void:
		clear_triggered = true
	event_bus.connect("game_clear_triggered", on_clear)
	
	var npc := DialogueNpc.new()
	npc.triggers_game_clear = true
	var lines: Array[String] = ["终点对话1", "终点对话2"]
	npc.dialogue_lines = lines
	
	var ui_scene := load("res://scenes/ui/npc_interaction_ui.tscn") as PackedScene
	var ui := ui_scene.instantiate() as NpcInteractionUI
	root.add_child(ui)
	
	# 模拟 NPC 对话流
	npc.advance_dialogue(ui, player)
	assert(not clear_triggered, "未结束对话时不应触发通关")
	npc.advance_dialogue(ui, player)
	assert(not clear_triggered, "未结束对话时不应触发通关")
	npc.advance_dialogue(ui, player)
	assert(clear_triggered, "对话结束时必须触发 game_clear_triggered 信号")
	print("[PASS] 3. DialogueNpc 通关触发信号校验通过")
	
	# 5. 检验 GameClearUI 界面
	var clear_ui_scene := load("res://scenes/ui/game_clear_ui.tscn") as PackedScene
	var clear_ui := clear_ui_scene.instantiate() as GameClearUI
	root.add_child(clear_ui)
	
	clear_ui.open(player, save_manager)
	assert(clear_ui.ui_root.visible, "打开通关界面后根控件应可见")
	assert(player.is_movement_locked(), "打开通关界面后玩家移动应被锁定")
	
	clear_ui.close()
	assert(not clear_ui.ui_root.visible, "关闭通关界面后根控件应隐藏")
	assert(not player.is_movement_locked(), "关闭通关界面后玩家移动锁应解除")
	print("[PASS] 4. GameClearUI 界面交互与移动锁控制校验通过")
	
	print("=== 所有通关结算与存档复现测试全部 PASS ===")
	quit(0)
