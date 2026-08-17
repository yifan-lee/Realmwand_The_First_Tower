class_name BattleActionPreview
extends RefCounted

class ActorDelta extends RefCounted:
	var hp_delta: float = 0.0
	var shield_delta: float = 0.0
	var mp_delta: float = 0.0
	var fp_delta: float = 0.0
	
	var atk_delta: float = 0.0
	var def_delta: float = 0.0
	var spd_delta: float = 0.0
	
	var atb_delta: float = 0.0
	var is_interrupted: bool = false
	var is_free_action: bool = false


var actor_deltas: Dictionary = {} # Key: Object (Actor), Value: ActorDelta
var extra_messages: Array[String] = []


func get_or_create_delta(actor: Object) -> ActorDelta:
	if not actor_deltas.has(actor):
		actor_deltas[actor] = ActorDelta.new()
	return actor_deltas[actor]

func add_message(msg: String) -> void:
	if not msg.is_empty():
		extra_messages.append(msg)
