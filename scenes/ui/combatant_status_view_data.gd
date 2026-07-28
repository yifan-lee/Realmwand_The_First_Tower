class_name CombatantStatusViewData
extends RefCounted

var portrait: Texture2D
var display_name: String

var current_hp: float
var max_hp: float
var current_mp: float
var max_mp: float

var atk: float
var def: float
var spd: float


static func from_player(player: Player) -> CombatantStatusViewData:
	var data := CombatantStatusViewData.new()

	data.display_name = player.display_name
	data.portrait = player.portrait
	data.current_hp = player.current_hp
	data.max_hp = player.max_hp
	data.current_mp = player.current_mp
	data.max_mp = player.max_mp
	data.atk = player.total_atk
	data.def = player.total_def
	data.spd = player.total_spd

	return data


static func from_enemy(
	enemy: EnemyData,
	current_hp: float,
	current_mp: float
) -> CombatantStatusViewData:
	var data := CombatantStatusViewData.new()

	data.display_name = enemy.display_name
	data.portrait = enemy.portrait
	data.current_hp = current_hp
	data.max_hp = enemy.max_hp
	data.current_mp = current_mp
	data.max_mp = enemy.max_mp
	data.atk = enemy.atk
	data.def = enemy.def
	data.spd = enemy.spd

	return data
