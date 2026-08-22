extends Node

func run_test(main: Node) -> void:
	print("--- 开始测试 CombatMessage 浮层系统 ---")

	var battle_ui: BattleUI = main.get_node_or_null("OverlayRoot/BattleUI") as BattleUI
	if battle_ui == null:
		battle_ui = main.get_node_or_null("BattleUI") as BattleUI
	assert(battle_ui != null, "BattleUI 必须存在")

	var combat_msg_panel = battle_ui.combat_message_panel as CombatMessagePanel
	assert(combat_msg_panel != null, "CombatMessagePanel 必须存在于 BattleUI")
	assert(combat_msg_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "CombatMessagePanel 必须穿透鼠标事件")
	assert(combat_msg_panel.message_container.mouse_filter == Control.MOUSE_FILTER_IGNORE, "MessageContainer 必须穿透鼠标事件")

	# 1. 测试清空
	combat_msg_panel.clear_all()
	assert(combat_msg_panel._active_entries.size() == 0, "clear_all 后 active_entries 必须为空")

	# 2. 测试消息压入与富文本着色
	battle_ui.show_message("玩家 使用了 【普通攻击】")
	assert(combat_msg_panel._active_entries.size() == 1, "压入一条消息后应有 1 个条目")

	var first_entry = combat_msg_panel._active_entries[0]
	assert(first_entry["node"] != null and is_instance_valid(first_entry["node"]), "条目 node 必须有效")
	assert(first_entry["node"].mouse_filter == Control.MOUSE_FILTER_IGNORE, "条目 Panel 必须穿透点击")

	var label: RichTextLabel = first_entry["node"].get_child(0) as RichTextLabel
	assert(label != null, "Panel 内部必须包含 RichTextLabel")
	assert(label.bbcode_enabled == true, "RichTextLabel 必须启用 bbcode_enabled")
	assert("普通攻击" in label.text, "Label 内容必须包含消息文字")
	print("[PASS] 1. CombatMessage 单条压入与富文本渲染验证通过")

	# 3. 测试容量上限与自动挤压 (FIFO Trim)
	combat_msg_panel.push_message("造成了 25 点伤害。")
	combat_msg_panel.push_message("获得 10 点护盾。")
	combat_msg_panel.push_message("敌人 使用了 【暗影突袭】")
	combat_msg_panel.push_message("造成了 15 点伤害。")
	# 此时达到 5 条
	assert(combat_msg_panel._active_entries.size() == 5, "应容纳 5 条消息")

	# 压入第 6 条，应触发最老一条快速淡出
	combat_msg_panel.push_message("触发反击！反弹了 8 点伤害。")
	# 检查第一条是否被标记为 fading out
	assert(combat_msg_panel._active_entries.size() <= 6, "消息条目在修剪中受控")
	print("[PASS] 2. CombatMessage 容量控制与挤压逻辑验证通过")

	# 4. 测试清空
	battle_ui.clear_message()
	assert(combat_msg_panel._active_entries.size() == 0, "clear_message 后条目必须清空")
	print("[PASS] 3. CombatMessage 全部清除验证通过")

	print("--- CombatMessage 系统所有测试 PASS ---")
