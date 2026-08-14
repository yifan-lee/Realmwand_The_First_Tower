extends Node2D

## 顶层场景入口：只负责连接世界、系统与 UI。
## 具体玩法逻辑保留在各自模块中。

@export var debug_skip_intro_and_bgm: bool = false

@onready var player: Player = $World/Player
@onready var game_hud: GameHUD = $OverlayRoot/GameHUD
@onready var esc_menu: EscMenu = $OverlayRoot/EscMenu
@onready var battle_ui: BattleUI = $OverlayRoot/BattleUI
@onready var level_up_ui: LevelUpUI = $OverlayRoot/LevelUpUI
@onready var npc_interaction_ui: NpcInteractionUI = $OverlayRoot/NpcInteractionUI
@onready var battle_manager: BattleManager = $Systems/BattleManager
@onready var level_up_manager: LevelUpManager = $Systems/LevelUpManager
@onready var npc_interaction_manager: NpcInteractionManager = $Systems/NpcInteractionManager
@onready var floor_manager: FloorManager = $Systems/FloorManager
@onready var save_manager: SaveManager = $Systems/SaveManager
@onready var tutorial_manager: TutorialManager = $Systems/TutorialManager
@onready var tutorial_ui: TutorialUI = $OverlayRoot/TutorialUI
@onready var intro_video: IntroVideo = $OverlayRoot/IntroVideo
@onready var feature_unlock_state: FeatureUnlockState = get_node("/root/FeatureUnlocks")
@onready var bgm_player: AudioStreamPlayer = $BgmPlayer

const BGM_INTRO = preload("res://assets/audios/intro.ogg")
const BGM_BATTLE = preload("res://assets/audios/battle.ogg")
const BGM_GENERAL = preload("res://assets/audios/general.ogg")

func play_bgm(stream: AudioStream) -> void:
	if debug_skip_intro_and_bgm:
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()


func _ready() -> void:
	player.set_input_enabled(false)

	intro_video.intro_finished.connect(
		_on_intro_finished
	)
	
	if debug_skip_intro_and_bgm:
		intro_video.hide()
		_on_intro_finished()
	else:
		play_bgm(BGM_INTRO)
		intro_video.play_intro()
	game_hud.bind_player(player)
	esc_menu.bind_player(player)
	tutorial_manager.setup(
		player,
		esc_menu,
		tutorial_ui,
		feature_unlock_state,
		battle_manager
	)
	save_manager.setup(player, floor_manager, tutorial_manager)
	esc_menu.bind_save_manager(save_manager)
	battle_manager.setup(player, battle_ui)
	level_up_manager.setup(player, level_up_ui)
	npc_interaction_manager.setup(player, npc_interaction_ui)
	battle_manager.battle_started.connect(
		_on_battle_started
	)
	battle_manager.battle_finished.connect(
		_on_battle_finished
	)


func _unhandled_input(event: InputEvent) -> void:
	if intro_video.is_playing_intro():
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed(&"toggle_menu"):
		if battle_manager.is_active() or level_up_manager.is_active() or npc_interaction_manager.is_active():
			get_viewport().set_input_as_handled()
			return
		esc_menu.toggle()
		get_viewport().set_input_as_handled()


func _on_battle_finished(victory: bool) -> void:
	play_bgm(BGM_GENERAL)


func _on_intro_finished() -> void:
	player.set_input_enabled(true)
	play_bgm(BGM_GENERAL)


func _on_battle_started(_enemy: Enemy) -> void:
	play_bgm(BGM_BATTLE)
