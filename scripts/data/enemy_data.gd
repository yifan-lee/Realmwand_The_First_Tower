class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
@export var max_hp: float = 100.0
@export var cur_hp: float = 100.0
@export var max_mp: float = 100.0
@export var cur_mp: float = 100.0
@export var atk: float = 10.0
@export var def: float = 10.0
@export var spd: float = 10.0
@export var experience_reward: int = 0
@export var gold_reward: int = 0
@export var portrait: Texture2D