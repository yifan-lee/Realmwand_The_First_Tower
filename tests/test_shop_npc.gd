extends Node

const ShopNpcClass = preload("res://scripts/npc/shop_npc.gd")

func run_test(main: Node) -> void:
	print("--- 开始测试 ShopNpc 商店与补给兑换系统 ---")

	var player = main.get_node("World/Player") as Player
	var ui = main.get_node("OverlayRoot/NpcInteractionUI") as NpcInteractionUI
	assert(player != null, "Player 必须存在")
	assert(ui != null, "NpcInteractionUI 必须存在")

	# 1. 创建 ShopNpc 实例
	var shop_scene = load("res://scenes/actors/npcs/shop_npc.tscn") as PackedScene
	assert(shop_scene != null, "shop_npc.tscn 必须加载成功")
	var shop_npc = shop_scene.instantiate()
	main.add_child(shop_npc)

	var credit_item = preload("res://resources/items/credit.tres")
	var hp_item = preload("res://resources/items/hp_recovery_lv1.tres")
	var mp_item = preload("res://resources/items/mp_recovery_lv1.tres")

	# 清理背包测试数据
	player.inventory.remove_item(credit_item.id, player.inventory.get_quantity(credit_item.id))
	player.inventory.remove_item(hp_item.id, player.inventory.get_quantity(hp_item.id))
	player.inventory.remove_item(mp_item.id, player.inventory.get_quantity(mp_item.id))

	# 2. 开始交互（0 Credits）
	shop_npc.begin_interaction(ui, player)
	assert(ui.is_open(), "NpcInteractionUI 应该已打开")
	assert(ui.title_label.text == "补给商人", "NPC 标题应为补给商人")
	assert(ui._rows.size() == 3, "选项应该有 3 行（HP药剂、MP药剂、取消）")

	# 验证每行的左右排版
	assert(ui._rows[0].text == "1级生命药剂 [持有数: 0]", "第1行名称应为 1级生命药剂 [持有数: 0]")
	assert(ui._rows[0].trailing_label.text == "25 Credits", "第1行价格应为 25 Credits")
	assert(ui._rows[0].disabled == true, "0 Credits 时第1行应为 disabled")

	assert(ui._rows[1].text == "1级数据恢复 [持有数: 0]", "第2行名称应为 1级数据恢复 [持有数: 0]")
	assert(ui._rows[1].trailing_label.text == "25 Credits", "第2行价格应为 25 Credits")
	assert(ui._rows[1].disabled == true, "0 Credits 时第2行应为 disabled")
	print("[PASS] 1. 初始选项排版与持有数格式验证通过")

	# 3. 0 Credits 尝试购买第 0 项
	shop_npc.handle_dialogue_option(0, ui, player)
	assert(player.inventory.get_quantity(hp_item.id) == 0, "信用点不足不应发放物品")
	assert("不足" in ui.feedback_label.text, "应显示不足提示")
	print("[PASS] 2. 信用点不足拦截验证通过")

	# 4. 给予玩家 50 Credits 并购买 HP 药剂
	player.inventory.add_item(credit_item, 50)
	shop_npc.begin_interaction(ui, player)
	assert(ui._rows[0].disabled == false, "50 Credits 时第1行应为可用")

	shop_npc.handle_dialogue_option(0, ui, player)
	assert(player.inventory.get_quantity(credit_item.id) == 25, "扣除 25 Credits 后应剩余 25")
	assert(player.inventory.get_quantity(hp_item.id) == 1, "应获得 1 个 HP 药剂")
	assert("兑换成功" in ui.feedback_label.text, "应提示兑换成功")
	assert(ui._rows[0].text == "1级生命药剂 [持有数: 1]", "购买后第1行持有数应更新为 1")
	print("[PASS] 3. 购买 HP 药剂与持有数实时更新通过")

	# 5. 再购买 1 瓶 MP 药剂
	shop_npc.handle_dialogue_option(1, ui, player)
	assert(player.inventory.get_quantity(credit_item.id) == 0, "再扣除 25 Credits 后应剩余 0")
	assert(player.inventory.get_quantity(mp_item.id) == 1, "应获得 1 个 MP 药剂")
	assert(ui._rows[1].text == "1级数据恢复 [持有数: 1]", "购买后第2行持有数应更新为 1")
	assert(ui._rows[0].disabled == true, "0 Credits 时选项应重新置灰")
	print("[PASS] 4. 购买 MP 药剂与余额归零自动置灰通过")

	# 6. 自定义商品定价测试（Inspector 调参）
	shop_npc.item_prices = [10, 80]
	player.inventory.add_item(credit_item, 10)
	shop_npc.begin_interaction(ui, player)
	assert(ui._rows[0].trailing_label.text == "10 Credits", "第1行价格应更新为 10 Credits")
	assert(ui._rows[1].trailing_label.text == "80 Credits", "第2行价格应更新为 80 Credits")
	assert(ui._rows[0].disabled == false, "持有 10 Credits 时 10 Credits 商品可用")
	assert(ui._rows[1].disabled == true, "持有 10 Credits 时 80 Credits 商品置灰")
	print("[PASS] 5. Inspector 自定义定价调参验证通过")

	ui.close()
	shop_npc.queue_free()
	print("=== ShopNpc 全部测试 100% 通过！===")
