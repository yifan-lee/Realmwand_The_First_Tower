extends Node

signal game_event(event_name: StringName, event_data: Variant)

signal floor_change_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
)

signal floor_changed(floor: Node)

signal battle_requested(
	enemy: Enemy,
	player: Player
)

signal npc_interaction_requested(
	npc: Node,
	player: Player
)
