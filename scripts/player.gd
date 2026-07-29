class_name Player
extends CharacterBody2D

signal item_added(item_name: String)
signal rewards_received(
	experience_gained: int,
	gold_gained: int
)
signal leveled_up(new_level: int)
signal attribute_points_changed(remaining_points: int)
signal attributes_changed
signal skill_learned(skill: SkillData)
signal weapon_equipped(
	weapon_name: String,
	total_total_atk: int
)
signal equipment_changed(
	equipment_name: String,
	total_attack: float
)

@onready var interaction_ray: RayCast2D = $InteractionRay

const GRID_SIZE: int = 32
const MOVE_DURATION: float = 0.15
const BATTLE_BALANCE: BattleBalanceConfig = preload(
	"res://resources/battle/battle_balance.tres"
)

var is_moving: bool = false
var inventory: Array[ItemData] = []
var facing_direction: Vector2 = Vector2.DOWN
var experience: int = 0
var gold: int = 0
var level: int = 1
var experience_to_next_level: int = (
	BATTLE_BALANCE.get_experience_requirement(1)
)
var unspent_attribute_points: int = 0
var base_max_hp: float = 200.0
var current_hp: float = 200.0
var base_max_mp: float = 100.0
var current_mp: float = 100.0
var base_atk: float = 20.0
var base_def: float = 20.0
var base_spd: float = 20.0
var equipment_manager := EquipmentManager.new()
var learned_skills: Array[SkillData] = []

var max_hp: float:
	get:
		return (
			base_max_hp
			+ equipment_manager.get_total_bonus(&"max_hp")
		)

var max_mp: float:
	get:
		return (
			base_max_mp
			+ equipment_manager.get_total_bonus(&"max_mp")
		)

var total_atk: float:
	get:
		return (
			base_atk
			+ equipment_manager.get_total_bonus(&"atk")
		)

var total_def: float:
	get:
		return (
			base_def
			+ equipment_manager.get_total_bonus(&"def")
		)

var total_spd: float:
	get:
		return (
			base_spd
			+ equipment_manager.get_total_bonus(&"spd")
		)

@export var skill_catalog: Array[SkillData] = []
@export var debug_config: PlayerDebugConfig
@export var display_name: String = "TooTwo"
@export var portrait: Texture2D


func _ready() -> void:
	_learn_available_skills(false)
	_apply_debug_config()


func _unhandled_input(event: InputEvent) -> void:
	if is_moving:
		return

	if event.is_action_pressed("interact"):
		try_interact()
		return

	var direction := Vector2.ZERO

	if event.is_action_pressed("move_up"):
		direction = Vector2.UP
	elif event.is_action_pressed("move_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed("move_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed("move_right"):
		direction = Vector2.RIGHT

	if direction != Vector2.ZERO:
		facing_direction = direction
		interaction_ray.target_position = facing_direction * GRID_SIZE
		move_one_tile(direction)

func move_one_tile(direction: Vector2) -> void:
	var motion := direction * GRID_SIZE
	if test_move(global_transform, motion):
		return
	is_moving = true

	var target_position := position + motion
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, MOVE_DURATION)

	await tween.finished
	is_moving = false


func wait_for_current_movement() -> void:
	while is_moving:
		await get_tree().process_frame


func add_item(
	new_item: ItemData
) -> void:
	inventory.append(new_item)
	item_added.emit(new_item.display_name)
	print("Added item: ", new_item.display_name)
	print("Inventory size: ", inventory.size())

func equip_item(
	item: EquipmentData,
	target_slot: int = EquipmentManager.INVALID_SLOT
) -> bool:
	if item == null:
		return false

	var inventory_index := inventory.find(item)

	if inventory_index < 0:
		return false

	var displaced_items := (
		equipment_manager.get_displaced_items(
			item,
			target_slot
		)
	)
	inventory.remove_at(inventory_index)

	if not equipment_manager.equip(item, target_slot):
		inventory.insert(inventory_index, item)
		return false

	for displaced_item in displaced_items:
		inventory.append(displaced_item)

	_emit_equipment_change(item)
	return true


func _emit_equipment_change(item: EquipmentData) -> void:
	current_hp = minf(current_hp, max_hp)
	current_mp = minf(current_mp, max_mp)
	equipment_changed.emit(item.display_name, total_atk)

	if item.is_hand_equipment():
		weapon_equipped.emit(
			item.display_name,
			total_atk
		)


func unequip_item(
	slot: EquipmentManager.EquipmentSlot
) -> EquipmentData:
	var item := equipment_manager.unequip(slot)

	if item != null:
		inventory.append(item)
		current_hp = minf(current_hp, max_hp)
		current_mp = minf(current_mp, max_mp)
		equipment_changed.emit(item.display_name, total_atk)

	return item

func try_interact() -> void:
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var target: Object = interaction_ray.get_collider()

	if target.has_method("interact"):
		target.call("interact")

func add_battle_rewards(
	experience_gained: int,
	gold_gained: int
) -> void:
	experience += experience_gained
	gold += gold_gained

	rewards_received.emit(
		experience_gained,
		gold_gained
	)

	print("Experience: ", experience)
	print("Gold: ", gold)
	_check_for_level_up()

func _check_for_level_up() -> void:
	var levels_gained := 0

	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level += 1
		levels_gained += 1

		_apply_attribute_increase(&"max_hp")
		_apply_attribute_increase(&"max_mp")
		_apply_attribute_increase(&"atk")
		_apply_attribute_increase(&"def")
		_apply_attribute_increase(&"spd")
		unspent_attribute_points += (
			BATTLE_BALANCE.free_attribute_points_per_level
		)

		experience_to_next_level = (
			BATTLE_BALANCE.get_experience_requirement(level)
		)
		_learn_available_skills(true)

		print("Level up! Level: ", level)
		print("Max health: ", max_hp)
		print("Attack power: ", total_atk)

	if levels_gained <= 0:
		return

	attributes_changed.emit()
	attribute_points_changed.emit(
		unspent_attribute_points
	)
	leveled_up.emit(level)


func spend_attribute_points(allocation: Dictionary) -> bool:
	var allocated_points := 0
	var valid_attributes: Array[StringName] = [
		&"max_hp",
		&"max_mp",
		&"atk",
		&"def",
		&"spd",
	]

	for key: Variant in allocation:
		if not key is StringName or key not in valid_attributes:
			return false

		var value: Variant = allocation[key]

		if not value is int or int(value) < 0:
			return false

		allocated_points += int(value)

	if allocated_points != unspent_attribute_points:
		return false

	for attribute: StringName in valid_attributes:
		var point_count := int(allocation.get(attribute, 0))

		for point_index: int in range(point_count):
			_apply_attribute_increase(attribute)

	unspent_attribute_points = 0
	attributes_changed.emit()
	attribute_points_changed.emit(
		unspent_attribute_points
	)
	return true


func _apply_attribute_increase(attribute: StringName) -> bool:
	match attribute:
		&"max_hp":
			base_max_hp += BATTLE_BALANCE.hp_per_point
			current_hp += BATTLE_BALANCE.hp_per_point
		&"max_mp":
			base_max_mp += BATTLE_BALANCE.mp_per_point
			current_mp += BATTLE_BALANCE.mp_per_point
		&"atk":
			base_atk += BATTLE_BALANCE.atk_per_point
		&"def":
			base_def += BATTLE_BALANCE.def_per_point
		&"spd":
			base_spd += BATTLE_BALANCE.spd_per_point
		_:
			return false

	return true


func get_combat_power() -> float:
	return BATTLE_BALANCE.calculate_combat_power(
		max_hp,
		max_mp,
		total_atk,
		total_def,
		total_spd
	)


func _learn_available_skills(emit_signal: bool) -> void:
	for skill: SkillData in skill_catalog:
		if (
			skill == null
			or skill.unlock_level > level
			or skill in learned_skills
		):
			continue

		learned_skills.append(skill)

		if emit_signal:
			skill_learned.emit(skill)


func _apply_debug_config() -> void:
	if (
		debug_config == null
		or not debug_config.enabled
		or not OS.is_debug_build()
	):
		return

	global_position = debug_config.world_position
	level = maxi(debug_config.level, 1)
	experience = maxi(debug_config.experience, 0)
	gold = maxi(debug_config.gold, 0)
	unspent_attribute_points = maxi(
		debug_config.unspent_attribute_points,
		0
	)
	experience_to_next_level = (
		BATTLE_BALANCE.get_experience_requirement(level)
	)

	base_max_hp = maxf(debug_config.max_hp, 1.0)
	base_max_mp = maxf(debug_config.max_mp, 0.0)
	base_atk = maxf(debug_config.atk, 0.0)
	base_def = maxf(debug_config.def, 0.0)
	base_spd = maxf(debug_config.spd, 0.0)

	inventory.clear()
	for item: ItemData in debug_config.inventory_items:
		if item != null:
			inventory.append(item)

	equipment_manager = EquipmentManager.new()
	_apply_debug_equipment()

	current_hp = _resolve_debug_resource_value(
		debug_config.current_hp,
		max_hp
	)
	current_mp = _resolve_debug_resource_value(
		debug_config.current_mp,
		max_mp
	)

	learned_skills.clear()
	for skill: SkillData in debug_config.skills:
		if skill != null and skill not in learned_skills:
			learned_skills.append(skill)


func _resolve_debug_resource_value(
	configured_value: float,
	maximum_value: float
) -> float:
	if configured_value < 0.0:
		return maximum_value

	return clampf(
		configured_value,
		0.0,
		maximum_value
	)


func _apply_debug_equipment() -> void:
	_equip_debug_item(
		debug_config.head,
		EquipmentManager.EquipmentSlot.HEAD
	)
	_equip_debug_item(
		debug_config.chest,
		EquipmentManager.EquipmentSlot.CHEST
	)
	_equip_debug_item(
		debug_config.hands,
		EquipmentManager.EquipmentSlot.HANDS
	)
	_equip_debug_item(
		debug_config.legs,
		EquipmentManager.EquipmentSlot.LEGS
	)
	_equip_debug_item(
		debug_config.feet,
		EquipmentManager.EquipmentSlot.FEET
	)
	_equip_debug_item(
		debug_config.left_hand,
		EquipmentManager.EquipmentSlot.LEFT_HAND
	)
	_equip_debug_item(
		debug_config.right_hand,
		EquipmentManager.EquipmentSlot.RIGHT_HAND
	)
	_equip_debug_item(
		debug_config.accessory,
		EquipmentManager.EquipmentSlot.ACCESSORY
	)


func _equip_debug_item(
	item: EquipmentData,
	slot: EquipmentManager.EquipmentSlot
) -> void:
	if item == null:
		return

	if not equipment_manager.equip(item, slot):
		push_warning(
			"Debug equipment %s cannot use slot %s."
			% [
				item.display_name,
				equipment_manager.get_slot_name(slot),
			]
		)


func find_item(item_id: StringName) -> ItemData:
	for item in inventory:
		if item.id == item_id:
			return item

	return null

func has_item(item_id: StringName) -> bool:
	return find_item(item_id) != null

func consume_item(item_id: StringName) -> ItemData:
	for item_index in range(inventory.size()):
		var item := inventory[item_index]
		if item.id == item_id:
			inventory.remove_at(item_index)
			print("Consumed: ", item.display_name)
			print("Inventory size: ", inventory.size())
			return item
	return null

func take_damage(damage: int) -> void:
	current_hp = max(
		current_hp - damage,
		0
	)


func heal(amount: int) -> void:
	current_hp = min(
		current_hp + amount,
		max_hp
	)


func restore_mp(amount: int) -> void:
	current_mp = min(
		current_mp + amount,
		max_mp
	)


func restore_full_health() -> void:
	current_hp = max_hp
