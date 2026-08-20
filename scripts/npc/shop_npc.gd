@tool
class_name ShopNpc
extends StaticBody2D

const CREDIT_ITEM: ItemData = preload("res://resources/items/credit.tres")

@export_group("Identity")
@export var npc_name: String = "补给商人"
@export_multiline var greeting_prompt: String = "这里提供各类战备补给，只要支付足够的信用点即可兑换。"

@export_group("Visuals")
@export var texture: Texture2D = preload("res://assets/interactables/npc_universal.png"):
	set(value):
		texture = value
		_update_visuals()
@export var sprite_scale: Vector2 = Vector2(0.125, 0.125):
	set(value):
		sprite_scale = value
		_update_visuals()

@export_group("Shop Inventory & Pricing")
## 可以在 Inspector 中自由添加/修改商品
@export var shop_items: Array[ItemData] = [
	preload("res://resources/items/hp_recovery_lv1.tres"),
	preload("res://resources/items/mp_recovery_lv1.tres")
]
## 对应商品的价格（Credits）
@export var item_prices: Array[int] = [25, 25]


func _ready() -> void:
	_update_visuals()


func _update_visuals() -> void:
	if not is_inside_tree():
		return
	var sprite_node := get_node_or_null("Sprite2D") as Sprite2D
	if sprite_node == null:
		return
	if texture != null:
		sprite_node.texture = texture
	sprite_node.scale = sprite_scale


func interact(player: Player) -> void:
	if Engine.is_editor_hint() or player == null:
		return
	EventBus.npc_interaction_requested.emit(self, player)


func begin_interaction(ui: NpcInteractionUI, player: Player) -> void:
	ui.show_player_stats(player)
	var entries := _get_entries()
	var labels := _build_labels(player)
	var tooltips := _build_tooltips()
	var disabled_flags := _build_disabled_flags(player)
	var trailings := _build_trailing_texts()

	ui.open_choices(npc_name, greeting_prompt, entries, labels, tooltips, disabled_flags, trailings)


func handle_dialogue_option_focused(_index: int, _ui: NpcInteractionUI, _player: Player) -> void:
	pass


func handle_dialogue_option(index: int, ui: NpcInteractionUI, player: Player) -> void:
	if index < 0 or index >= shop_items.size():
		return

	var item := shop_items[index]
	if item == null:
		return

	var price := _get_price_for_index(index)
	var player_credits := player.inventory.get_quantity(&"credit")

	if player_credits < price:
		ui.show_transaction_result(false, "信用点不足，需要 %d Credits（当前持有: %d）。" % [price, player_credits])
		return

	if not player.inventory.remove_item(&"credit", price):
		ui.show_transaction_result(false, "扣除信用点失败，请重试。")
		return

	player.inventory.add_item(item, 1)
	ui.update_choices(_build_labels(player), _build_disabled_flags(player), _build_trailing_texts())
	ui.show_player_stats(player)
	ui.show_entry_detail(item)
	ui.show_transaction_result(true, "兑换成功！获得 1 个【%s】。" % item.display_name)


func _get_entries() -> Array[Resource]:
	var entries: Array[Resource] = []
	for item in shop_items:
		entries.append(item)
	return entries


func _get_price_for_index(index: int) -> int:
	if index >= 0 and index < item_prices.size():
		return item_prices[index]
	return 25


func _build_labels(player: Player = null) -> Array[String]:
	var labels: Array[String] = []
	for item in shop_items:
		if item != null:
			var count: int = player.inventory.get_quantity(item.id) if player != null and player.inventory != null else 0
			labels.append("%s [持有数: %d]" % [item.display_name, count])
		else:
			labels.append("未知商品")
	return labels


func _build_trailing_texts() -> Array[String]:
	var trailings: Array[String] = []
	for i in shop_items.size():
		var price := _get_price_for_index(i)
		trailings.append("%d Credits" % price)
	return trailings


func _build_tooltips() -> Array[String]:
	var tooltips: Array[String] = []
	for item in shop_items:
		if item != null:
			tooltips.append(item.description)
		else:
			tooltips.append("")
	return tooltips


func _build_disabled_flags(player: Player) -> Array[bool]:
	var flags: Array[bool] = []
	var player_credits := player.inventory.get_quantity(&"credit") if player != null else 0
	for i in shop_items.size():
		var price := _get_price_for_index(i)
		flags.append(player_credits < price)
	return flags
