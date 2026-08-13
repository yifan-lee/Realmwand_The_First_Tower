extends Node

signal game_event(event_name: StringName, event_data: Variant)
signal system_message_requested(message: String)

signal floor_change_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
)

signal floor_changed(floor: Node)

signal screen_fade_out_started
signal screen_fade_out_finished
signal screen_fade_in_with_info_started(floor_name: String, floor_desc: String)
signal screen_fade_in_finished

signal battle_requested(
	enemy: Enemy,
	player: Player
)

signal npc_interaction_requested(
	npc: Node,
	player: Player
)
