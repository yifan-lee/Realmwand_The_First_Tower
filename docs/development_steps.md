# Realmwand 从零重建实施步骤（1.1—8.x）

> 本文按当前仓库的实际实现整理。场景和资源必须在 Godot 编辑器中创建或修改，不直接手写 `.tscn` / `.tres`。

## 目录

- [第 1 块：数据层](#第-1-块数据层)
- [第 2 块：Player 与基础 Main](#第-2-块player-与基础-main)
- [第 3 块：Floor、Stair、Switch](#第-3-块floorstairswitch)
- [第 4 块：Enemy、Pickup、背包与装备](#第-4-块enemypickup背包与装备)
- [第 5 块：统一辅助 UI](#第-5-块统一辅助-ui)
- [第 6 块：HUD、ESC 与 Message](#第-6-块hudesc-与-message)
- [第 7 块：Battle、升级与 Main 拆分](#第-7-块battle升级与-main-拆分)
- [第 8 块：完整联调](#第-8-块完整联调)
- [全部 GDScript 完整源码](#全部-gdscript-完整源码)

## 第 1 块：数据层

### 1.1 数据脚本

在 `scripts/data/` 新建 `actor_data.gd`、`player_data.gd`、`enemy_data.gd`、`item_data.gd`、`equipment_data.gd`、`skill_data.gd`、`skill_effect_data.gd`。完整内容见末尾源码区。Resource 只保存定义；HP、MP、经验和数量等运行时状态不得写回共享 Resource。

### 1.2 EventBus

新建 `scripts/autoload/event_bus.gd`，在 **项目 → 项目设置 → 全局/自动加载（Project → Project Settings → Globals/Autoload）** 注册为 `EventBus`，统一转发换层和战斗请求。

### 1.3 角色、物品和技能资源

| 资源 | 类型 | Inspector 关键项 |
|---|---|---|
| `resources/actors/player.tres` | PlayerData | id、基础属性、sprite_frames、starting_skills |
| `resources/actors/enemy_balance_lv1.tres` | EnemyData | id、属性、skills、world_texture、portrait、奖励 |
| `resources/items/hp_recovery_lv1.tres` | ItemData | battle 可用、使用后消耗、HP Recovery=100 |
| `resources/items/fragment_red_lv1.tres` | ItemData | 图标、世界贴图、堆叠数 |
| `resources/equipment/blade_lv1.tres` | EquipmentData | 槽位、占用槽位、属性加成 |
| `resources/skills/basic_attack.tres` | SkillData | power、MP、cooldown_seconds |
| `resources/skills/hard_attack.tres` | SkillData | unlock_level=2、cooldown_seconds=3 |
| `resources/skills/battle_focus.tres` | SkillData | effect 使用 duration_seconds |

创建步骤：文件系统中右键目录 → **新建 → 资源（New → Resource）** → 选 Data 类 → 填 Inspector → 保存为表中路径。技能冷却和 Effect 持续范围都使用秒，和 ATB 的 `delta` 时间轴一致。

## 第 2 块：Player 与基础 Main

### 2.1 `player.tscn`

| 节点 | 类型 | Inspector 设置 |
|---|---|---|
| Player | CharacterBody2D | 挂 `player.gd`；Player Data=`player.tres` |
| AnimatedSprite2D | AnimatedSprite2D | SpriteFrames 运行时从 PlayerData 获取 |
| CollisionShape2D | CollisionShape2D | 适配 32×32 网格 |
| InteractionRay | RayCast2D | Enabled；长度由脚本更新 |
| Camera2D | Camera2D | Enabled |
| Inventory | Node | 挂 `inventory.gd` |
| Equipment | Node | 挂 `equipment_loadout.gd` |

地图视觉层整体偏移 `(-16, 16)`，逻辑对象仍可使用 32 的倍数定位。

### 2.2 `main.tscn` 基础结构

| 路径 | 类型/来源 |
|---|---|
| Main/World | Node2D |
| Main/World/FloorContainer | Node2D，场景唯一名称 |
| Main/World/Player | `player.tscn` 实例 |
| Main/Systems/FloorManager | Node + `floor_manager.gd` |
| Main/OverlayRoot | Node |

## 第 3 块：Floor、Stair、Switch

### 3.1 Floor

`floor.tscn` 根节点挂 `floor.gd`，包含 GroundLayer、WallLayer、FeatureLayer 三个 TileMapLayer，以及 SpawnPoints、Interactables、Enemies、Pickups。三层共用 `tower_tileset.tres`。`floor_1.tscn`、`floor_2.tscn`只设计地图和放置对象，专属规则写在 `floor_n.gd`。

### 3.2 Stair

| Inspector 属性 | 说明 |
|---|---|
| Direction | UP / DOWN，决定贴图 |
| Target Floor ID | 目标 `floor_n` ID |
| Target Spawn ID | 目标出生点名称 |

Stair 是 Area2D，Player 进入自动换层。出生点可与楼梯重叠；刚加载产生的初始重叠不会触发，必须先离开再进入。

### 3.3 Switch

Switch 是 StaticBody2D，CollisionShape2D 阻挡玩家。交互会反复切换 `is_active`。一层可放多个 Switch；每个 Switch 可在 `floor_n.gd` 中对应多个 TileMap cell。Switch 自己不包含地图规则。

## 第 4 块：Enemy、Pickup、背包与装备

### 4.1 Enemy

`enemy.tscn` 挂 `enemy.gd`；具体 `enemy_balance_lv1.tscn` 在 Inspector 填 `enemy_balance_lv1.tres`。Sprite2D.texture 不重复填写，脚本从 EnemyData.world_texture 自动取得。

### 4.2 Pickup、Inventory、Equipment

`item_pickup.tscn` 只填写 ItemData 和数量，同时支持普通物品与 EquipmentData。Inventory 按 id 保存资源引用与数量；`add_item` 返回未接纳余量。EquipmentLoadout 处理槽位和加成，Player 负责安全的装备/卸装事务。

## 第 5 块：统一辅助 UI

### 5.1 Theme 与组件

创建 `resources/themes/game_ui_theme.tres`，统一字体、Panel、Button 和间距。可复用组件如下：

| 场景 | 根节点 | 作用 |
|---|---|---|
| actor_stats_panel.tscn | PanelContainer | 角色属性及增量预览 |
| selectable_list_row.tscn | Button | 背包/技能共用行 |
| inventory_panel.tscn | PanelContainer | 绑定 Inventory |
| skill_panel.tscn | PanelContainer | 绑定 SkillData 数组 |
| entry_info_panel.tscn | PanelContainer | 物品/技能说明 |
| game_message_panel.tscn | PanelContainer | 独立 Message |
| player_stat_hud.tscn | PanelContainer | HUD 属性 |
| tracked_inventory_hud.tscn | PanelContainer | 跟踪物品数量 |

`row_scene` 在相应场景根节点 Inspector 中填写 `selectable_list_row.tscn` 或 `tracked_item_row.tscn`。

## 第 6 块：HUD、ESC 与 Message

### 6.1 GameHUD

`game_hud.tscn` 为 CanvasLayer，包含 PlayerStatHUD、TrackedInventoryHUD 和独立 GameMessagePanel。脚本绑定 Player、构造 ViewData，并转发消息。

### 6.2 ESC

`esc_menu.tscn` 实例化 InventoryPanel、SkillPanel 和 System 占位区，不含 Message 页。打开时禁用 Player 输入，关闭时恢复。在 **项目设置 → 输入映射（Input Map）** 建立 `toggle_menu` 并绑定 Escape。

## 第 7 块：Battle、升级与 Main 拆分

### 7.1 Battle UI 和 Manager

`battle_ui.tscn`：CanvasLayer → BattleRoot → Backdrop → Center → BattlePanel；内部实例化两个 ActorStatsPanel、SkillPanel、InventoryPanel，并放两个 ProgressBar、Message Label 和撤退 Button。尺寸、颜色、间距均在 Inspector 设置。

Main/Systems/BattleManager 挂 `battle_manager.gd`。ATB 与冷却按 `delta` 秒推进；Player ATB 满后选择技能/物品，Enemy ATB 满后自动行动。胜利结算经验/金币。

### 7.2 Level-up

`level_up_ui.tscn` 实例化 ActorStatsPanel，放生命、魔法、攻击、防御、速度五个按钮和关闭按钮。Main/Systems/LevelUpManager 挂 `level_up_manager.gd`。每级获得 5 点，全部分配后才可关闭。

### 7.3 Main 最终职责

Main 只做顶层 bind/setup、ESC UI 仲裁和战斗结果到 HUD Message 的转发；战斗公式、换层、背包和升级规则不写进 Main。

## 第 8 块：完整联调

### 8.1 检查点

1. Main 启动并加载 floor_1。
2. 移动、碰撞、多 Switch、多格地形变化、Stair 换层。
3. Pickup 入包，HUD 数量同步。
4. ESC 开关正确禁用/恢复输入。
5. Enemy → Battle UI；验证 ATB、伤害、冷却、物品、撤退和胜利。
6. 经验升级 → 分完 5 点 → 关闭升级 UI。
7. 运行 `python3 tools/run_basic_regression.py` 后再做目标交互测试和截图。
8. 更新 `docs/progress/YYYY-MM-DD.md`。

## 全部 GDScript 完整源码

以下源码直接取自当前仓库。具体调用链见 `code_reference.md`。
### 4.1 `scripts/actors/enemy.gd`

```gdscript
@tool
class_name Enemy
extends StaticBody2D

signal battle_requested(
	enemy: Enemy,
	player: Player
)
signal stats_changed

@export_group("Identity")
@export var instance_id: StringName = &""

@export_group("Data")
@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		_refresh_visual()


var current_hp: float = 0.0
var current_mp: float = 0.0
var is_defeated: bool = false

var _active_collision_layer: int = 0


func _ready() -> void:
	_refresh_visual()

	if Engine.is_editor_hint():
		return

	_active_collision_layer = collision_layer

	if enemy_data == null:
		push_error(
			"Enemy requires an EnemyData resource."
		)
		set_defeated(true)
		return

	current_hp = enemy_data.max_hp
	current_mp = enemy_data.max_mp


func interact(player: Player) -> void:
	if is_defeated:
		return

	battle_requested.emit(self, player)
	EventBus.battle_requested.emit(self, player)


func take_damage(amount: float) -> float:
	if is_defeated or amount <= 0.0:
		return 0.0

	var applied_damage: float = minf(
		amount,
		current_hp
	)

	current_hp -= applied_damage
	stats_changed.emit()

	if current_hp <= 0.0:
		current_hp = 0.0
		set_defeated(true)

	return applied_damage


func change_mp(amount: float) -> void:
	if enemy_data == null:
		return

	current_mp = clampf(
		current_mp + amount,
		0.0,
		enemy_data.max_mp
	)
	stats_changed.emit()


func set_defeated(defeated: bool) -> void:
	is_defeated = defeated
	visible = not is_defeated

	set_deferred(
		"collision_layer",
		0 if is_defeated
		else _active_collision_layer
	)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if instance_id.is_empty():
		warnings.append(
			"Enemy requires a unique floor instance ID."
		)

	if enemy_data == null:
		warnings.append(
			"Enemy requires an EnemyData resource."
		)
	elif enemy_data.id.is_empty():
		warnings.append(
			"EnemyData requires a non-empty ID."
		)


	if (
		enemy_data != null
		and enemy_data.world_texture == null
	):
		warnings.append(
			"EnemyData requires a world texture."
		)

	return warnings


func _refresh_visual() -> void:
	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return

	if enemy_data == null:
		sprite.texture = null
		return

	sprite.texture = enemy_data.world_texture
```

### 2.2 `scripts/actors/player.gd`

```gdscript
class_name Player
extends CharacterBody2D

signal movement_finished
signal stats_changed
signal level_up_available

@export var player_data: PlayerData

@export_group("Movement")
@export_range(1.0, 256.0, 1.0) var grid_size: float = 32.0
@export_range(0.01, 1.0, 0.01) var move_duration: float = 0.16

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_ray: RayCast2D = $InteractionRay
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentLoadout = $Equipment

var level: int = 1
var experience: int = 0
var gold: int = 0
var unspent_stat_points: int = 0

var base_max_hp: float = 0.0
var base_max_mp: float = 0.0
var base_atk: float = 0.0
var base_def: float = 0.0
var base_spd: float = 0.0

var current_hp: float = 0.0
var current_mp: float = 0.0


var learned_skills: Array[SkillData] = []

var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var input_enabled: bool = true


func _ready() -> void:
	if player_data == null:
		push_error("Player requires a PlayerData resource.")
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	_initialize_runtime_state()
	_apply_data_visuals()
	_update_interaction_ray()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or is_moving:
		return

	if event.is_action_pressed(&"interact"):
		_try_interact()
		get_viewport().set_input_as_handled()
		return

	var direction := Vector2.ZERO

	if event.is_action_pressed(&"move_up"):
		direction = Vector2.UP
	elif event.is_action_pressed(&"move_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed(&"move_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed(&"move_right"):
		direction = Vector2.RIGHT

	if direction == Vector2.ZERO:
		return

	_set_facing_direction(direction)
	_move_one_tile(direction)
	get_viewport().set_input_as_handled()


func _initialize_runtime_state() -> void:
	level = player_data.starting_level
	experience = player_data.starting_experience
	gold = player_data.starting_gold

	base_max_hp = player_data.max_hp
	base_max_mp = player_data.max_mp
	base_atk = player_data.atk
	base_def = player_data.def
	base_spd = player_data.spd

	current_hp = base_max_hp
	current_mp = base_max_mp

	for starting_item: ItemData in player_data.starting_items:
		var remaining_amount := inventory.add_item(starting_item)

		if remaining_amount > 0:
			push_warning(
				"Could not add starting item '%s'."
				% starting_item.id
			)

	learned_skills = player_data.starting_skills.duplicate()


func _apply_data_visuals() -> void:
	if player_data.sprite_frames != null:
		animated_sprite.sprite_frames = player_data.sprite_frames

	_play_directional_animation(&"idle")


func _set_facing_direction(direction: Vector2) -> void:
	facing_direction = direction
	_update_interaction_ray()


func _update_interaction_ray() -> void:
	interaction_ray.target_position = (
		facing_direction * grid_size
	)


func _move_one_tile(direction: Vector2) -> void:
	var motion := direction * grid_size

	if test_move(global_transform, motion):
		_play_directional_animation(&"idle")
		return

	is_moving = true
	_play_directional_animation(&"walk")

	var target_position := global_position + motion
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		self,
		"global_position",
		target_position,
		move_duration
	)

	await tween.finished

	global_position = target_position
	is_moving = false
	_play_directional_animation(&"idle")
	movement_finished.emit()


func _play_directional_animation(
	action: StringName
) -> void:
	if animated_sprite.sprite_frames == null:
		return

	var animation_name := StringName(
		"%s_%s"
		% [
			action,
			_get_direction_suffix(),
		]
	)

	if animated_sprite.sprite_frames.has_animation(
		animation_name
	):
		animated_sprite.play(animation_name)


func _get_direction_suffix() -> StringName:
	if facing_direction == Vector2.UP:
		return &"up"

	if facing_direction == Vector2.DOWN:
		return &"down"

	if facing_direction == Vector2.LEFT:
		return &"left"

	return &"right"


func _try_interact() -> void:
	interaction_ray.force_raycast_update()

	if not interaction_ray.is_colliding():
		return

	var target: Object = interaction_ray.get_collider()

	if target == null:
		return

	if target.has_method(&"interact"):
		target.call(&"interact", self)


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled

	if not input_enabled and not is_moving:
		_play_directional_animation(&"idle")

func set_current_hp(value: float) -> void:
	var next_hp: float = clampf(
		value,
		0.0,
		get_max_hp()
	)

	if is_equal_approx(current_hp, next_hp):
		return

	current_hp = next_hp
	stats_changed.emit()


func change_hp(amount: float) -> void:
	set_current_hp(current_hp + amount)


func set_current_mp(value: float) -> void:
	var next_mp: float = clampf(
		value,
		0.0,
		get_max_mp()
	)

	if is_equal_approx(current_mp, next_mp):
		return

	current_mp = next_mp
	stats_changed.emit()


func change_mp(amount: float) -> void:
	set_current_mp(current_mp + amount)


func get_experience_for_next_level() -> int:
	return level * 100


func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount
	var leveled_up := false

	while experience >= get_experience_for_next_level():
		experience -= get_experience_for_next_level()
		level += 1
		unspent_stat_points += 5
		leveled_up = true

	stats_changed.emit()

	if leveled_up:
		level_up_available.emit()


func spend_stat_point(stat_id: StringName) -> bool:
	if unspent_stat_points <= 0:
		return false

	match stat_id:
		&"max_hp":
			base_max_hp += 10.0
			current_hp += 10.0
		&"max_mp":
			base_max_mp += 5.0
			current_mp += 5.0
		&"atk":
			base_atk += 1.0
		&"def":
			base_def += 1.0
		&"spd":
			base_spd += 1.0
		_:
			return false

	unspent_stat_points -= 1
	stats_changed.emit()
	return true

func equip_item(
	item_id: StringName,
	target_slot: int
) -> bool:
	var item := inventory.get_item(
		item_id
	) as EquipmentData

	if item == null:
		return false

	if not equipment.can_equip(
		item,
		target_slot
	):
		return false

	var displaced_items: Array[EquipmentData] = (
		equipment.get_displaced_items(
			item,
			target_slot
		)
	)

	for displaced_item: EquipmentData in displaced_items:
		var available_capacity: int = (
			inventory.get_remaining_capacity(
				displaced_item
			)
		)

		if displaced_item.id == item.id:
			available_capacity += 1

		if available_capacity < 1:
			return false

	if not inventory.remove_item(item_id):
		return false

	var actual_displaced_items: Array[EquipmentData] = (
		equipment.equip(
			item,
			target_slot
		)
	)

	for displaced_item: EquipmentData in (
		actual_displaced_items
	):
		var remaining_amount: int = (
			inventory.add_item(displaced_item)
		)

		if remaining_amount > 0:
			push_error(
				"Could not return displaced equipment '%s'."
				% displaced_item.id
			)
			return false

	return true


func unequip_item(target_slot: int) -> bool:
	var item := equipment.get_equipped(
		target_slot
	)

	if item == null:
		return false

	var remaining_amount: int = (
		inventory.add_item(item)
	)

	if remaining_amount > 0:
		return false

	equipment.unequip(target_slot)

	return true


func get_max_hp() -> float:
	return (
		base_max_hp
		+ equipment.get_max_hp_bonus()
	)


func get_max_mp() -> float:
	return (
		base_max_mp
		+ equipment.get_max_mp_bonus()
	)


func get_atk() -> float:
	return (
		base_atk
		+ equipment.get_atk_bonus()
	)


func get_def() -> float:
	return (
		base_def
		+ equipment.get_def_bonus()
	)


func get_spd() -> float:
	return (
		base_spd
		+ equipment.get_spd_bonus()
	)


func _on_equipment_changed() -> void:
	current_hp = minf(
		current_hp,
		get_max_hp()
	)
	current_mp = minf(
		current_mp,
		get_max_mp()
	)

	stats_changed.emit()
```

### 1.3 `scripts/autoload/event_bus.gd`

```gdscript
extends Node

signal floor_change_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
)

signal battle_requested(
	enemy: Enemy,
	player: Player
)
```

### 7.4 `scripts/battle/battle_manager.gd`

```gdscript
class_name BattleManager
extends Node

signal battle_started(enemy: Enemy)
signal battle_finished(victory: bool)

const ATB_MAX := 100.0

var _player: Player
var _enemy: Enemy
var _battle_ui: BattleUI
var _active := false
var _player_atb := 0.0
var _enemy_atb := 0.0
var _player_ready := false
var _cooldowns: Dictionary[StringName, float] = {}


func setup(player: Player, battle_ui: BattleUI) -> void:
	_player = player
	_battle_ui = battle_ui
	EventBus.battle_requested.connect(_on_battle_requested)
	battle_ui.skill_selected.connect(_on_skill_selected)
	battle_ui.item_selected.connect(_on_item_selected)
	battle_ui.escape_requested.connect(_on_escape_requested)


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active or _enemy == null:
		return

	_tick_cooldowns(delta)

	if not _player_ready:
		_player_atb = minf(ATB_MAX, _player_atb + _player.get_spd() * delta)
		if _player_atb >= ATB_MAX:
			_player_ready = true
			_battle_ui.set_action_available(true)
			_battle_ui.show_message("轮到你行动。")

	_enemy_atb = minf(ATB_MAX, _enemy_atb + _enemy.enemy_data.spd * delta)
	if _enemy_atb >= ATB_MAX:
		_enemy_atb = 0.0
		_enemy_take_turn()

	_battle_ui.set_atb(_player_atb, _enemy_atb)


func start_battle(enemy: Enemy, player: Player) -> void:
	if _active or enemy == null or player == null or enemy.is_defeated:
		return

	_enemy = enemy
	_player = player
	_active = true
	_player_atb = 0.0
	_enemy_atb = 0.0
	_player_ready = false
	_cooldowns.clear()
	_player.set_input_enabled(false)
	_battle_ui.open(_player, _enemy)
	_battle_ui.show_message("遭遇 %s，战斗开始。" % _enemy.enemy_data.display_name)
	battle_started.emit(_enemy)


func _on_battle_requested(enemy: Enemy, player: Player) -> void:
	start_battle(enemy, player)


func _on_skill_selected(skill: SkillData) -> void:
	if not _active or not _player_ready or skill == null:
		return
	if _cooldowns.get(skill.id, 0.0) > 0.0:
		_battle_ui.show_message("%s 仍在冷却。" % skill.display_name)
		return
	if _player.current_mp < skill.mp_cost:
		_battle_ui.show_message("MP 不足。")
		return

	_player.change_mp(-skill.mp_cost)
	var damage := maxf(1.0, _player.get_atk() + skill.skill_power - _enemy.enemy_data.def)
	var applied := _enemy.take_damage(damage)
	_cooldowns[skill.id] = skill.cooldown_seconds
	_battle_ui.show_message("%s 造成了 %.0f 点伤害。" % [skill.display_name, applied])
	_complete_player_action()

	if _enemy.is_defeated:
		_finish_battle(true)


func _on_item_selected(item: ItemData) -> void:
	if not _active or not _player_ready or item == null:
		return
	if not item.usable_in_battle:
		_battle_ui.show_message("这个物品不能在战斗中使用。")
		return

	_player.change_hp(item.hp_recovery)
	_player.change_mp(item.mp_recovery)
	if item.consumed_on_use:
		_player.inventory.remove_item(item.id)
	_battle_ui.show_message("使用了 %s。" % item.display_name)
	_complete_player_action()


func _on_escape_requested() -> void:
	if _active:
		_finish_battle(false)


func _enemy_take_turn() -> void:
	if not _active:
		return

	var power := 0.0
	var skill_name := "攻击"
	if not _enemy.enemy_data.skills.is_empty():
		var skill: SkillData = _enemy.enemy_data.skills.front()
		power = skill.skill_power
		skill_name = skill.display_name

	var damage := maxf(1.0, _enemy.enemy_data.atk + power - _player.get_def())
	_player.change_hp(-damage)
	_battle_ui.refresh_stats()
	_battle_ui.show_message("%s 使用 %s，造成 %.0f 点伤害。" % [_enemy.enemy_data.display_name, skill_name, damage])

	if _player.current_hp <= 0.0:
		_finish_battle(false)


func _complete_player_action() -> void:
	_player_atb = 0.0
	_player_ready = false
	_battle_ui.set_action_available(false)
	_battle_ui.refresh_stats()


func _finish_battle(victory: bool) -> void:
	if not _active:
		return

	_active = false
	_battle_ui.close()
	_player.set_input_enabled(true)

	if victory:
		var reward := _get_experience_reward()
		_player.gold += _enemy.enemy_data.gold_reward
		_player.add_experience(reward)
	else:
		_player.set_current_hp(maxf(1.0, _player.current_hp))

	battle_finished.emit(victory)
	_enemy = null


func _get_experience_reward() -> int:
	if _enemy.enemy_data.experience_reward_override >= 0:
		return _enemy.enemy_data.experience_reward_override
	return maxi(1, roundi(_enemy.enemy_data.max_hp * 0.25))


func _tick_cooldowns(delta: float) -> void:
	for skill_id: StringName in _cooldowns.keys():
		_cooldowns[skill_id] = maxf(0.0, _cooldowns[skill_id] - delta)
```

### 7.5 `scripts/battle/battle_ui.gd`

```gdscript
class_name BattleUI
extends CanvasLayer

signal skill_selected(skill: SkillData)
signal item_selected(item: ItemData)
signal escape_requested

@onready var battle_root: Control = $BattleRoot
@onready var player_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Stats/PlayerStats
@onready var enemy_stats: ActorStatsPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Stats/EnemyStats
@onready var player_atb: ProgressBar = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Gauges/PlayerAtb
@onready var enemy_atb: ProgressBar = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Gauges/EnemyAtb
@onready var skill_panel: SkillPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Actions/SkillPanel
@onready var inventory_panel: InventoryPanel = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Actions/InventoryPanel
@onready var message_label: Label = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/Message
@onready var escape_button: Button = $BattleRoot/Backdrop/Center/BattlePanel/Margin/Content/EscapeButton

var _player: Player
var _enemy: Enemy


func _ready() -> void:
	skill_panel.skill_selected.connect(skill_selected.emit)
	inventory_panel.item_selected.connect(item_selected.emit)
	escape_button.pressed.connect(escape_requested.emit)


func open(player: Player, enemy: Enemy) -> void:
	_player = player
	_enemy = enemy
	skill_panel.display_skills(player.learned_skills)
	inventory_panel.bind_inventory(player.inventory)
	battle_root.visible = true
	set_action_available(false)
	refresh_stats()


func close() -> void:
	battle_root.visible = false
	inventory_panel.bind_inventory(null)
	_player = null
	_enemy = null


func set_action_available(available: bool) -> void:
	skill_panel.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	skill_panel.modulate.a = 1.0 if available else 0.55
	inventory_panel.modulate.a = 1.0 if available else 0.55


func set_atb(player_value: float, enemy_value: float) -> void:
	player_atb.value = player_value
	enemy_atb.value = enemy_value


func show_message(message: String) -> void:
	message_label.text = message


func refresh_stats() -> void:
	player_stats.display_stats(_build_player_view())
	enemy_stats.display_stats(_build_enemy_view())


func _build_player_view() -> ActorStatsViewData:
	if _player == null or _player.player_data == null:
		return null

	var view := ActorStatsViewData.new()
	view.display_name = _player.player_data.display_name
	view.portrait = _player.player_data.portrait
	view.current_hp = _player.current_hp
	view.max_hp = _player.get_max_hp()
	view.current_mp = _player.current_mp
	view.max_mp = _player.get_max_mp()
	view.atk = _player.get_atk()
	view.def = _player.get_def()
	view.spd = _player.get_spd()
	return view


func _build_enemy_view() -> ActorStatsViewData:
	if _enemy == null or _enemy.enemy_data == null:
		return null

	var view := ActorStatsViewData.new()
	view.display_name = _enemy.enemy_data.display_name
	view.portrait = _enemy.enemy_data.portrait
	view.current_hp = _enemy.current_hp
	view.max_hp = _enemy.enemy_data.max_hp
	view.current_mp = _enemy.current_mp
	view.max_mp = _enemy.enemy_data.max_mp
	view.atk = _enemy.enemy_data.atk
	view.def = _enemy.enemy_data.def
	view.spd = _enemy.enemy_data.spd
	return view
```

### 1.6 `scripts/data/actor_data.gd`

```gdscript
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
```

### 1.7 `scripts/data/enemy_data.gd`

```gdscript
class_name EnemyData
extends ActorData

@export_group("Battle")
@export var skills: Array[SkillData] = []

@export_group("Rewards")
@export var experience_reward_override: int = -1
@export_range(0, 999999, 1) var gold_reward: int = 0


@export_group("World Presentation")
@export var world_texture: Texture2D
```

### 1.8 `scripts/data/equipment_data.gd`

```gdscript
class_name EquipmentData
extends ItemData


enum EquipmentSlotType {
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	HAND,
	ACCESSORY,
}

enum HandRule {
	NONE,
	LEFT_ONLY,
	RIGHT_ONLY,
	EITHER_HAND,
	TWO_HANDED,
}

@export_group("Equipment")
@export var slot_type: EquipmentSlotType = EquipmentSlotType.HAND
@export var hand_rule: HandRule = HandRule.NONE


@export_group("Stat Bonuses")
@export var max_hp_bonus: float = 0.0
@export var max_mp_bonus: float = 0.0
@export var atk_bonus: float = 0.0
@export var def_bonus: float = 0.0
@export var spd_bonus: float = 0.0
```

### 1.9 `scripts/data/item_data.gd`

```gdscript
class_name ItemData
extends Resource

enum ItemType {
	CONSUMABLE,
	EQUIPMENT,
	KEY_ITEM,
	MATERIAL,
}

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.CONSUMABLE

@export_group("Visual")
@export var icon: Texture2D
@export var world_texture: Texture2D

@export_group("Inventory")
@export_range(1, 999, 1) var max_stack: int = 99

@export_group("Usage")
@export var usable_from_inventory: bool = false
@export var usable_in_battle: bool = false
@export var consumed_on_use: bool = false
@export_range(0.0, 999999.0, 1.0) var hp_recovery: float = 0.0
@export_range(0.0, 999999.0, 1.0) var mp_recovery: float = 0.0
```

### 1.10 `scripts/data/player_data.gd`

```gdscript
class_name PlayerData
extends ActorData

@export_group("Player Visual")
@export var sprite_frames: SpriteFrames

@export_group("Starting Progression")
@export_range(1, 99, 1) var starting_level: int = 1
@export_range(0, 999999999, 1) var starting_experience: int = 0
@export_range(0, 999999999, 1) var starting_gold: int = 0

@export_group("Starting Content")
@export var starting_items: Array[ItemData] = []
@export var starting_skills: Array[SkillData] = []
```

### 1.11 `scripts/data/skill_data.gd`

```gdscript
class_name SkillData
extends Resource

enum TargetType {
	ENEMY,
	SELF,
}

@export_group("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export_group("Progression")
@export_range(1, 99, 1) var unlock_level: int = 1

@export_group("Usage")
@export_range(0.0, 9999.0, 0.1) var mp_cost: float = 0.0
@export_range(0.0, 9999.0, 0.1) var cooldown_seconds: float = 0.0
@export var target_type: TargetType = TargetType.ENEMY

@export_group("Damage")
@export_range(0.0, 99999.0, 0.1) var skill_power: float = 0.0

@export_group("Effects")
@export var effects: Array[SkillEffectData] = []
```

### 1.12 `scripts/data/skill_effect_data.gd`

```gdscript
class_name SkillEffectData
extends Resource

enum EffectType {
	ATK,
	DEF,
	SPD,
}

enum TargetType {
	SELF,
	ENEMY,
}

enum OperationType {
	ADD,
	MULTIPLY,
}

@export_group("Effect")
@export var effect_type: EffectType = EffectType.ATK
@export var target_type: TargetType = TargetType.SELF
@export var operation_type: OperationType = OperationType.ADD

@export_group("Value")
@export var value: float = 0.0
@export_range(0.1, 999.0, 0.1) var duration_seconds: float = 5.0
```

### 3.13 `scripts/floors/floor.gd`

```gdscript
class_name Floor
extends Node2D


class TileCellSnapshot:
	extends RefCounted

	var cell: Vector2i
	var source_id: int
	var atlas_coords: Vector2i
	var alternative_tile: int

	func _init(
		target_cell: Vector2i,
		target_source_id: int,
		target_atlas_coords: Vector2i,
		target_alternative_tile: int
	) -> void:
		cell = target_cell
		source_id = target_source_id
		atlas_coords = target_atlas_coords
		alternative_tile = target_alternative_tile

@export_group("Identity")
@export var floor_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Spawning")
@export var default_spawn_id: StringName = &"FromStart"

@onready var spawn_points: Node2D = $SpawnPoints
@onready var interactables: Node2D = %Interactables
@onready var enemies: Node2D = %Enemies
@onready var pickups: Node2D = %Pickups


func get_spawn_point(spawn_id: StringName) -> Marker2D:
	var resolved_id := spawn_id

	if resolved_id == &"":
		resolved_id = default_spawn_id

	var marker := spawn_points.get_node_or_null(
		NodePath(String(resolved_id))
	) as Marker2D

	if marker == null:
		push_error(
			"Floor '%s' has no spawn point '%s'."
			% [floor_id, resolved_id]
		)

	return marker


func capture_tile_cells(
	layer: TileMapLayer,
	cells: Array[Vector2i]
) -> Array[TileCellSnapshot]:
	var snapshots: Array[TileCellSnapshot] = []

	for cell: Vector2i in cells:
		var source_id := layer.get_cell_source_id(cell)

		if source_id == -1:
			push_error(
				"Floor '%s' has no tile at cell %s."
				% [floor_id, cell]
			)
			continue

		var snapshot := TileCellSnapshot.new(
			cell,
			source_id,
			layer.get_cell_atlas_coords(cell),
			layer.get_cell_alternative_tile(cell)
		)

		snapshots.append(snapshot)

	return snapshots


func set_tile_cells_removed(
	layer: TileMapLayer,
	snapshots: Array[TileCellSnapshot],
	removed: bool
) -> void:
	for snapshot: TileCellSnapshot in snapshots:
		if removed:
			layer.erase_cell(snapshot.cell)
		else:
			layer.set_cell(
				snapshot.cell,
				snapshot.source_id,
				snapshot.atlas_coords,
				snapshot.alternative_tile
			)

func capture_runtime_state() -> Dictionary:
	var switch_states: Dictionary = {}
	var pickup_states: Dictionary = {}
	var enemy_states: Dictionary = {}

	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch == null:
			continue

		if floor_switch.switch_id.is_empty():
			continue

		var switch_key := String(
			floor_switch.switch_id
		)

		switch_states[switch_key] = (
			floor_switch.is_active
		)

	for child: Node in pickups.get_children():
		var item_pickup := child as ItemPickup

		if item_pickup == null:
			continue

		if item_pickup.pickup_id.is_empty():
			continue

		var pickup_key := String(
			item_pickup.pickup_id
		)

		pickup_states[pickup_key] = {
			"is_collected":
				item_pickup.is_collected,
			"amount":
				item_pickup.amount,
		}

	for child: Node in enemies.get_children():
		var enemy := child as Enemy

		if enemy == null:
			continue

		if enemy.instance_id.is_empty():
			continue

		var enemy_key := String(
			enemy.instance_id
		)

		enemy_states[enemy_key] = {
			"is_defeated": enemy.is_defeated,
			"current_hp": enemy.current_hp,
			"current_mp": enemy.current_mp,
		}

	return {
		"switches": switch_states,
		"pickups": pickup_states,
		"enemies": enemy_states,
	}


func apply_runtime_state(state: Dictionary) -> void:
	_apply_switch_states(
		state.get("switches", {})
	)
	_apply_pickup_states(
		state.get("pickups", {})
	)
	_apply_enemy_states(
		state.get("enemies", {})
	)


func _apply_switch_states(
	switch_states_value: Variant
) -> void:
	if not (switch_states_value is Dictionary):
		push_error(
			"Floor '%s' has invalid switch state data."
			% floor_id
		)
		return

	var switch_states: Dictionary = switch_states_value

	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch == null:
			continue

		var switch_key := String(
			floor_switch.switch_id
		)

		if not switch_states.has(switch_key):
			continue

		floor_switch.set_active(
			bool(switch_states[switch_key])
		)


func _apply_pickup_states(
	pickup_states_value: Variant
) -> void:
	if not (pickup_states_value is Dictionary):
		push_error(
			"Floor '%s' has invalid pickup state data."
			% floor_id
		)
		return

	var pickup_states: Dictionary = pickup_states_value

	for child: Node in pickups.get_children():
		var item_pickup := child as ItemPickup

		if item_pickup == null:
			continue

		var pickup_key := String(
			item_pickup.pickup_id
		)

		if not pickup_states.has(pickup_key):
			continue

		var pickup_state_value: Variant = (
			pickup_states[pickup_key]
		)

		if not (pickup_state_value is Dictionary):
			push_error(
				"Pickup '%s' has invalid state data."
				% item_pickup.pickup_id
			)
			continue

		var pickup_state: Dictionary = (
			pickup_state_value
		)

		item_pickup.amount = maxi(
			1,
			int(
				pickup_state.get(
					"amount",
					item_pickup.amount
				)
			)
		)

		item_pickup.set_collected(
			bool(
				pickup_state.get(
					"is_collected",
					false
				)
			)
		)


func _apply_enemy_states(
	enemy_states_value: Variant
) -> void:
	if not (enemy_states_value is Dictionary):
		push_error(
			"Floor '%s' has invalid enemy state data."
			% floor_id
		)
		return

	var enemy_states: Dictionary = enemy_states_value

	for child: Node in enemies.get_children():
		var enemy := child as Enemy

		if enemy == null:
			continue

		var enemy_key := String(
			enemy.instance_id
		)

		if not enemy_states.has(enemy_key):
			continue

		var enemy_state_value: Variant = (
			enemy_states[enemy_key]
		)

		if not (enemy_state_value is Dictionary):
			push_error(
				"Enemy '%s' has invalid state data."
				% enemy.instance_id
			)
			continue

		var enemy_state: Dictionary = (
			enemy_state_value
		)

		enemy.current_hp = maxf(
			0.0,
			float(
				enemy_state.get(
					"current_hp",
					enemy.current_hp
				)
			)
		)

		enemy.current_mp = maxf(
			0.0,
			float(
				enemy_state.get(
					"current_mp",
					enemy.current_mp
				)
			)
		)

		enemy.set_defeated(
			bool(
				enemy_state.get(
					"is_defeated",
					false
				)
			)
		)
```

### 3.14 `scripts/floors/floor_1.gd`

```gdscript
extends Floor


class SwitchTerrainRule:
	extends RefCounted

	var switch_id: StringName
	var wall_cells: Array[Vector2i]
	var wall_snapshots: Array[Floor.TileCellSnapshot] = []

	func _init(
		target_switch_id: StringName,
		target_wall_cells: Array[Vector2i]
	) -> void:
		switch_id = target_switch_id
		wall_cells = target_wall_cells


@onready var wall_layer: TileMapLayer = %WallLayer

var switch_rules: Array[SwitchTerrainRule] = []


func _ready() -> void:
	_create_switch_rules()
	_cache_switch_terrain()
	_apply_initial_switch_states()


func _create_switch_rules() -> void:
	switch_rules = [
		SwitchTerrainRule.new(
			&"wall_passage",
			[
				Vector2i(1, -6),
				Vector2i(0, -6),
                Vector2i(-1, -6),
			]
		),
	]


func _cache_switch_terrain() -> void:
	for rule: SwitchTerrainRule in switch_rules:
		rule.wall_snapshots = capture_tile_cells(
			wall_layer,
			rule.wall_cells
		)


func _apply_initial_switch_states() -> void:
	for child: Node in interactables.get_children():
		var floor_switch := child as FloorSwitch

		if floor_switch == null:
			continue

		_apply_switch_state(
			floor_switch.switch_id,
			floor_switch.is_active
		)


func _on_floor_switch_state_changed(
	switch_id: StringName,
	is_active: bool
) -> void:
	_apply_switch_state(switch_id, is_active)


func _apply_switch_state(
	switch_id: StringName,
	is_active: bool
) -> void:
	for rule: SwitchTerrainRule in switch_rules:
		if rule.switch_id != switch_id:
			continue

		set_tile_cells_removed(
			wall_layer,
			rule.wall_snapshots,
			is_active
		)
		return

	push_warning(
		"Floor '%s' has no terrain rule for switch '%s'."
		% [floor_id, switch_id]
	)
```

### 3.15 `scripts/floors/floor_manager.gd`

```gdscript
class_name FloorManager
extends Node

const FLOOR_SCENE_DIRECTORY := "res://scenes/floors"

@export_group("Startup")
@export var starting_floor_id: StringName = &"floor_1"
@export var starting_spawn_id: StringName = &"FromStart"

@onready var floor_container: Node2D = %FloorContainer
@onready var player: Player = %Player

var current_floor: Floor
var current_floor_id: StringName = &""
var floor_states: Dictionary = {}


func _ready() -> void:
	EventBus.floor_change_requested.connect(
		_on_floor_change_requested
	)

	change_floor(
		starting_floor_id,
		starting_spawn_id
	)


func change_floor(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	if target_floor_id == &"":
		push_error("Cannot load a floor with an empty ID.")
		return

	var floor_path := (
		"%s/%s.tscn"
		% [
			FLOOR_SCENE_DIRECTORY,
			String(target_floor_id),
		]
	)

	if not ResourceLoader.exists(floor_path):
		push_error(
			"Floor scene does not exist: %s"
			% floor_path
		)
		return

	var floor_scene := ResourceLoader.load(
		floor_path,
		"PackedScene"
	) as PackedScene

	if floor_scene == null:
		push_error(
			"Failed to load floor scene: %s"
			% floor_path
		)
		return

	# Runtime-only: the requested floor is only known during play.
	var new_floor := floor_scene.instantiate() as Floor

	if new_floor == null:
		push_error(
			"Floor scene root must inherit Floor: %s"
			% floor_path
		)
		return

	if new_floor.floor_id != target_floor_id:
		push_error(
			"Floor ID '%s' does not match requested ID '%s'."
			% [
				new_floor.floor_id,
				target_floor_id,
			]
		)
		new_floor.queue_free()
		return

	floor_container.add_child(new_floor)

	var spawn_point := new_floor.get_spawn_point(
		target_spawn_id
	)

	if spawn_point == null:
		floor_container.remove_child(new_floor)
		new_floor.queue_free()
		return

	player.set_input_enabled(false)

	_store_current_floor_state()

	if is_instance_valid(current_floor):
		floor_container.remove_child(current_floor)
		current_floor.queue_free()

	current_floor = new_floor
	current_floor_id = target_floor_id

	_apply_saved_floor_state(current_floor)

	
	player.global_position = spawn_point.global_position

	player.set_input_enabled(true)


func _on_floor_change_requested(
	target_floor_id: StringName,
	target_spawn_id: StringName
) -> void:
	change_floor(
		target_floor_id,
		target_spawn_id
	)


func _store_current_floor_state() -> void:
	if not is_instance_valid(current_floor):
		return

	var floor_key := String(current_floor.floor_id)

	floor_states[floor_key] = (
		current_floor.capture_runtime_state()
	)

func _apply_saved_floor_state(
	floor: Floor
) -> void:
	var floor_key := String(floor.floor_id)

	if not floor_states.has(floor_key):
		return

	var saved_state: Dictionary = floor_states[floor_key]

	floor.apply_runtime_state(saved_state)
```

### 4.16 `scripts/interactables/item_pickup.gd`

```gdscript
@tool
class_name ItemPickup
extends Area2D

signal picked_up(item: ItemData, amount: int)

@export_group("Identity")
@export var pickup_id: StringName = &""

@export_group("Content")
@export var item_data: ItemData:
	set(value):
		item_data = value
		_refresh_visual()

@export_range(1, 999, 1) var amount: int = 1

var is_collected: bool = false


func _ready() -> void:
	_refresh_visual()


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if is_collected:
		return

	if not body is Player:
		return

	if item_data == null or amount <= 0:
		return

	var player := body as Player
	var remaining_amount: int = (
		player.inventory.add_item(item_data, amount)
	)
	var accepted_amount: int = amount - remaining_amount

	if accepted_amount <= 0:
		return

	picked_up.emit(item_data, accepted_amount)

	if remaining_amount == 0:
		set_collected(true)
	else:
		amount = remaining_amount


func _refresh_visual() -> void:
	var sprite := get_node_or_null(
		"Sprite2D"
	) as Sprite2D

	if sprite == null:
		return

	if item_data == null:
		sprite.texture = null
		return

	sprite.texture = item_data.world_texture


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if pickup_id.is_empty():
		warnings.append(
			"ItemPickup requires a unique pickup ID."
		)

	if item_data == null:
		warnings.append(
			"ItemPickup requires an ItemData resource."
		)
	elif item_data.id.is_empty():
		warnings.append(
			"ItemPickup's ItemData requires a non-empty ID."
		)
	elif item_data.world_texture == null:
		warnings.append(
			"ItemPickup's ItemData has no world texture."
		)

	return warnings


func set_collected(collected: bool) -> void:
	is_collected = collected
	visible = not is_collected

	set_deferred(
		"monitoring",
		not is_collected
	)
```

### 3.17 `scripts/interactables/stair.gd`

```gdscript
@tool
class_name Stair
extends Area2D

enum Direction {
	UP,
	DOWN,
}

@export_group("Appearance")
@export var direction: Direction = Direction.UP:
	set(value):
		direction = value
		_update_visual()

@export_group("Destination")
@export var target_floor_id: StringName = &""
@export var target_spawn_id: StringName = &""

var transition_requested: bool = false


func _ready() -> void:
	_update_visual()


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	var player := body as Player

	if player == null:
		return

	if transition_requested:
		return

	if not player.is_moving:
		return

	if target_floor_id == &"":
		push_error("Stair requires a target floor ID.")
		return

	if target_spawn_id == &"":
		push_error("Stair requires a target spawn ID.")
		return

	transition_requested = true

	if player.is_moving:
		await player.movement_finished

	if not is_instance_valid(player):
		transition_requested = false
		return

	EventBus.floor_change_requested.emit(
		target_floor_id,
		target_spawn_id
	)

	transition_requested = false


func _update_visual() -> void:
	var animated_sprite := get_node_or_null(
		"AnimatedSprite2D"
	) as AnimatedSprite2D

	if animated_sprite == null:
		return

	if direction == Direction.UP:
		animated_sprite.animation = &"up"
	else:
		animated_sprite.animation = &"down"

	animated_sprite.frame = 0
```

### 3.18 `scripts/interactables/switch.gd`

```gdscript
class_name FloorSwitch
extends Area2D

signal state_changed(
	switch_id: StringName,
	is_active: bool
)

@export_group("Identity")
@export var switch_id: StringName = &""

@export_group("State")
@export var is_active: bool = false

@onready var animated_sprite: AnimatedSprite2D = (
	$AnimatedSprite2D
)


func _ready() -> void:
	_update_visual()


func interact(_player: Node) -> void:
	set_active(not is_active)


func set_active(active: bool) -> void:
	if is_active == active:
		return

	is_active = active
	_update_visual()
	state_changed.emit(switch_id, is_active)


func _update_visual() -> void:
	if is_active:
		animated_sprite.play(&"active")
	else:
		animated_sprite.play(&"inactive")
```

### 4.19 `scripts/inventory/equipment_loadout.gd`

```gdscript
class_name EquipmentLoadout
extends Node

signal equipment_changed
signal item_equipped(
	slot: int,
	item: EquipmentData
)
signal item_unequipped(
	slot: int,
	item: EquipmentData
)

enum Slot {
	HEAD,
	CHEST,
	HANDS,
	LEGS,
	FEET,
	LEFT_HAND,
	RIGHT_HAND,
	ACCESSORY_1,
	ACCESSORY_2,
}

var _equipped: Dictionary[int, EquipmentData] = {}


func can_equip(
	item: EquipmentData,
	target_slot: int
) -> bool:
	if item == null:
		return false

	match item.slot_type:
		EquipmentData.EquipmentSlotType.HEAD:
			return target_slot == Slot.HEAD

		EquipmentData.EquipmentSlotType.CHEST:
			return target_slot == Slot.CHEST

		EquipmentData.EquipmentSlotType.HANDS:
			return target_slot == Slot.HANDS

		EquipmentData.EquipmentSlotType.LEGS:
			return target_slot == Slot.LEGS

		EquipmentData.EquipmentSlotType.FEET:
			return target_slot == Slot.FEET

		EquipmentData.EquipmentSlotType.ACCESSORY:
			return (
				target_slot == Slot.ACCESSORY_1
				or target_slot == Slot.ACCESSORY_2
			)

		EquipmentData.EquipmentSlotType.HAND:
			return _can_equip_in_hand(
				item,
				target_slot
			)

	return false


func equip(
	item: EquipmentData,
	target_slot: int
) -> Array[EquipmentData]:
	var displaced_items: Array[EquipmentData] = []

	if not can_equip(item, target_slot):
		return displaced_items

	displaced_items = get_displaced_items(
		item,
		target_slot
	)

	for displaced_item: EquipmentData in displaced_items:
		_remove_equipped_item(displaced_item)

	if (
		item.slot_type == EquipmentData.EquipmentSlotType.HAND
		and item.hand_rule == EquipmentData.HandRule.TWO_HANDED
	):
		_equipped[Slot.LEFT_HAND] = item
		_equipped[Slot.RIGHT_HAND] = item
	else:
		_equipped[target_slot] = item

	for displaced_item: EquipmentData in displaced_items:
		item_unequipped.emit(
			target_slot,
			displaced_item
		)

	item_equipped.emit(target_slot, item)
	equipment_changed.emit()

	return displaced_items


func unequip(slot: int) -> EquipmentData:
	var item := get_equipped(slot)

	if item == null:
		return null

	_remove_equipped_item(item)

	item_unequipped.emit(slot, item)
	equipment_changed.emit()

	return item


func get_equipped(slot: int) -> EquipmentData:
	return _equipped.get(slot)


func get_unique_equipped_items() -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []

	for item: EquipmentData in _equipped.values():
		if not result.has(item):
			result.append(item)

	return result


func _can_equip_in_hand(
	item: EquipmentData,
	target_slot: int
) -> bool:
	match item.hand_rule:
		EquipmentData.HandRule.LEFT_ONLY:
			return target_slot == Slot.LEFT_HAND

		EquipmentData.HandRule.RIGHT_ONLY:
			return target_slot == Slot.RIGHT_HAND

		EquipmentData.HandRule.EITHER_HAND:
			return (
				target_slot == Slot.LEFT_HAND
				or target_slot == Slot.RIGHT_HAND
			)

		EquipmentData.HandRule.TWO_HANDED:
			return (
				target_slot == Slot.LEFT_HAND
				or target_slot == Slot.RIGHT_HAND
			)

	return false


func _collect_displaced_items(
	item: EquipmentData,
	target_slot: int
) -> Array[EquipmentData]:
	var result: Array[EquipmentData] = []
	var affected_slots: Array[int] = [target_slot]

	if (
		item.slot_type
		== EquipmentData.EquipmentSlotType.HAND
		and item.hand_rule
		== EquipmentData.HandRule.TWO_HANDED
	):
		affected_slots = [
			Slot.LEFT_HAND,
			Slot.RIGHT_HAND,
		]

	for slot: int in affected_slots:
		var equipped_item := get_equipped(slot)

		if (
			equipped_item != null
			and not result.has(equipped_item)
		):
			result.append(equipped_item)

	return result


func _remove_equipped_item(
	item: EquipmentData
) -> void:
	var slots_to_clear: Array[int] = []

	for slot: int in _equipped.keys():
		if _equipped[slot] == item:
			slots_to_clear.append(slot)

	for slot: int in slots_to_clear:
		_equipped.erase(slot)


func get_max_hp_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.max_hp_bonus

	return total


func get_max_mp_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.max_mp_bonus

	return total


func get_atk_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.atk_bonus

	return total


func get_def_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.def_bonus

	return total


func get_spd_bonus() -> float:
	var total: float = 0.0

	for item: EquipmentData in (
		get_unique_equipped_items()
	):
		total += item.spd_bonus

	return total


func get_displaced_items(
	item: EquipmentData,
	target_slot: int
) -> Array[EquipmentData]:
	if not can_equip(item, target_slot):
		return []

	return _collect_displaced_items(
		item,
		target_slot
	)
```

### 4.20 `scripts/inventory/inventory.gd`

```gdscript
class_name Inventory
extends Node

signal inventory_changed
signal item_added(item: ItemData, amount: int)
signal item_removed(item: ItemData, amount: int)

var _items: Dictionary[StringName, ItemData] = {}
var _quantities: Dictionary[StringName, int] = {}


func add_item(item: ItemData, amount: int = 1) -> int:
	if item == null or item.id.is_empty() or amount <= 0:
		return amount

	var current_amount := get_quantity(item.id)
	var accepted_amount := mini(
		amount,
		item.max_stack - current_amount
	)

	if accepted_amount <= 0:
		return amount

	_items[item.id] = item
	_quantities[item.id] = current_amount + accepted_amount

	item_added.emit(item, accepted_amount)
	inventory_changed.emit()

	return amount - accepted_amount


func remove_item(
	item_id: StringName,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	var current_amount := get_quantity(item_id)

	if current_amount < amount:
		return false

	var remaining_amount := current_amount - amount
	var item: ItemData = _items[item_id]

	if remaining_amount == 0:
		_items.erase(item_id)
		_quantities.erase(item_id)
	else:
		_quantities[item_id] = remaining_amount

	item_removed.emit(item, amount)
	inventory_changed.emit()

	return true


func has_item(
	item_id: StringName,
	amount: int = 1
) -> bool:
	return get_quantity(item_id) >= amount


func get_quantity(item_id: StringName) -> int:
	return _quantities.get(item_id, 0)


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id)


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []

	for item: ItemData in _items.values():
		result.append(item)

	return result


func get_remaining_capacity(
	item: ItemData
) -> int:
	if item == null or item.id.is_empty():
		return 0

	return maxi(
		0,
		item.max_stack
		- get_quantity(item.id)
	)
```

### 2.21 `scripts/main.gd`

```gdscript
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
```

### 7.22 `scripts/progression/level_up_manager.gd`

```gdscript
class_name LevelUpManager
extends Node

var _player: Player
var _level_up_ui: LevelUpUI


func setup(player: Player, level_up_ui: LevelUpUI) -> void:
	_player = player
	_level_up_ui = level_up_ui
	player.level_up_available.connect(_on_level_up_available)
	level_up_ui.stat_selected.connect(_on_stat_selected)
	level_up_ui.close_requested.connect(_on_close_requested)


func is_active() -> bool:
	return _level_up_ui != null and _level_up_ui.level_root.visible


func _on_level_up_available() -> void:
	_player.set_input_enabled(false)
	_level_up_ui.open(_player)


func _on_stat_selected(stat_id: StringName) -> void:
	if _player.spend_stat_point(stat_id):
		_level_up_ui.refresh()


func _on_close_requested() -> void:
	if _player.unspent_stat_points > 0:
		return
	_level_up_ui.close()
	_player.set_input_enabled(true)
```

### 7.23 `scripts/progression/level_up_ui.gd`

```gdscript
class_name LevelUpUI
extends CanvasLayer

signal stat_selected(stat_id: StringName)
signal close_requested

@onready var level_root: Control = $LevelRoot
@onready var stats_panel: ActorStatsPanel = $LevelRoot/Backdrop/Center/Panel/Margin/Content/StatsPanel
@onready var points_label: Label = $LevelRoot/Backdrop/Center/Panel/Margin/Content/PointsLabel
@onready var close_button: Button = $LevelRoot/Backdrop/Center/Panel/Margin/Content/CloseButton

var _player: Player


func _ready() -> void:
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/MaxHp.pressed.connect(stat_selected.emit.bind(&"max_hp"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/MaxMp.pressed.connect(stat_selected.emit.bind(&"max_mp"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/Atk.pressed.connect(stat_selected.emit.bind(&"atk"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/Def.pressed.connect(stat_selected.emit.bind(&"def"))
	$LevelRoot/Backdrop/Center/Panel/Margin/Content/Buttons/Spd.pressed.connect(stat_selected.emit.bind(&"spd"))
	close_button.pressed.connect(close_requested.emit)


func open(player: Player) -> void:
	_player = player
	level_root.visible = true
	refresh()


func close() -> void:
	level_root.visible = false
	_player = null


func refresh() -> void:
	if _player == null:
		return
	points_label.text = "等级 %d    剩余属性点：%d" % [_player.level, _player.unspent_stat_points]
	var view := ActorStatsViewData.new()
	view.display_name = _player.player_data.display_name
	view.portrait = _player.player_data.portrait
	view.current_hp = _player.current_hp
	view.max_hp = _player.get_max_hp()
	view.current_mp = _player.current_mp
	view.max_mp = _player.get_max_mp()
	view.atk = _player.get_atk()
	view.def = _player.get_def()
	view.spd = _player.get_spd()
	stats_panel.display_stats(view)
	close_button.disabled = _player.unspent_stat_points > 0
```

### 5.24 `scripts/ui/components/actor_stats_panel.gd`

```gdscript
class_name ActorStatsPanel
extends PanelContainer

@onready var portrait: TextureRect = %Portrait
@onready var name_label: Label = %NameLabel
@onready var hp_value: Label = %HpValue
@onready var mp_value: Label = %MpValue
@onready var atk_value: Label = %AtkValue
@onready var def_value: Label = %DefValue
@onready var spd_value: Label = %SpdValue


func display_stats(
	view_data: ActorStatsViewData
) -> void:
	if view_data == null:
		clear_stats()
		return

	portrait.texture = view_data.portrait
	portrait.visible = view_data.portrait != null

	name_label.text = view_data.display_name

	hp_value.text = "%d / %s" % [
		roundi(view_data.current_hp),
		_format_stat(
			view_data.max_hp,
			view_data.max_hp_delta
		),
	]

	mp_value.text = "%d / %s" % [
		roundi(view_data.current_mp),
		_format_stat(
			view_data.max_mp,
			view_data.max_mp_delta
		),
	]

	atk_value.text = _format_stat(
		view_data.atk,
		view_data.atk_delta
	)
	def_value.text = _format_stat(
		view_data.def,
		view_data.def_delta
	)
	spd_value.text = _format_stat(
		view_data.spd,
		view_data.spd_delta
	)


func clear_stats() -> void:
	portrait.texture = null
	portrait.visible = false

	name_label.text = ""
	hp_value.text = ""
	mp_value.text = ""
	atk_value.text = ""
	def_value.text = ""
	spd_value.text = ""


func _format_stat(
	value: float,
	delta: float
) -> String:
	var rounded_value: int = roundi(value)
	var rounded_delta: int = roundi(delta)

	if rounded_delta == 0:
		return str(rounded_value)

	var sign_text: String = ""

	if rounded_delta > 0:
		sign_text = "+"

	return "%d (%s%d)" % [
		rounded_value,
		sign_text,
		rounded_delta,
	]
```

### 5.25 `scripts/ui/components/actor_stats_view_data.gd`

```gdscript
class_name ActorStatsViewData
extends RefCounted

var display_name: String = ""
var portrait: Texture2D

var current_hp: float = 0.0
var max_hp: float = 0.0
var current_mp: float = 0.0
var max_mp: float = 0.0

var atk: float = 0.0
var def: float = 0.0
var spd: float = 0.0

var max_hp_delta: float = 0.0
var max_mp_delta: float = 0.0
var atk_delta: float = 0.0
var def_delta: float = 0.0
var spd_delta: float = 0.0
```

### 5.26 `scripts/ui/components/entry_info_panel.gd`

```gdscript
class_name EntryInfoPanel
extends PanelContainer

@onready var icon_rect: TextureRect = %Icon
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var details_separator: HSeparator = %DetailsSeparator
@onready var details_label: RichTextLabel = %DetailsLabel


func display_info(
	view_data: EntryInfoViewData
) -> void:
	if view_data == null:
		clear_info()
		return

	title_label.text = view_data.title
	description_label.text = view_data.description

	icon_rect.texture = view_data.icon
	icon_rect.visible = view_data.icon != null

	var has_details := not view_data.detail_lines.is_empty()

	details_separator.visible = has_details
	details_label.visible = has_details
	details_label.text = "\n".join(
		view_data.detail_lines
	)


func clear_info() -> void:
	title_label.text = ""
	description_label.text = ""

	icon_rect.texture = null
	icon_rect.visible = false

	details_label.text = ""
	details_label.visible = false
	details_separator.visible = false
```

### 5.27 `scripts/ui/components/entry_info_view_data.gd`

```gdscript
class_name EntryInfoViewData
extends RefCounted

var title: String = ""
var icon: Texture2D
var description: String = ""
var detail_lines: Array[String] = []
```

### 5.28 `scripts/ui/components/game_message_panel.gd`

```gdscript
class_name GameMessagePanel
extends PanelContainer

@onready var message_label: Label = %MessageLabel


func show_message(message: String) -> void:
	message_label.text = message
	visible = not message.is_empty()


func clear_message() -> void:
	message_label.text = ""
	visible = false
```

### 5.29 `scripts/ui/components/inventory_panel.gd`

```gdscript
class_name InventoryPanel
extends PanelContainer

signal item_selected(item: ItemData)

@export var row_scene: PackedScene

@onready var item_rows: VBoxContainer = (
	$MarginContainer/Content/ItemScroll/ItemRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _inventory: Inventory


func bind_inventory(inventory: Inventory) -> void:
	if _inventory != null:
		if _inventory.inventory_changed.is_connected(refresh):
			_inventory.inventory_changed.disconnect(refresh)

	_inventory = inventory

	if _inventory != null:
		_inventory.inventory_changed.connect(refresh)

	refresh()


func refresh() -> void:
	for child: Node in item_rows.get_children():
		item_rows.remove_child(child)
		child.queue_free()

	if _inventory == null:
		empty_label.visible = true
		return

	var items: Array[ItemData] = _inventory.get_all_items()
	items.sort_custom(_sort_items)

	empty_label.visible = items.is_empty()

	for item: ItemData in items:
		var row: SelectableListRow = (
			row_scene.instantiate()
			as SelectableListRow
		)

		if row == null:
			push_error("InventoryPanel row_scene has an invalid root.")
			return

		item_rows.add_child(row)
		row.setup(
			item,
			"%s  ×%d" % [
				item.display_name,
				_inventory.get_quantity(item.id),
			],
			item.icon,
			item.description
		)
		row.entry_selected.connect(_on_entry_selected)


func _sort_items(
	left: ItemData,
	right: ItemData
) -> bool:
	return left.display_name < right.display_name


func _on_entry_selected(entry: Resource) -> void:
	var item: ItemData = entry as ItemData

	if item != null:
		item_selected.emit(item)
```

### 5.30 `scripts/ui/components/player_stat_hud.gd`

```gdscript
class_name PlayerStatHUD
extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var hp_value: Label = %HpValue
@onready var hp_bar: ProgressBar = %HpBar
@onready var mp_value: Label = %MpValue
@onready var mp_bar: ProgressBar = %MpBar


func display_stats(
	view_data: ActorStatsViewData
) -> void:
	if view_data == null:
		clear_stats()
		return

	name_label.text = view_data.display_name

	_set_bar(
		hp_bar,
		hp_value,
		view_data.current_hp,
		view_data.max_hp
	)

	_set_bar(
		mp_bar,
		mp_value,
		view_data.current_mp,
		view_data.max_mp
	)


func clear_stats() -> void:
	name_label.text = ""

	_set_bar(hp_bar, hp_value, 0, 1)
	_set_bar(mp_bar, mp_value, 0, 1)


func _set_bar(
	bar: ProgressBar,
	value_label: Label,
	current_value: float,
	maximum_value: float
) -> void:
	var safe_maximum := maxf(
		maximum_value,
		1.0
	)

	var displayed_value := clampf(
		current_value,
		0.0,
		safe_maximum
	)

	bar.max_value = safe_maximum
	bar.value = displayed_value

	value_label.text = "%d / %d" % [
		roundi(displayed_value),
		roundi(safe_maximum),
	]
```

### 5.31 `scripts/ui/components/selectable_list_row.gd`

```gdscript
class_name SelectableListRow
extends Button

signal entry_selected(entry: Resource)

var entry_data: Resource


func setup(
	entry: Resource,
	entry_text: String,
	entry_icon: Texture2D,
	entry_tooltip: String
) -> void:
	entry_data = entry

	if entry_data == null:
		text = ""
		icon = null
		tooltip_text = ""
		disabled = true
		return

	text = entry_text
	icon = entry_icon
	tooltip_text = entry_tooltip
	disabled = false


func _pressed() -> void:
	if entry_data != null:
		entry_selected.emit(entry_data)
```

### 5.32 `scripts/ui/components/skill_panel.gd`

```gdscript
class_name SkillPanel
extends PanelContainer

signal skill_selected(skill: SkillData)

@export var row_scene: PackedScene

@onready var skill_rows: VBoxContainer = (
	$MarginContainer/Content/SkillScroll/SkillRows
)
@onready var empty_label: Label = (
	$MarginContainer/Content/EmptyLabel
)

var _skills: Array[SkillData] = []


func display_skills(
	skills: Array[SkillData]
) -> void:
	_skills = skills.duplicate()
	refresh()


func clear_skills() -> void:
	_skills.clear()
	refresh()


func refresh() -> void:
	for child: Node in skill_rows.get_children():
		skill_rows.remove_child(child)
		child.queue_free()

	_skills.sort_custom(_sort_skills)
	empty_label.visible = _skills.is_empty()

	for skill: SkillData in _skills:
		var row: SelectableListRow = (
			row_scene.instantiate()
			as SelectableListRow
		)

		if row == null:
			push_error(
				"SkillPanel row_scene has an invalid root."
			)
			return

		skill_rows.add_child(row)
		row.setup(
			skill,
			_build_row_text(skill),
			skill.icon,
			skill.description
		)
		row.entry_selected.connect(
			_on_entry_selected
		)


func _build_row_text(skill: SkillData) -> String:
	var details: Array[String] = []

	if skill.mp_cost > 0.0:
		details.append(
			"MP %.0f" % skill.mp_cost
		)

	if skill.cooldown_seconds > 0.0:
		details.append(
			"%.1fs" % skill.cooldown_seconds
		)

	if details.is_empty():
		return skill.display_name

	return "%s  %s" % [
		skill.display_name,
		" / ".join(details),
	]


func _sort_skills(
	left: SkillData,
	right: SkillData
) -> bool:
	if left.unlock_level == right.unlock_level:
		return left.display_name < right.display_name

	return left.unlock_level < right.unlock_level


func _on_entry_selected(entry: Resource) -> void:
	var skill: SkillData = entry as SkillData

	if skill != null:
		skill_selected.emit(skill)
```

### 5.33 `scripts/ui/components/tracked_inventory_hud.gd`

```gdscript
class_name TrackedInventoryHUD
extends PanelContainer

@onready var item_rows: VBoxContainer = %ItemRows

var _inventory: Inventory


func bind_inventory(
	inventory: Inventory
) -> void:
	_inventory = inventory

	for child: Node in item_rows.get_children():
		var row: TrackedItemRow = (
			child as TrackedItemRow
		)

		if row != null:
			row.bind_inventory(_inventory)
```

### 5.34 `scripts/ui/components/tracked_item_row.gd`

```gdscript
class_name TrackedItemRow
extends HBoxContainer

@export var item: ItemData

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var quantity_label: Label = %QuantityLabel

var _inventory: Inventory


func _ready() -> void:
	refresh()


func bind_inventory(
	inventory: Inventory
) -> void:
	if _inventory != null:
		if _inventory.inventory_changed.is_connected(
			refresh
		):
			_inventory.inventory_changed.disconnect(
				refresh
			)

	_inventory = inventory

	if _inventory != null:
		_inventory.inventory_changed.connect(refresh)

	refresh()


func refresh() -> void:
	if item == null:
		visible = false
		return

	visible = true

	icon_rect.texture = item.icon
	name_label.text = item.display_name

	var quantity: int = 0

	if _inventory != null:
		quantity = _inventory.get_quantity(item.id)

	quantity_label.text = "×%d" % quantity
```

### 6.35 `scripts/ui/esc_menu.gd`

```gdscript
class_name EscMenu
extends CanvasLayer

signal opened
signal closed

@onready var inventory_panel: InventoryPanel = (
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Columns/InventoryPanel
)
@onready var skill_panel: SkillPanel = (
	$MenuRoot/Backdrop/MenuCenter/MenuPanel/MarginContainer/Content/Columns/SkillPanel
)
@onready var menu_root: Control = $MenuRoot

var _player: Player


func bind_player(player: Player) -> void:
	_player = player
	refresh_content()


func refresh_content() -> void:
	if _player == null:
		inventory_panel.bind_inventory(null)
		skill_panel.clear_skills()
		return

	inventory_panel.bind_inventory(_player.inventory)
	skill_panel.display_skills(_player.learned_skills)


func open() -> void:
	if menu_root.visible:
		return

	refresh_content()
	menu_root.visible = true

	if _player != null:
		_player.set_input_enabled(false)

	opened.emit()


func close() -> void:
	if not menu_root.visible:
		return

	menu_root.visible = false

	if _player != null:
		_player.set_input_enabled(true)

	closed.emit()


func toggle() -> void:
	if menu_root.visible:
		close()
		return

	open()


func is_open() -> bool:
	return menu_root.visible
```

### 6.36 `scripts/ui/game_hud.gd`

```gdscript
class_name GameHUD
extends CanvasLayer


@onready var player_stat_hud: PlayerStatHUD = (
	$HudRoot/PlayerStatHUD
)
@onready var tracked_inventory_hud: TrackedInventoryHUD = (
	$HudRoot/TrackedInventoryHUD
)
@onready var game_message_panel: GameMessagePanel = (
	$HudRoot/MessageArea/GameMessagePanel
)

var _player: Player


func bind_player(player: Player) -> void:
	if (
		_player != null
		and _player.stats_changed.is_connected(
			refresh_player_stats
		)
	):
		_player.stats_changed.disconnect(
			refresh_player_stats
		)

	_player = player

	if _player == null:
		player_stat_hud.clear_stats()
		tracked_inventory_hud.bind_inventory(null)
		return

	_player.stats_changed.connect(
		refresh_player_stats
	)

	tracked_inventory_hud.bind_inventory(
		_player.inventory
	)
	refresh_player_stats()


func refresh_player_stats() -> void:
	if _player == null or _player.player_data == null:
		player_stat_hud.clear_stats()
		return

	var view_data: ActorStatsViewData = ActorStatsViewData.new()

	view_data.display_name = _player.player_data.display_name
	view_data.portrait = _player.player_data.portrait

	view_data.current_hp = _player.current_hp
	view_data.max_hp = _player.get_max_hp()
	view_data.current_mp = _player.current_mp
	view_data.max_mp = _player.get_max_mp()

	player_stat_hud.display_stats(view_data)


func show_message(message: String) -> void:
	game_message_panel.show_message(message)


func clear_message() -> void:
	game_message_panel.clear_message()
```


