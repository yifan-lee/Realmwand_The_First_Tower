# GDScript 职责与调用关系

本文与当前工程同步，重点说明运行时入口、键盘输入、信号流、公式入口和可复用 UI。完整源码见 [development_steps.md](development_steps.md#全部-gdscript-完整源码与当前工程同步)。

## 目录

- [总调用关系](#总调用关系)
- [main.gd 详细说明](#maingd-详细说明)
- [关键运行链](#关键运行链)
- [共享公式入口](#共享公式入口)
- [全部脚本索引](#全部脚本索引)
- [`actors/enemy.gd`](#script-scripts-actors-enemy-gd)
- [`actors/player.gd`](#script-scripts-actors-player-gd)
- [`autoload/event_bus.gd`](#script-scripts-autoload-event-bus-gd)
- [`battle/battle_manager.gd`](#script-scripts-battle-battle-manager-gd)
- [`battle/battle_ui.gd`](#script-scripts-battle-battle-ui-gd)
- [`data/actor_data.gd`](#script-scripts-data-actor-data-gd)
- [`data/enemy_data.gd`](#script-scripts-data-enemy-data-gd)
- [`data/equipment_data.gd`](#script-scripts-data-equipment-data-gd)
- [`data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`data/player_data.gd`](#script-scripts-data-player-data-gd)
- [`data/skill_data.gd`](#script-scripts-data-skill-data-gd)
- [`data/skill_effect_data.gd`](#script-scripts-data-skill-effect-data-gd)
- [`floors/floor.gd`](#script-scripts-floors-floor-gd)
- [`floors/floor_1.gd`](#script-scripts-floors-floor-1-gd)
- [`floors/floor_manager.gd`](#script-scripts-floors-floor-manager-gd)
- [`interactables/item_pickup.gd`](#script-scripts-interactables-item-pickup-gd)
- [`interactables/stair.gd`](#script-scripts-interactables-stair-gd)
- [`interactables/switch.gd`](#script-scripts-interactables-switch-gd)
- [`inventory/equipment_loadout.gd`](#script-scripts-inventory-equipment-loadout-gd)
- [`inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)
- [`main.gd`](#script-scripts-main-gd)
- [`progression/level_up_manager.gd`](#script-scripts-progression-level-up-manager-gd)
- [`progression/level_up_ui.gd`](#script-scripts-progression-level-up-ui-gd)
- [`shared/game_formulas.gd`](#script-scripts-shared-game-formulas-gd)
- [`ui/components/actor_stats_panel.gd`](#script-scripts-ui-components-actor-stats-panel-gd)
- [`ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)
- [`ui/components/entry_info_panel.gd`](#script-scripts-ui-components-entry-info-panel-gd)
- [`ui/components/entry_info_view_data.gd`](#script-scripts-ui-components-entry-info-view-data-gd)
- [`ui/components/equipment_panel.gd`](#script-scripts-ui-components-equipment-panel-gd)
- [`ui/components/game_message_panel.gd`](#script-scripts-ui-components-game-message-panel-gd)
- [`ui/components/inventory_panel.gd`](#script-scripts-ui-components-inventory-panel-gd)
- [`ui/components/player_stat_hud.gd`](#script-scripts-ui-components-player-stat-hud-gd)
- [`ui/components/selectable_list_row.gd`](#script-scripts-ui-components-selectable-list-row-gd)
- [`ui/components/skill_panel.gd`](#script-scripts-ui-components-skill-panel-gd)
- [`ui/components/tracked_inventory_hud.gd`](#script-scripts-ui-components-tracked-inventory-hud-gd)
- [`ui/components/tracked_item_row.gd`](#script-scripts-ui-components-tracked-item-row-gd)
- [`ui/esc_menu.gd`](#script-scripts-ui-esc-menu-gd)
- [`ui/game_hud.gd`](#script-scripts-ui-game-hud-gd)

## 总调用关系

```text
main.gd
├─ FloorManager ──加载/切换──> Floor / Floor_n
├─ Player ──撞入敌人格──> Enemy.request_battle()
│                         └─ EventBus.battle_requested
├─ BattleManager <────────────┘
│  ├─ GameFormulas：ATB、伤害、持续效果、奖励
│  └─ BattleUI
│     ├─ ActorStatsPanel × 2
│     ├─ SkillPanel / InventoryPanel
│     └─ EntryInfoPanel
├─ EscMenu
│  ├─ ActorStatsPanel / EquipmentPanel
│  ├─ InventoryPanel / SkillPanel
│  ├─ EntryInfoPanel
│  └─ GameFormulas：装备、恢复、技能预览
└─ LevelUpManager ──> LevelUpUI
```

## main.gd 详细说明

源码：[main.gd](../scripts/main.gd)。

### 变量

| 变量 | 节点 | 作用 |
|---|---|---|
| `player` | `World/Player` | 唯一玩家运行实例 |
| `game_hud` | `OverlayRoot/GameHUD` | 常驻属性、跟踪物品和独立消息 |
| `esc_menu` | `OverlayRoot/EscMenu` | 键盘优先暂停菜单 |
| `battle_ui` | `OverlayRoot/BattleUI` | 战斗表现和选择输入 |
| `level_up_ui` | `OverlayRoot/LevelUpUI` | 升级加点界面 |
| `battle_manager` | `Systems/BattleManager` | ATB 状态和战斗规则协调 |
| `level_up_manager` | `Systems/LevelUpManager` | 升级流程协调 |

### _ready()

`_ready()` 只组装依赖：

1. 将同一个 [Player](#script-scripts-actors-player-gd) 绑定到 [GameHUD](#script-scripts-ui-game-hud-gd) 与 [EscMenu](#script-scripts-ui-esc-menu-gd)。
2. 调用 [BattleManager.setup()](#script-scripts-battle-battle-manager-gd)，传入玩家和 BattleUI。
3. 调用 [LevelUpManager.setup()](#script-scripts-progression-level-up-manager-gd)，传入玩家和升级 UI。
4. 监听 `battle_finished(victory)`，结束后让 HUD 显示结果消息。

`main.gd` 自身不发射业务信号；它接收 `BattleManager.battle_finished`。战斗请求由 [EventBus](#script-scripts-autoload-event-bus-gd) 转交，不经过 Main。

### 输入

`_unhandled_input()` 只接收 `toggle_menu`：

- 战斗或升级进行中：吞掉输入，不打开 ESC。
- 其他时候：调用 `EscMenu.toggle()`。
- 方向键、确认、取消由获得焦点的 UI 组件和各 UI 控制器处理。

### 场景侧说明

`main.tscn` 保存 World、Systems、OverlayRoot 三个职责区及其实例关系；`main.gd` 不在运行时创建可视节点。

## 关键运行链

### 遭遇与 ATB

1. [Player](#script-scripts-actors-player-gd) 尝试进入目标格，射线发现 Enemy。
2. Player 调用 [Enemy.request_battle()](#script-scripts-actors-enemy-gd)，Enemy 发出 `EventBus.battle_requested(enemy, player)`。
3. [BattleManager](#script-scripts-battle-battle-manager-gd) 打开 [BattleUI](#script-scripts-battle-battle-ui-gd) 并禁用地图输入。
4. `RUNNING` 状态推进 ATB、冷却和持续效果。
5. 玩家 ATB 满后切到 `WAITING_FOR_PLAYER`；`_process()` 立即停止推进，敌人 ATB 保持不变。
6. BattleUI 自动聚焦第一个技能。上下选择，左右切页，确认发出 `skill_selected`、`item_selected` 或 `escape_requested`。
7. Manager 调用 [GameFormulas](#script-scripts-shared-game-formulas-gd) 结算，再回到 `RUNNING`。

### 战斗预览

[BattleUI](#script-scripts-battle-battle-ui-gd) 收到列表的 `skill_focused` / `item_focused`，构造两份 `ActorStatsViewData`，将预计 HP/MP/属性差写入 delta 字段，再交给共享 [ActorStatsPanel](#script-scripts-ui-components-actor-stats-panel-gd) 显示。

### ESC 菜单

1. Main 调用 [EscMenu.toggle()](#script-scripts-ui-esc-menu-gd)；菜单打开并禁用地图输入。
2. 初始焦点是背包顶层页签。左右切换背包/技能/系统，上下进入内容。
3. 背包内左右切换装备/消耗品/材料/其他，上下选择条目。
4. 聚焦装备时，`GameFormulas.equipment_delta()` 计算候选装备减去被替换装备后的净变化；[EquipmentPanel](#script-scripts-ui-components-equipment-panel-gd) 高亮受影响槽位。
5. 确认键装备、使用物品或卸下当前装备；列表和属性面板刷新。

### 换层

[Stair](#script-scripts-interactables-stair-gd) 的 Area2D 检测玩家进入后，请求 [FloorManager](#script-scripts-floors-floor-manager-gd) 切换目标楼层和出生点。FloorManager 保存当前 Floor 状态，实例化新楼层，再把 Player 放到目标 Marker2D。

## 共享公式入口

所有可修改数值规则集中在 [`scripts/shared/game_formulas.gd`](../scripts/shared/game_formulas.gd)：

| 函数/常量 | 用途 |
|---|---|
| `ATB_MAX`、`calculate_atb_gain()` | ATB 上限与速度 |
| `MIN_DAMAGE`、`calculate_skill_damage()` | 最低伤害与攻防公式 |
| `calculate_recovery_delta()` | HP/MP 回复预览 |
| `skill_effect_delta()`、`calculate_effective_stat()` | 技能效果预览与运行时属性 |
| `equipment_delta()` | 更换装备的净属性差 |
| `experience_for_next_level()`、`default_enemy_experience()`、`stat_point_increase()` | 经验、奖励和升级点数 |

这里使用纯静态函数，不需要 `battle_rules.tres` 或 `progression_rules.tres`。角色、敌人、技能、物品的内容数据仍然保留为 `.tres`。

## 全部脚本索引

<a id="script-scripts-actors-enemy-gd"></a>
### `scripts/actors/enemy.gd`

- 继承：`StaticBody2D`；类名：`Enemy`。
- 信号：`battle_requested(`、`stats_changed`
- 主要函数：`_ready()`、`interact()`、`request_battle()`、`take_damage()`、`change_mp()`、`set_defeated()`、`_get_configuration_warnings()`、`_refresh_visual()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：各个 `scenes/actors/enemy/enemy_n.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-actors-player-gd"></a>
### `scripts/actors/player.gd`

- 继承：`CharacterBody2D`；类名：`Player`。
- 信号：`movement_finished`、`stats_changed`、`level_up_available`
- 主要函数：`_ready()`、`_unhandled_input()`、`_initialize_runtime_state()`、`_apply_data_visuals()`、`_set_facing_direction()`、`_update_interaction_ray()`、`_move_one_tile()`、`_play_directional_animation()`、`_get_direction_suffix()`、`_try_interact()`、`set_input_enabled()`、`set_current_hp()`、`change_hp()`、`set_current_mp()`、`change_mp()`、`get_experience_for_next_level()`、`add_experience()`、`spend_stat_point()`、`equip_item()`、`unequip_item()`、`get_max_hp()`、`get_max_mp()`、`get_atk()`、`get_def()`、`get_spd()`、`_on_equipment_changed()`
- 直接预载依赖：[`shared/game_formulas.gd`](#script-scripts-shared-game-formulas-gd)
- 场景侧：`scenes/actors/player.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-autoload-event-bus-gd"></a>
### `scripts/autoload/event_bus.gd`

- 继承：`Node`；类名：`无全局类名`。
- 信号：`floor_change_requested(`、`battle_requested(`
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-battle-battle-manager-gd"></a>
### `scripts/battle/battle_manager.gd`

- 继承：`Node`；类名：`BattleManager`。
- 信号：`battle_started(enemy: Enemy)`、`battle_finished(victory: bool)`
- 主要函数：`setup()`、`is_active()`、`is_waiting_for_player()`、`_process()`、`start_battle()`、`_on_battle_requested()`、`_on_skill_selected()`、`_on_item_selected()`、`_on_escape_requested()`、`_enemy_take_turn()`、`_complete_player_action()`、`_finish_battle()`、`_get_experience_reward()`、`_tick_cooldowns()`、`_apply_skill_effects()`、`_tick_effects()`、`_get_player_stat()`、`_get_enemy_stat()`
- 直接预载依赖：[`shared/game_formulas.gd`](#script-scripts-shared-game-formulas-gd)

<a id="script-scripts-battle-battle-ui-gd"></a>
### `scripts/battle/battle_ui.gd`

- 继承：`CanvasLayer`；类名：`BattleUI`。
- 信号：`skill_selected(skill: SkillData)`、`item_selected(item: ItemData)`、`escape_requested`
- 主要函数：`_ready()`、`_unhandled_input()`、`open()`、`close()`、`set_action_available()`、`set_atb()`、`show_message()`、`refresh_stats()`、`_show_action_page()`、`_cycle_action_page()`、`_focus_current_page()`、`_focus_current_tab()`、`_is_tab_focused()`、`_on_escape_tab_pressed()`、`_on_skill_focused()`、`_on_item_focused()`、`_apply_skill_effect_preview()`、`_build_player_view()`、`_build_enemy_view()`
- 直接预载依赖：[`shared/game_formulas.gd`](#script-scripts-shared-game-formulas-gd)
- 场景侧：`scenes/battle/battle_ui.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-data-actor-data-gd"></a>
### `scripts/data/actor_data.gd`

- 继承：`Resource`；类名：`ActorData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-data-enemy-data-gd"></a>
### `scripts/data/enemy_data.gd`

- 继承：`ActorData`；类名：`EnemyData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-data-equipment-data-gd"></a>
### `scripts/data/equipment_data.gd`

- 继承：`ItemData`；类名：`EquipmentData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-data-item-data-gd"></a>
### `scripts/data/item_data.gd`

- 继承：`Resource`；类名：`ItemData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-data-player-data-gd"></a>
### `scripts/data/player_data.gd`

- 继承：`ActorData`；类名：`PlayerData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-data-skill-data-gd"></a>
### `scripts/data/skill_data.gd`

- 继承：`Resource`；类名：`SkillData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-data-skill-effect-data-gd"></a>
### `scripts/data/skill_effect_data.gd`

- 继承：`Resource`；类名：`SkillEffectData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-floors-floor-gd"></a>
### `scripts/floors/floor.gd`

- 继承：`Node2D`；类名：`Floor`。
- 信号：无。
- 主要函数：`get_spawn_point()`、`capture_tile_cells()`、`set_tile_cells_removed()`、`capture_runtime_state()`、`apply_runtime_state()`、`_apply_switch_states()`、`_apply_pickup_states()`、`_apply_enemy_states()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：楼层场景的基类 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-floors-floor-1-gd"></a>
### `scripts/floors/floor_1.gd`

- 继承：`Floor`；类名：`无全局类名`。
- 信号：无。
- 主要函数：`_ready()`、`_create_switch_rules()`、`_cache_switch_terrain()`、`_apply_initial_switch_states()`、`_on_floor_switch_state_changed()`、`_apply_switch_state()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/floors/floor_1.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-floors-floor-manager-gd"></a>
### `scripts/floors/floor_manager.gd`

- 继承：`Node`；类名：`FloorManager`。
- 信号：无。
- 主要函数：`_ready()`、`change_floor()`、`_on_floor_change_requested()`、`_store_current_floor_state()`、`_apply_saved_floor_state()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-interactables-item-pickup-gd"></a>
### `scripts/interactables/item_pickup.gd`

- 继承：`Area2D`；类名：`ItemPickup`。
- 信号：`picked_up(item: ItemData, amount: int)`
- 主要函数：`_ready()`、`_on_body_entered()`、`_refresh_visual()`、`_get_configuration_warnings()`、`set_collected()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/interactables/item_pickup.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-interactables-stair-gd"></a>
### `scripts/interactables/stair.gd`

- 继承：`Area2D`；类名：`Stair`。
- 信号：无。
- 主要函数：`_ready()`、`_on_body_entered()`、`_update_visual()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/interactables/stair.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-interactables-switch-gd"></a>
### `scripts/interactables/switch.gd`

- 继承：`Area2D`；类名：`FloorSwitch`。
- 信号：`state_changed(`
- 主要函数：`_ready()`、`interact()`、`set_active()`、`_update_visual()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/interactables/switch.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-inventory-equipment-loadout-gd"></a>
### `scripts/inventory/equipment_loadout.gd`

- 继承：`Node`；类名：`EquipmentLoadout`。
- 信号：`equipment_changed`、`item_equipped(`、`item_unequipped(`
- 主要函数：`can_equip()`、`equip()`、`unequip()`、`get_equipped()`、`get_unique_equipped_items()`、`_can_equip_in_hand()`、`_collect_displaced_items()`、`_remove_equipped_item()`、`get_max_hp_bonus()`、`get_max_mp_bonus()`、`get_atk_bonus()`、`get_def_bonus()`、`get_spd_bonus()`、`get_displaced_items()`、`get_compatible_slots()`、`get_slots_for_item()`、`get_affected_slots()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-inventory-inventory-gd"></a>
### `scripts/inventory/inventory.gd`

- 继承：`Node`；类名：`Inventory`。
- 信号：`inventory_changed`、`item_added(item: ItemData, amount: int)`、`item_removed(item: ItemData, amount: int)`
- 主要函数：`add_item()`、`remove_item()`、`has_item()`、`get_quantity()`、`get_item()`、`get_all_items()`、`get_remaining_capacity()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-main-gd"></a>
### `scripts/main.gd`

- 继承：`Node2D`；类名：`无全局类名`。
- 信号：无。
- 主要函数：`_ready()`、`_unhandled_input()`、`_on_battle_finished()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/main.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-progression-level-up-manager-gd"></a>
### `scripts/progression/level_up_manager.gd`

- 继承：`Node`；类名：`LevelUpManager`。
- 信号：无。
- 主要函数：`setup()`、`is_active()`、`_on_level_up_available()`、`_on_stat_selected()`、`_on_close_requested()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-progression-level-up-ui-gd"></a>
### `scripts/progression/level_up_ui.gd`

- 继承：`CanvasLayer`；类名：`LevelUpUI`。
- 信号：`stat_selected(stat_id: StringName)`、`close_requested`
- 主要函数：`_ready()`、`open()`、`close()`、`refresh()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/level_up_ui.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-shared-game-formulas-gd"></a>
### `scripts/shared/game_formulas.gd`

- 继承：`RefCounted`；类名：`GameFormulas`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-components-actor-stats-panel-gd"></a>
### `scripts/ui/components/actor_stats_panel.gd`

- 继承：`PanelContainer`；类名：`ActorStatsPanel`。
- 信号：无。
- 主要函数：`display_stats()`、`clear_stats()`、`_format_stat()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/components/actor_stats_panel.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-components-actor-stats-view-data-gd"></a>
### `scripts/ui/components/actor_stats_view_data.gd`

- 继承：`RefCounted`；类名：`ActorStatsViewData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-components-entry-info-panel-gd"></a>
### `scripts/ui/components/entry_info_panel.gd`

- 继承：`PanelContainer`；类名：`EntryInfoPanel`。
- 信号：无。
- 主要函数：`display_info()`、`clear_info()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/components/entry_info_panel.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-components-entry-info-view-data-gd"></a>
### `scripts/ui/components/entry_info_view_data.gd`

- 继承：`RefCounted`；类名：`EntryInfoViewData`。
- 信号：无。
- 主要函数：无运行函数，仅保存数据。
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-components-equipment-panel-gd"></a>
### `scripts/ui/components/equipment_panel.gd`

- 继承：`PanelContainer`；类名：`EquipmentPanel`。
- 信号：`slot_focused(slot: int)`、`slot_selected(slot: int)`
- 主要函数：`_ready()`、`bind_loadout()`、`refresh()`、`preview_slots()`、`clear_preview()`、`focus_first_slot()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/components/equipment_panel.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-components-game-message-panel-gd"></a>
### `scripts/ui/components/game_message_panel.gd`

- 继承：`PanelContainer`；类名：`GameMessagePanel`。
- 信号：无。
- 主要函数：`show_message()`、`clear_message()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-components-inventory-panel-gd"></a>
### `scripts/ui/components/inventory_panel.gd`

- 继承：`PanelContainer`；类名：`InventoryPanel`。
- 信号：`item_selected(item: ItemData)`、`item_focused(item: ItemData)`
- 主要函数：`bind_inventory()`、`refresh()`、`set_item_type_filter()`、`clear_filter()`、`set_battle_only()`、`focus_first_item()`、`_matches_filter()`、`_sort_items()`、`_on_entry_selected()`、`_on_entry_focused()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/components/inventory_panel.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-components-player-stat-hud-gd"></a>
### `scripts/ui/components/player_stat_hud.gd`

- 继承：`PanelContainer`；类名：`PlayerStatHUD`。
- 信号：无。
- 主要函数：`display_stats()`、`clear_stats()`、`_set_bar()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-components-selectable-list-row-gd"></a>
### `scripts/ui/components/selectable_list_row.gd`

- 继承：`Button`；类名：`SelectableListRow`。
- 信号：`entry_selected(entry: Resource)`、`entry_focused(entry: Resource)`
- 主要函数：`_ready()`、`setup()`、`_pressed()`、`_emit_focused()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/components/selectable_list_row.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-components-skill-panel-gd"></a>
### `scripts/ui/components/skill_panel.gd`

- 继承：`PanelContainer`；类名：`SkillPanel`。
- 信号：`skill_selected(skill: SkillData)`、`skill_focused(skill: SkillData)`
- 主要函数：`display_skills()`、`clear_skills()`、`refresh()`、`focus_first_skill()`、`_build_row_text()`、`_sort_skills()`、`_on_entry_selected()`、`_on_entry_focused()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/components/skill_panel.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-components-tracked-inventory-hud-gd"></a>
### `scripts/ui/components/tracked_inventory_hud.gd`

- 继承：`PanelContainer`；类名：`TrackedInventoryHUD`。
- 信号：无。
- 主要函数：`bind_inventory()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-components-tracked-item-row-gd"></a>
### `scripts/ui/components/tracked_item_row.gd`

- 继承：`HBoxContainer`；类名：`TrackedItemRow`。
- 信号：无。
- 主要函数：`_ready()`、`bind_inventory()`、`refresh()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。

<a id="script-scripts-ui-esc-menu-gd"></a>
### `scripts/ui/esc_menu.gd`

- 继承：`CanvasLayer`；类名：`EscMenu`。
- 信号：`opened`、`closed`
- 主要函数：`_ready()`、`_unhandled_input()`、`bind_player()`、`refresh_content()`、`open()`、`close()`、`toggle()`、`is_open()`、`refresh_player_stats()`、`_show_main_page()`、`_show_category()`、`_navigate_horizontal()`、`_focus_current_page()`、`_focus_main_tab()`、`_is_main_tab_focused()`、`_is_in_control()`、`_on_item_focused()`、`_on_item_selected()`、`_on_skill_focused()`、`_on_equipment_slot_focused()`、`_on_equipment_slot_selected()`、`_choose_equipment_target()`、`_build_player_view()`、`_display_entry_info()`
- 直接预载依赖：[`shared/game_formulas.gd`](#script-scripts-shared-game-formulas-gd)
- 场景侧：`scenes/ui/esc_menu.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

<a id="script-scripts-ui-game-hud-gd"></a>
### `scripts/ui/game_hud.gd`

- 继承：`CanvasLayer`；类名：`GameHUD`。
- 信号：无。
- 主要函数：`bind_player()`、`refresh_player_stats()`、`show_message()`、`clear_message()`
- 直接预载依赖：无直接脚本预载；类型或信号依赖见源码与调用链。
- 场景侧：`scenes/ui/game_hud.tscn` 负责节点、布局、碰撞体或可视内容；脚本只附加行为。

