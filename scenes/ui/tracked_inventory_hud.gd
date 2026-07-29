class_name TrackedInventoryHud
extends PanelContainer

const ITEM_ROW_SCENE: PackedScene = preload(
	"res://scenes/ui/tracked_item_count_row.tscn"
)

@onready var item_list: VBoxContainer = (
	$MarginContainer/Content/ItemList
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)


func set_inventory(inventory: Array[ItemData]) -> void:
	for child: Node in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()

	var tracked_items: Array[ItemData] = []
	var tracked_counts: Array[int] = []

	for item: ItemData in inventory:
		if item == null or not item.show_count_in_hud:
			continue

		var tracked_index := _find_tracked_item(
			tracked_items,
			item.id
		)

		if tracked_index < 0:
			tracked_items.append(item)
			tracked_counts.append(1)
		else:
			tracked_counts[tracked_index] += 1

	for item_index: int in range(tracked_items.size()):
		var row := (
			ITEM_ROW_SCENE.instantiate()
			as TrackedItemCountRow
		)
		item_list.add_child(row)
		row.setup(
			tracked_items[item_index],
			tracked_counts[item_index]
		)

	empty_label.visible = tracked_items.is_empty()


func _find_tracked_item(
	tracked_items: Array[ItemData],
	item_id: StringName
) -> int:
	for item_index: int in range(tracked_items.size()):
		if tracked_items[item_index].id == item_id:
			return item_index

	return -1
