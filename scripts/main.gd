extends Node2D

## 顶层场景入口：只负责连接世界、系统与 UI。
## 具体玩法逻辑保留在各自模块中。

@onready var player: Player = $World/Player
@onready var game_hud: GameHUD = $OverlayRoot/GameHUD
@onready var esc_menu: EscMenu = $OverlayRoot/EscMenu
@onready var battle_ui: BattleUI = $OverlayRoot/BattleUI
@onready var level_up_ui: LevelUpUI = $OverlayRoot/LevelUpUI
@onready var battle_manager: BattleManager = $Systems/BattleManager
@onready var level_up_manager: LevelUpManager = $Systems/LevelUpManager


func _ready() -> void:
	game_hud.bind_player(player)
	esc_menu.bind_player(player)
	battle_manager.setup(player, battle_ui)
	level_up_manager.setup(player, level_up_ui)
	battle_manager.battle_finished.connect(
		_on_battle_finished
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_menu"):
		if battle_manager.is_active() or level_up_manager.is_active():
			get_viewport().set_input_as_handled()
			return
		esc_menu.toggle()
		get_viewport().set_input_as_handled()


func _on_battle_finished(victory: bool) -> void:
	game_hud.show_message(
		"战斗胜利。" if victory else "战斗结束。"
	)
