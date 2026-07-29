extends SceneTree

## Run with:
## Godot --headless --path . --script res://tools/battle_cost_estimator.gd
##
## Edit only this configuration block when comparing combatants.
const BATTLES_TO_SIMULATE: int = 100
const MAX_ACTIONS_PER_BATTLE: int = 10_000

const PLAYER_STATS := {
	"max_hp": 200.0,
	"max_mp": 100.0,
	"atk": 20.0,
	"def": 20.0,
	"spd": 20.0,
}

const ENEMY_STATS := {
	"name": "Slime",
	"max_hp": 40.0,
	"atk": 10.0,
	"def": 10.0,
	"spd": 10.0,
}

## The first usable skill in this array is selected each turn.
## Put high-priority skills first and keep a zero-cost basic attack last.
const PLAYER_SKILLS := [
	{
		"id": &"power_strike",
		"name": "Power Strike",
		"power": 40.0,
		"mp_cost": 10.0,
		"cooldown_seconds": 3.0,
	},
	{
		"id": &"basic_attack",
		"name": "Basic Attack",
		"power": 20.0,
		"mp_cost": 0.0,
		"cooldown_seconds": 0.0,
	},
]

const BATTLE_BALANCE: BattleBalanceConfig = preload(
	"res://resources/battle/battle_balance.tres"
)


func _initialize() -> void:
	var validation_error := _validate_configuration()

	if not validation_error.is_empty():
		push_error(validation_error)
		quit(1)
		return

	var summary := _simulate_many_battles()
	_print_summary(summary)
	quit()


func _simulate_many_battles() -> Dictionary:
	var victories: int = 0
	var defeats: int = 0
	var deadlocks: int = 0
	var total_hp_lost: float = 0.0
	var total_mp_spent: float = 0.0
	var total_duration: float = 0.0
	var total_player_actions: int = 0
	var total_enemy_actions: int = 0
	var total_skill_uses: Dictionary = {}
	var deadlock_reason: String = ""

	for _battle_index: int in range(BATTLES_TO_SIMULATE):
		var result := _simulate_battle()
		var status := result["status"] as String

		match status:
			"victory":
				victories += 1
				total_hp_lost += (
					float(PLAYER_STATS["max_hp"])
					- float(result["player_hp"])
				)
				total_mp_spent += (
					float(PLAYER_STATS["max_mp"])
					- float(result["player_mp"])
				)
				total_duration += float(result["duration"])
				total_player_actions += int(
					result["player_actions"]
				)
				total_enemy_actions += int(
					result["enemy_actions"]
				)
				_merge_skill_uses(
					total_skill_uses,
					result["skill_uses"] as Dictionary
				)
			"defeat":
				defeats += 1
			_:
				deadlocks += 1
				deadlock_reason = result["reason"] as String

	return {
		"victories": victories,
		"defeats": defeats,
		"deadlocks": deadlocks,
		"average_hp_lost": (
			total_hp_lost / victories
			if victories > 0
			else 0.0
		),
		"average_mp_spent": (
			total_mp_spent / victories
			if victories > 0
			else 0.0
		),
		"average_duration": (
			total_duration / victories
			if victories > 0
			else 0.0
		),
		"average_player_actions": (
			float(total_player_actions) / victories
			if victories > 0
			else 0.0
		),
		"average_enemy_actions": (
			float(total_enemy_actions) / victories
			if victories > 0
			else 0.0
		),
		"skill_uses": total_skill_uses,
		"deadlock_reason": deadlock_reason,
	}


func _simulate_battle() -> Dictionary:
	var player_hp := float(PLAYER_STATS["max_hp"])
	var player_mp := float(PLAYER_STATS["max_mp"])
	var enemy_hp := float(ENEMY_STATS["max_hp"])
	var player_atb: float = 0.0
	var enemy_atb: float = 0.0
	var duration: float = 0.0
	var player_actions: int = 0
	var enemy_actions: int = 0
	var cooldowns: Dictionary = {}
	var skill_uses: Dictionary = {}

	var player_fill_time := BATTLE_BALANCE.get_atb_fill_time(
		float(PLAYER_STATS["spd"])
	)
	var enemy_fill_time := BATTLE_BALANCE.get_atb_fill_time(
		float(ENEMY_STATS["spd"])
	)

	for _action_index: int in range(MAX_ACTIONS_PER_BATTLE):
		var player_wait := (
			(1.0 - player_atb) * player_fill_time
		)
		var enemy_wait := (
			(1.0 - enemy_atb) * enemy_fill_time
		)
		var elapsed := minf(player_wait, enemy_wait)

		duration += elapsed
		player_atb = minf(
			player_atb + elapsed / player_fill_time,
			1.0
		)
		enemy_atb = minf(
			enemy_atb + elapsed / enemy_fill_time,
			1.0
		)
		_advance_cooldowns(cooldowns, elapsed)

		## Battle checks the player first when both ATBs fill together.
		if is_equal_approx(player_atb, 1.0):
			var skill := _select_skill(player_mp, cooldowns)

			if skill.is_empty():
				return {
					"status": "deadlock",
					"reason": (
						"Player ATB is full, but no skill is usable. "
						+ "Add a zero-cost, zero-CD fallback skill."
					),
				}

			player_atb = 0.0
			player_actions += 1
			player_mp -= float(skill["mp_cost"])

			var skill_id := skill["id"] as StringName
			var cooldown := float(
				skill["cooldown_seconds"]
			)

			if cooldown > 0.0:
				cooldowns[skill_id] = cooldown

			skill_uses[skill_id] = (
				int(skill_uses.get(skill_id, 0)) + 1
			)
			enemy_hp -= BATTLE_BALANCE.calculate_damage(
				float(PLAYER_STATS["atk"]),
				float(ENEMY_STATS["def"]),
				float(skill["power"])
			)

			if enemy_hp <= 0.0:
				return {
					"status": "victory",
					"player_hp": player_hp,
					"player_mp": player_mp,
					"duration": duration,
					"player_actions": player_actions,
					"enemy_actions": enemy_actions,
					"skill_uses": skill_uses,
				}

			continue

		enemy_atb = 0.0
		enemy_actions += 1
		player_hp -= BATTLE_BALANCE.calculate_damage(
			float(ENEMY_STATS["atk"]),
			float(PLAYER_STATS["def"]),
			BATTLE_BALANCE.basic_attack_power
		)

		if player_hp <= 0.0:
			return {
				"status": "defeat",
			}

	return {
		"status": "deadlock",
		"reason": (
			"Reached MAX_ACTIONS_PER_BATTLE before combat ended."
		),
	}


func _select_skill(
	current_mp: float,
	cooldowns: Dictionary
) -> Dictionary:
	for skill_variant: Variant in PLAYER_SKILLS:
		var skill := skill_variant as Dictionary
		var skill_id := skill["id"] as StringName

		if float(skill["mp_cost"]) > current_mp:
			continue

		if float(cooldowns.get(skill_id, 0.0)) > 0.0:
			continue

		return skill

	return {}


func _advance_cooldowns(
	cooldowns: Dictionary,
	elapsed: float
) -> void:
	for skill_id: Variant in cooldowns.keys():
		var remaining := maxf(
			float(cooldowns[skill_id]) - elapsed,
			0.0
		)

		if remaining <= 0.0:
			cooldowns.erase(skill_id)
		else:
			cooldowns[skill_id] = remaining


func _merge_skill_uses(
	totals: Dictionary,
	battle_uses: Dictionary
) -> void:
	for skill_id: Variant in battle_uses:
		totals[skill_id] = (
			int(totals.get(skill_id, 0))
			+ int(battle_uses[skill_id])
		)


func _print_summary(summary: Dictionary) -> void:
	var victories := int(summary["victories"])
	var success_rate := (
		float(victories)
		/ float(BATTLES_TO_SIMULATE)
		* 100.0
	)

	print("=== Battle Cost Estimate ===")
	print(
		"Player vs %s | simulations: %d"
		% [
			ENEMY_STATS["name"],
			BATTLES_TO_SIMULATE,
		]
	)
	print("Victory rate: %.1f%%" % success_rate)
	print(
		"Results: %d victories, %d defeats, %d deadlocks"
		% [
			victories,
			summary["defeats"],
			summary["deadlocks"],
		]
	)

	if victories <= 0:
		var reason := summary["deadlock_reason"] as String

		if not reason.is_empty():
			print("Deadlock reason: ", reason)

		print("No victory samples; HP and MP averages unavailable.")
		return

	print(
		"Average HP lost: %.2f / %.2f"
		% [
			summary["average_hp_lost"],
			PLAYER_STATS["max_hp"],
		]
	)
	print(
		"Average MP spent: %.2f / %.2f"
		% [
			summary["average_mp_spent"],
			PLAYER_STATS["max_mp"],
		]
	)
	print(
		"Average battle time: %.2fs"
		% summary["average_duration"]
	)
	print(
		"Average actions: player %.2f, enemy %.2f"
		% [
			summary["average_player_actions"],
			summary["average_enemy_actions"],
		]
	)

	var skill_uses := summary["skill_uses"] as Dictionary

	for skill_variant: Variant in PLAYER_SKILLS:
		var skill := skill_variant as Dictionary
		var skill_id := skill["id"] as StringName
		var average_uses := (
			float(skill_uses.get(skill_id, 0))
			/ float(victories)
		)

		print(
			"Average %s uses: %.2f"
			% [
				skill["name"],
				average_uses,
			]
		)


func _validate_configuration() -> String:
	if BATTLES_TO_SIMULATE <= 0:
		return "BATTLES_TO_SIMULATE must be greater than zero."

	for stat_name: String in [
		"max_hp",
		"max_mp",
		"atk",
		"def",
		"spd",
	]:
		if not PLAYER_STATS.has(stat_name):
			return "PLAYER_STATS is missing '%s'." % stat_name

	for stat_name: String in [
		"max_hp",
		"atk",
		"def",
		"spd",
	]:
		if not ENEMY_STATS.has(stat_name):
			return "ENEMY_STATS is missing '%s'." % stat_name

	if PLAYER_SKILLS.is_empty():
		return "PLAYER_SKILLS must contain at least one skill."

	for skill_variant: Variant in PLAYER_SKILLS:
		var skill := skill_variant as Dictionary

		for field_name: String in [
			"id",
			"name",
			"power",
			"mp_cost",
			"cooldown_seconds",
		]:
			if not skill.has(field_name):
				return (
					"One PLAYER_SKILLS entry is missing '%s'."
					% field_name
				)

	return ""
