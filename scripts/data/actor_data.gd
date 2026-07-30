class_name ActorData
extends Resource

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Base Stats")
@export_range(1.0, 999999.0, 1.0) var max_hp: float = 100.0
@export_range(0.0, 999999.0, 1.0) var max_mp: float = 0.0
@export_range(0.0, 999999.0, 1.0) var atk: float = 10.0
@export_range(0.0, 999999.0, 1.0) var def: float = 10.0
@export_range(0.0, 999999.0, 1.0) var spd: float = 10.0

@export_group("Presentation")
@export var portrait: Texture2D