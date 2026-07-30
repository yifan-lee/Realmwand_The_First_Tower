class_name PlayerData
extends ActorData

@export_group("Player Visual")
@export var sprite_frames: SpriteFrames

@export_group("Starting Progression")
@export_range(1, 99, 1) var starting_level: int = 1
@export_range(0, 999999999, 1) var starting_experience: int = 0
@export_range(0, 999999999, 1) var starting_gold: int = 0

@export_group("Starting Content")
@export var starting_items: Array[ItemData] = []
@export var starting_skills: Array[SkillData] = []