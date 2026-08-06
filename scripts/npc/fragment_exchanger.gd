@tool
class_name FragmentExchanger
extends StaticBody2D

const RED_FRAGMENT: ItemData = preload("res://resources/items/fragment_red_lv1.tres")
const YELLOW_FRAGMENT: ItemData = preload("res://resources/items/fragment_yellow_lv1.tres")
const BLUE_FRAGMENT: ItemData = preload("res://resources/items/fragment_blue_lv1.tres")
const NPC_NAME := "碎片共鸣者"
const PROMPT := "将碎片交给我，它们会化作你自身的力量。"
const STAT_IDS: Array[StringName] = [&"atk", &"def", &"spd"]
const STAT_NAMES: Array[String] = ["攻击力", "防御力", "速度"]
const STAT_AMOUNT := 1.0
const COST_AMOUNT := 1


func interact(player: Player) -> void:
	if Engine.is_editor_hint() or player == null:
		return
	EventBus.npc_interaction_requested.emit(self, player)


func begin_interaction(ui: NpcInteractionUI, player: Player) -> void:
	ui.open_choices(NPC_NAME, PROMPT, _get_fragments(), _build_labels(player), _build_tooltips())
	ui.show_player_stat_preview(player, STAT_IDS[0], STAT_AMOUNT)


func handle_dialogue_option(index: int, ui: NpcInteractionUI, player: Player) -> void:
	var fragments := _get_fragments()
	if index < 0 or index >= fragments.size():
		return
	var fragment: ItemData = fragments[index]
	if not player.inventory.has_item(fragment.id, COST_AMOUNT):
		ui.show_transaction_result(false, "%s不足，需要 %d 个。" % [fragment.display_name, COST_AMOUNT])
		return
	if not player.inventory.remove_item(fragment.id, COST_AMOUNT):
		ui.show_transaction_result(false, "交换失败，请重试。")
		return
	player.apply_permanent_stat_increase(STAT_IDS[index], STAT_AMOUNT)
	ui.update_choices(_build_labels(player))
	ui.show_player_stat_preview(player, STAT_IDS[index], STAT_AMOUNT)
	ui.show_transaction_result(true, "交换完成：%s +%d" % [STAT_NAMES[index], int(STAT_AMOUNT)])


func handle_dialogue_option_focused(index: int, ui: NpcInteractionUI, player: Player) -> void:
	if index >= 0 and index < STAT_IDS.size():
		ui.show_player_stat_preview(player, STAT_IDS[index], STAT_AMOUNT)


func _get_fragments() -> Array[Resource]:
	return [RED_FRAGMENT, YELLOW_FRAGMENT, BLUE_FRAGMENT]


func _build_labels(player: Player) -> Array[String]:
	var labels: Array[String] = []
	var fragments := _get_fragments()
	for index: int in fragments.size():
		var fragment := fragments[index] as ItemData
		labels.append("%s：%s +%d    [%s %d/%d]" % [
			fragment.display_name,
			STAT_NAMES[index],
			int(STAT_AMOUNT),
			fragment.display_name,
			player.inventory.get_quantity(fragment.id),
			COST_AMOUNT,
		])
	return labels


func _build_tooltips() -> Array[String]:
	return [
		"消耗红色碎片，永久提高攻击力。",
		"消耗黄色碎片，永久提高防御力。",
		"消耗蓝色碎片，永久提高速度。",
	]
