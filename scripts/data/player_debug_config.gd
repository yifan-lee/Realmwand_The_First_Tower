class_name PlayerDebugConfig
extends Resource

@export_group("Debug Mode")
@export var enabled: bool = false
@export var world_position: Vector2 = Vector2.ZERO

@export_group("Progression")
@export_range(1, 99, 1) var level: int = 1
@export var experience: int = 0
@export var gold: int = 0
@export var unspent_attribute_points: int = 0

@export_group("Base Attributes")
@export var max_hp: float = 200.0
@export var max_mp: float = 100.0
@export var atk: float = 20.0
@export var def: float = 20.0
@export var spd: float = 20.0
@export var current_hp: float = -1.0
@export var current_mp: float = -1.0

@export_group("Equipment")
@export var head: EquipmentData
@export var chest: EquipmentData
@export var hands: EquipmentData
@export var legs: EquipmentData
@export var feet: EquipmentData
@export var left_hand: EquipmentData
@export var right_hand: EquipmentData
@export var accessory: EquipmentData

@export_group("Inventory")
@export var inventory_items: Array[ItemData] = []

@export_group("Skills")
@export var skills: Array[SkillData] = []
