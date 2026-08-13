class_name GameHUD
extends CanvasLayer

@onready var stats_column: GameStatsColumn = $HudRoot/StatsColumn


func bind_player(player: Player) -> void:
	stats_column.bind_player(player)
