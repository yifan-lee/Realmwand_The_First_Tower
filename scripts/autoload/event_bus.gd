extends Node

signal floor_change_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
)

signal battle_requested(
	enemy: Enemy,
	player: Player
)

signal npc_interaction_requested(
	npc: Node,
	player: Player
)
