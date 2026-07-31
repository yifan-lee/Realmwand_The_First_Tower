# GDScript 职责与调用关系

> 本文以当前实际代码为准。点击脚本名称可在本文内跳转；每节的“源文件”可直接打开仓库文件。

## 目录

- [`scripts/actors/enemy.gd`](#script-scripts-actors-enemy-gd)
- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/autoload/event_bus.gd`](#script-scripts-autoload-event-bus-gd)
- [`scripts/battle/battle_manager.gd`](#script-scripts-battle-battle-manager-gd)
- [`scripts/battle/battle_ui.gd`](#script-scripts-battle-battle-ui-gd)
- [`scripts/data/actor_data.gd`](#script-scripts-data-actor-data-gd)
- [`scripts/data/enemy_data.gd`](#script-scripts-data-enemy-data-gd)
- [`scripts/data/equipment_data.gd`](#script-scripts-data-equipment-data-gd)
- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/data/player_data.gd`](#script-scripts-data-player-data-gd)
- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)
- [`scripts/data/skill_effect_data.gd`](#script-scripts-data-skill-effect-data-gd)
- [`scripts/floors/floor.gd`](#script-scripts-floors-floor-gd)
- [`scripts/floors/floor_1.gd`](#script-scripts-floors-floor-1-gd)
- [`scripts/floors/floor_manager.gd`](#script-scripts-floors-floor-manager-gd)
- [`scripts/interactables/item_pickup.gd`](#script-scripts-interactables-item-pickup-gd)
- [`scripts/interactables/stair.gd`](#script-scripts-interactables-stair-gd)
- [`scripts/interactables/switch.gd`](#script-scripts-interactables-switch-gd)
- [`scripts/inventory/equipment_loadout.gd`](#script-scripts-inventory-equipment-loadout-gd)
- [`scripts/inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)
- [`scripts/main.gd`](#script-scripts-main-gd)
- [`scripts/progression/level_up_manager.gd`](#script-scripts-progression-level-up-manager-gd)
- [`scripts/progression/level_up_ui.gd`](#script-scripts-progression-level-up-ui-gd)
- [`scripts/ui/components/actor_stats_panel.gd`](#script-scripts-ui-components-actor-stats-panel-gd)
- [`scripts/ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)
- [`scripts/ui/components/entry_info_panel.gd`](#script-scripts-ui-components-entry-info-panel-gd)
- [`scripts/ui/components/entry_info_view_data.gd`](#script-scripts-ui-components-entry-info-view-data-gd)
- [`scripts/ui/components/game_message_panel.gd`](#script-scripts-ui-components-game-message-panel-gd)
- [`scripts/ui/components/inventory_panel.gd`](#script-scripts-ui-components-inventory-panel-gd)
- [`scripts/ui/components/player_stat_hud.gd`](#script-scripts-ui-components-player-stat-hud-gd)
- [`scripts/ui/components/selectable_list_row.gd`](#script-scripts-ui-components-selectable-list-row-gd)
- [`scripts/ui/components/skill_panel.gd`](#script-scripts-ui-components-skill-panel-gd)
- [`scripts/ui/components/tracked_inventory_hud.gd`](#script-scripts-ui-components-tracked-inventory-hud-gd)
- [`scripts/ui/components/tracked_item_row.gd`](#script-scripts-ui-components-tracked-item-row-gd)
- [`scripts/ui/esc_menu.gd`](#script-scripts-ui-esc-menu-gd)
- [`scripts/ui/game_hud.gd`](#script-scripts-ui-game-hud-gd)

## 总调用图

```text
main.gd
├─ bind → game_hud.gd / esc_menu.gd
├─ setup → battle_manager.gd / level_up_manager.gd
├─ ESC → esc_menu.toggle()
└─ battle_finished → game_hud.show_message()

stair.gd → EventBus.floor_change_requested → floor_manager.gd
enemy.gd → EventBus.battle_requested → battle_manager.gd
battle_manager.gd ↔ battle_ui.gd → skill_panel.gd / inventory_panel.gd
battle_manager.gd → player.add_experience() → level_up_manager.gd ↔ level_up_ui.gd
```

## `main.gd` 逐项说明

- `player`：世界中唯一 Player 运行时实例。
- `game_hud`：常驻 HUD 和独立 Message 入口。
- `esc_menu`：背包/技能/System 覆盖菜单。
- `battle_ui`、`level_up_ui`：只负责表现和用户选择。
- `battle_manager`、`level_up_manager`：独立功能系统。

`_ready()` 依次调用 [`GameHUD.bind_player()`](#script-scripts-ui-game-hud-gd)、[`EscMenu.bind_player()`](#script-scripts-ui-esc-menu-gd)、[`BattleManager.setup()`](#script-scripts-battle-battle-manager-gd) 和 [`LevelUpManager.setup()`](#script-scripts-progression-level-up-manager-gd)；随后监听 BattleManager 的 `battle_finished`。

`_unhandled_input()` 接收 `toggle_menu`。若战斗或升级正在显示则消费输入但不打开菜单；否则调用 [`EscMenu.toggle()`](#script-scripts-ui-esc-menu-gd)。战斗结束后 `_on_battle_finished()` 调用 [`GameHUD.show_message()`](#script-scripts-ui-game-hud-gd)。

## 关键事件链

### 换层

1. [`stair.gd`](#script-scripts-interactables-stair-gd) 发出 `EventBus.floor_change_requested`。
2. [`floor_manager.gd`](#script-scripts-floors-floor-manager-gd) 接收后加载目标 `floor_n.tscn`。
3. 新 Floor 提供 spawn point；旧 Floor 状态被保存，新 Floor 状态被恢复。

### 战斗

1. [`enemy.gd`](#script-scripts-actors-enemy-gd) 的 `interact(player)` 发 `EventBus.battle_requested`。
2. [`battle_manager.gd`](#script-scripts-battle-battle-manager-gd) 接收并打开 [`battle_ui.gd`](#script-scripts-battle-battle-ui-gd)。
3. Battle UI 从 [`skill_panel.gd`](#script-scripts-ui-components-skill-panel-gd) / [`inventory_panel.gd`](#script-scripts-ui-components-inventory-panel-gd) 收到选择后转发。
4. Manager 修改 [`player.gd`](#script-scripts-actors-player-gd) / [`enemy.gd`](#script-scripts-actors-enemy-gd) 的运行时 HP、MP；胜利后给经验。

### 升级

1. [`player.gd`](#script-scripts-actors-player-gd) `add_experience()` 跨过阈值后发 `level_up_available`。
2. [`level_up_manager.gd`](#script-scripts-progression-level-up-manager-gd) 打开 [`level_up_ui.gd`](#script-scripts-progression-level-up-ui-gd) 并禁用 Player 输入。
3. UI 发 `stat_selected`；Manager 调用 `Player.spend_stat_point()`；点数归零后才允许关闭。

## 全部脚本


<a id="script-scripts-actors-enemy-gd"></a>
### `scripts/actors/enemy.gd`

源文件：[scripts/actors/enemy.gd](../scripts/actors/enemy.gd)

地图敌人实体：从 EnemyData 更新外观，接收伤害，交互时请求战斗。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `current_hp` | 公开、Inspector 或节点/运行时数据。 |
| `current_mp` | 公开、Inspector 或节点/运行时数据。 |
| `is_defeated` | 公开、Inspector 或节点/运行时数据。 |
| `_active_collision_layer` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

- `battle_requested`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `stats_changed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `_ready()`
- `interact(player: Player)`
- `take_damage(amount: float)`
- `change_mp(amount: float)`
- `set_defeated(defeated: bool)`
- `_get_configuration_warnings()`
- `_refresh_visual()`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/autoload/event_bus.gd`](#script-scripts-autoload-event-bus-gd)
- [`scripts/data/enemy_data.gd`](#script-scripts-data-enemy-data-gd)

#### 场景侧功能

`scenes/actors/enemies/enemy.tscn` 与预配置的 `enemy_balance_lv1.tscn`。


<a id="script-scripts-actors-player-gd"></a>
### `scripts/actors/player.gd`

源文件：[scripts/actors/player.gd](../scripts/actors/player.gd)

玩家运行时实体：网格移动、交互、运行时属性、背包/装备、经验与属性点。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `animated_sprite` | 公开、Inspector 或节点/运行时数据。 |
| `interaction_ray` | 公开、Inspector 或节点/运行时数据。 |
| `inventory` | 公开、Inspector 或节点/运行时数据。 |
| `equipment` | 公开、Inspector 或节点/运行时数据。 |
| `level` | 公开、Inspector 或节点/运行时数据。 |
| `experience` | 公开、Inspector 或节点/运行时数据。 |
| `gold` | 公开、Inspector 或节点/运行时数据。 |
| `unspent_stat_points` | 公开、Inspector 或节点/运行时数据。 |
| `base_max_hp` | 公开、Inspector 或节点/运行时数据。 |
| `base_max_mp` | 公开、Inspector 或节点/运行时数据。 |
| `base_atk` | 公开、Inspector 或节点/运行时数据。 |
| `base_def` | 公开、Inspector 或节点/运行时数据。 |
| `base_spd` | 公开、Inspector 或节点/运行时数据。 |
| `current_hp` | 公开、Inspector 或节点/运行时数据。 |
| `current_mp` | 公开、Inspector 或节点/运行时数据。 |
| `learned_skills` | 公开、Inspector 或节点/运行时数据。 |
| `facing_direction` | 公开、Inspector 或节点/运行时数据。 |
| `is_moving` | 公开、Inspector 或节点/运行时数据。 |
| `input_enabled` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
接收 `_unhandled_input()`；动作判断、消费输入和后续调用见函数列表。

#### 信号

- `movement_finished`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `stats_changed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `level_up_available`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `_ready()`
- `_unhandled_input(event: InputEvent)`
- `_initialize_runtime_state()`
- `_apply_data_visuals()`
- `_set_facing_direction(direction: Vector2)`
- `_update_interaction_ray()`
- `_move_one_tile(direction: Vector2)`
- `_play_directional_animation(action: StringName)`
- `_get_direction_suffix()`
- `_try_interact()`
- `set_input_enabled(enabled: bool)`
- `set_current_hp(value: float)`
- `change_hp(amount: float)`
- `set_current_mp(value: float)`
- `change_mp(amount: float)`
- `get_experience_for_next_level()`
- `add_experience(amount: int)`
- `spend_stat_point(stat_id: StringName)`
- `equip_item(item_id: StringName, target_slot: int)`
- `unequip_item(target_slot: int)`
- `get_max_hp()`
- `get_max_mp()`
- `get_atk()`
- `get_def()`
- `get_spd()`
- `_on_equipment_changed()`

#### 涉及的其他脚本

- [`scripts/data/equipment_data.gd`](#script-scripts-data-equipment-data-gd)
- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/data/player_data.gd`](#script-scripts-data-player-data-gd)
- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)
- [`scripts/inventory/equipment_loadout.gd`](#script-scripts-inventory-equipment-loadout-gd)
- [`scripts/inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)

#### 场景侧功能

`scenes/actors/player.tscn`；Inventory、Equipment、InteractionRay、Camera2D 都在场景中。


<a id="script-scripts-autoload-event-bus-gd"></a>
### `scripts/autoload/event_bus.gd`

源文件：[scripts/autoload/event_bus.gd](../scripts/autoload/event_bus.gd)

跨模块事件总线：让 Stair、Enemy 等世界对象不直接依赖管理器实例。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

- `floor_change_requested`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `battle_requested`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

- [`scripts/actors/enemy.gd`](#script-scripts-actors-enemy-gd)
- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)


<a id="script-scripts-battle-battle-manager-gd"></a>
### `scripts/battle/battle_manager.gd`

源文件：[scripts/battle/battle_manager.gd](../scripts/battle/battle_manager.gd)

秒制 ATB 战斗状态机：行动条、冷却、伤害、物品、胜负和奖励。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `ATB_MAX` | 常量；用于该脚本的固定配置或枚举值。 |
| `_player` | 脚本内部运行时状态/依赖引用。 |
| `_enemy` | 脚本内部运行时状态/依赖引用。 |
| `_battle_ui` | 脚本内部运行时状态/依赖引用。 |
| `_active` | 脚本内部运行时状态/依赖引用。 |
| `_player_atb` | 脚本内部运行时状态/依赖引用。 |
| `_enemy_atb` | 脚本内部运行时状态/依赖引用。 |
| `_player_ready` | 脚本内部运行时状态/依赖引用。 |
| `_cooldowns` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
外部通过 `setup()` 注入依赖并连接信号。
不直接接收 InputMap 输入。

#### 信号

- `battle_started`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `battle_finished`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `setup(player: Player, battle_ui: BattleUI)`
- `is_active()`
- `_process(delta: float)`
- `start_battle(enemy: Enemy, player: Player)`
- `_on_battle_requested(enemy: Enemy, player: Player)`
- `_on_skill_selected(skill: SkillData)`
- `_on_item_selected(item: ItemData)`
- `_on_escape_requested()`
- `_enemy_take_turn()`
- `_complete_player_action()`
- `_finish_battle(victory: bool)`
- `_get_experience_reward()`
- `_tick_cooldowns(delta: float)`

#### 涉及的其他脚本

- [`scripts/actors/enemy.gd`](#script-scripts-actors-enemy-gd)
- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/autoload/event_bus.gd`](#script-scripts-autoload-event-bus-gd)
- [`scripts/battle/battle_ui.gd`](#script-scripts-battle-battle-ui-gd)
- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)


<a id="script-scripts-battle-battle-ui-gd"></a>
### `scripts/battle/battle_ui.gd`

源文件：[scripts/battle/battle_ui.gd](../scripts/battle/battle_ui.gd)

战斗表现层：复用属性、技能和背包组件，向 BattleManager 发出选择信号。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `battle_root` | 公开、Inspector 或节点/运行时数据。 |
| `player_stats` | 公开、Inspector 或节点/运行时数据。 |
| `enemy_stats` | 公开、Inspector 或节点/运行时数据。 |
| `player_atb` | 公开、Inspector 或节点/运行时数据。 |
| `enemy_atb` | 公开、Inspector 或节点/运行时数据。 |
| `skill_panel` | 公开、Inspector 或节点/运行时数据。 |
| `inventory_panel` | 公开、Inspector 或节点/运行时数据。 |
| `message_label` | 公开、Inspector 或节点/运行时数据。 |
| `escape_button` | 公开、Inspector 或节点/运行时数据。 |
| `_player` | 脚本内部运行时状态/依赖引用。 |
| `_enemy` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

- `skill_selected`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `item_selected`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `escape_requested`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `_ready()`
- `open(player: Player, enemy: Enemy)`
- `close()`
- `set_action_available(available: bool)`
- `set_atb(player_value: float, enemy_value: float)`
- `show_message(message: String)`
- `refresh_stats()`
- `_build_player_view()`
- `_build_enemy_view()`

#### 涉及的其他脚本

- [`scripts/actors/enemy.gd`](#script-scripts-actors-enemy-gd)
- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)
- [`scripts/ui/components/actor_stats_panel.gd`](#script-scripts-ui-components-actor-stats-panel-gd)
- [`scripts/ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)
- [`scripts/ui/components/inventory_panel.gd`](#script-scripts-ui-components-inventory-panel-gd)
- [`scripts/ui/components/skill_panel.gd`](#script-scripts-ui-components-skill-panel-gd)

#### 场景侧功能

`scenes/battle/battle_ui.tscn`；两个属性面板、技能、背包、ATB 条和按钮均在场景中。


<a id="script-scripts-data-actor-data-gd"></a>
### `scripts/data/actor_data.gd`

源文件：[scripts/data/actor_data.gd](../scripts/data/actor_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。


<a id="script-scripts-data-enemy-data-gd"></a>
### `scripts/data/enemy_data.gd`

源文件：[scripts/data/enemy_data.gd](../scripts/data/enemy_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

- [`scripts/data/actor_data.gd`](#script-scripts-data-actor-data-gd)
- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)


<a id="script-scripts-data-equipment-data-gd"></a>
### `scripts/data/equipment_data.gd`

源文件：[scripts/data/equipment_data.gd](../scripts/data/equipment_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)


<a id="script-scripts-data-item-data-gd"></a>
### `scripts/data/item_data.gd`

源文件：[scripts/data/item_data.gd](../scripts/data/item_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

- [`scripts/inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)


<a id="script-scripts-data-player-data-gd"></a>
### `scripts/data/player_data.gd`

源文件：[scripts/data/player_data.gd](../scripts/data/player_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/data/actor_data.gd`](#script-scripts-data-actor-data-gd)
- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)


<a id="script-scripts-data-skill-data-gd"></a>
### `scripts/data/skill_data.gd`

源文件：[scripts/data/skill_data.gd](../scripts/data/skill_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

- [`scripts/data/skill_effect_data.gd`](#script-scripts-data-skill-effect-data-gd)


<a id="script-scripts-data-skill-effect-data-gd"></a>
### `scripts/data/skill_effect_data.gd`

源文件：[scripts/data/skill_effect_data.gd](../scripts/data/skill_effect_data.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

无持久变量；主要提供数据类型或无状态方法。

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。


<a id="script-scripts-floors-floor-gd"></a>
### `scripts/floors/floor.gd`

源文件：[scripts/floors/floor.gd](../scripts/floors/floor.gd)

所有楼层共有的节点引用、出生点查找、Tile cell 捕获/恢复和状态接口。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `spawn_points` | 公开、Inspector 或节点/运行时数据。 |
| `interactables` | 公开、Inspector 或节点/运行时数据。 |
| `enemies` | 公开、Inspector 或节点/运行时数据。 |
| `pickups` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `get_spawn_point(spawn_id: StringName)`
- `capture_tile_cells(layer: TileMapLayer, cells: Array[Vector2i])`
- `set_tile_cells_removed(layer: TileMapLayer, snapshots: Array[TileCellSnapshot], removed: bool)`
- `capture_runtime_state()`
- `apply_runtime_state(state: Dictionary)`
- `_apply_switch_states(switch_states_value: Variant)`
- `_apply_pickup_states(pickup_states_value: Variant)`
- `_apply_enemy_states(enemy_states_value: Variant)`

#### 涉及的其他脚本

- [`scripts/actors/enemy.gd`](#script-scripts-actors-enemy-gd)
- [`scripts/interactables/item_pickup.gd`](#script-scripts-interactables-item-pickup-gd)
- [`scripts/interactables/switch.gd`](#script-scripts-interactables-switch-gd)

#### 场景侧功能

`scenes/floors/floor.tscn`；TileMapLayer 和各内容容器在场景中。


<a id="script-scripts-floors-floor-1-gd"></a>
### `scripts/floors/floor_1.gd`

源文件：[scripts/floors/floor_1.gd](../scripts/floors/floor_1.gd)

一楼专属 Switch 到多格地图变化的映射与状态缓存。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `wall_layer` | 公开、Inspector 或节点/运行时数据。 |
| `switch_rules` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `_ready()`
- `_create_switch_rules()`
- `_cache_switch_terrain()`
- `_apply_initial_switch_states()`
- `_on_floor_switch_state_changed(switch_id: StringName, is_active: bool)`
- `_apply_switch_state(switch_id: StringName, is_active: bool)`

#### 涉及的其他脚本

- [`scripts/floors/floor.gd`](#script-scripts-floors-floor-gd)
- [`scripts/interactables/switch.gd`](#script-scripts-interactables-switch-gd)

#### 场景侧功能

`scenes/floors/floor_1.tscn`；Switch、敌人、Pickup 和地图格由场景放置。


<a id="script-scripts-floors-floor-manager-gd"></a>
### `scripts/floors/floor_manager.gd`

源文件：[scripts/floors/floor_manager.gd](../scripts/floors/floor_manager.gd)

动态加载单一当前楼层，保存/恢复楼层状态，并把 Player 放到目标出生点。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `FLOOR_SCENE_DIRECTORY` | 常量；用于该脚本的固定配置或枚举值。 |
| `floor_container` | 公开、Inspector 或节点/运行时数据。 |
| `player` | 公开、Inspector 或节点/运行时数据。 |
| `current_floor` | 公开、Inspector 或节点/运行时数据。 |
| `current_floor_id` | 公开、Inspector 或节点/运行时数据。 |
| `floor_states` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `_ready()`
- `change_floor(target_floor_id: StringName, target_spawn_id: StringName)`
- `_on_floor_change_requested(target_floor_id: StringName, target_spawn_id: StringName)`
- `_store_current_floor_state()`
- `_apply_saved_floor_state(floor: Floor)`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/autoload/event_bus.gd`](#script-scripts-autoload-event-bus-gd)
- [`scripts/floors/floor.gd`](#script-scripts-floors-floor-gd)


<a id="script-scripts-interactables-item-pickup-gd"></a>
### `scripts/interactables/item_pickup.gd`

源文件：[scripts/interactables/item_pickup.gd](../scripts/interactables/item_pickup.gd)

通用物品/装备拾取物：尝试加入 Inventory，成功后消失。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `is_collected` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

- `picked_up`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `_ready()`
- `_on_body_entered(body: Node2D)`
- `_refresh_visual()`
- `_get_configuration_warnings()`
- `set_collected(collected: bool)`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)

#### 场景侧功能

`scenes/interactables/item_pickup.tscn`；具体 ItemData 与数量由实例 Inspector 填写。


<a id="script-scripts-interactables-stair-gd"></a>
### `scripts/interactables/stair.gd`

源文件：[scripts/interactables/stair.gd](../scripts/interactables/stair.gd)

Player 进入 Area2D 后请求换层，并处理出生点与楼梯重叠的初始抑制。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `transition_requested` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `_ready()`
- `_on_body_entered(body: Node2D)`
- `_update_visual()`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/autoload/event_bus.gd`](#script-scripts-autoload-event-bus-gd)

#### 场景侧功能

`scenes/interactables/stair.tscn`；Area2D、碰撞形状、上下楼贴图在场景/Inspector。


<a id="script-scripts-interactables-switch-gd"></a>
### `scripts/interactables/switch.gd`

源文件：[scripts/interactables/switch.gd](../scripts/interactables/switch.gd)

可反复切换的阻挡型交互物，只保存开关状态并发信号。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `animated_sprite` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

- `state_changed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `_ready()`
- `interact(_player: Node)`
- `set_active(active: bool)`
- `_update_visual()`

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。

#### 场景侧功能

`scenes/interactables/switch.tscn`；StaticBody2D 碰撞体决定不可穿越。


<a id="script-scripts-inventory-equipment-loadout-gd"></a>
### `scripts/inventory/equipment_loadout.gd`

源文件：[scripts/inventory/equipment_loadout.gd](../scripts/inventory/equipment_loadout.gd)

装备槽位、冲突装备、双手占位和所有装备属性加成。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `_equipped` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

- `equipment_changed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `item_equipped`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `item_unequipped`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `can_equip(item: EquipmentData, target_slot: int)`
- `equip(item: EquipmentData, target_slot: int)`
- `unequip(slot: int)`
- `get_equipped(slot: int)`
- `get_unique_equipped_items()`
- `_can_equip_in_hand(item: EquipmentData, target_slot: int)`
- `_collect_displaced_items(item: EquipmentData, target_slot: int)`
- `_remove_equipped_item(item: EquipmentData)`
- `get_max_hp_bonus()`
- `get_max_mp_bonus()`
- `get_atk_bonus()`
- `get_def_bonus()`
- `get_spd_bonus()`
- `get_displaced_items(item: EquipmentData, target_slot: int)`

#### 涉及的其他脚本

- [`scripts/data/equipment_data.gd`](#script-scripts-data-equipment-data-gd)


<a id="script-scripts-inventory-inventory-gd"></a>
### `scripts/inventory/inventory.gd`

源文件：[scripts/inventory/inventory.gd](../scripts/inventory/inventory.gd)

按 ItemData.id 管理资源引用与数量，负责堆叠限制和变化信号。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `_items` | 脚本内部运行时状态/依赖引用。 |
| `_quantities` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

- `inventory_changed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `item_added`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `item_removed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `add_item(item: ItemData, amount: int = 1)`
- `remove_item(item_id: StringName, amount: int = 1)`
- `has_item(item_id: StringName, amount: int = 1)`
- `get_quantity(item_id: StringName)`
- `get_item(item_id: StringName)`
- `get_all_items()`
- `get_remaining_capacity(item: ItemData)`

#### 涉及的其他脚本

- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)


<a id="script-scripts-main-gd"></a>
### `scripts/main.gd`

源文件：[scripts/main.gd](../scripts/main.gd)

顶层组合根：绑定 Player、HUD、ESC、BattleManager、LevelUpManager；只处理 UI 层级仲裁与结果转发。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `player` | 公开、Inspector 或节点/运行时数据。 |
| `game_hud` | 公开、Inspector 或节点/运行时数据。 |
| `esc_menu` | 公开、Inspector 或节点/运行时数据。 |
| `battle_ui` | 公开、Inspector 或节点/运行时数据。 |
| `level_up_ui` | 公开、Inspector 或节点/运行时数据。 |
| `battle_manager` | 公开、Inspector 或节点/运行时数据。 |
| `level_up_manager` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
接收 `_unhandled_input()`；动作判断、消费输入和后续调用见函数列表。

#### 信号

无自定义 signal。

#### 主要函数

- `_ready()`
- `_unhandled_input(event: InputEvent)`
- `_on_battle_finished(victory: bool)`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/battle/battle_manager.gd`](#script-scripts-battle-battle-manager-gd)
- [`scripts/battle/battle_ui.gd`](#script-scripts-battle-battle-ui-gd)
- [`scripts/progression/level_up_manager.gd`](#script-scripts-progression-level-up-manager-gd)
- [`scripts/progression/level_up_ui.gd`](#script-scripts-progression-level-up-ui-gd)
- [`scripts/ui/esc_menu.gd`](#script-scripts-ui-esc-menu-gd)
- [`scripts/ui/game_hud.gd`](#script-scripts-ui-game-hud-gd)

#### 场景侧功能

`scenes/main.tscn` 根节点；Systems 与 OverlayRoot 的组合关系主要由场景定义。


<a id="script-scripts-progression-level-up-manager-gd"></a>
### `scripts/progression/level_up_manager.gd`

源文件：[scripts/progression/level_up_manager.gd](../scripts/progression/level_up_manager.gd)

连接 Player 的升级信号与升级 UI，执行属性点分配。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `_player` | 脚本内部运行时状态/依赖引用。 |
| `_level_up_ui` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
外部通过 `setup()` 注入依赖并连接信号。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `setup(player: Player, level_up_ui: LevelUpUI)`
- `is_active()`
- `_on_level_up_available()`
- `_on_stat_selected(stat_id: StringName)`
- `_on_close_requested()`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/progression/level_up_ui.gd`](#script-scripts-progression-level-up-ui-gd)


<a id="script-scripts-progression-level-up-ui-gd"></a>
### `scripts/progression/level_up_ui.gd`

源文件：[scripts/progression/level_up_ui.gd](../scripts/progression/level_up_ui.gd)

升级表现层：显示属性与剩余点数，发出选择/关闭请求。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `level_root` | 公开、Inspector 或节点/运行时数据。 |
| `stats_panel` | 公开、Inspector 或节点/运行时数据。 |
| `points_label` | 公开、Inspector 或节点/运行时数据。 |
| `close_button` | 公开、Inspector 或节点/运行时数据。 |
| `_player` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
不直接接收 InputMap 输入。

#### 信号

- `stat_selected`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `close_requested`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `_ready()`
- `open(player: Player)`
- `close()`
- `refresh()`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/ui/components/actor_stats_panel.gd`](#script-scripts-ui-components-actor-stats-panel-gd)
- [`scripts/ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)

#### 场景侧功能

`scenes/ui/progression/level_up_ui.tscn`；属性面板和五个加点按钮均在场景中。


<a id="script-scripts-ui-components-actor-stats-panel-gd"></a>
### `scripts/ui/components/actor_stats_panel.gd`

源文件：[scripts/ui/components/actor_stats_panel.gd](../scripts/ui/components/actor_stats_panel.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `portrait` | 公开、Inspector 或节点/运行时数据。 |
| `name_label` | 公开、Inspector 或节点/运行时数据。 |
| `hp_value` | 公开、Inspector 或节点/运行时数据。 |
| `mp_value` | 公开、Inspector 或节点/运行时数据。 |
| `atk_value` | 公开、Inspector 或节点/运行时数据。 |
| `def_value` | 公开、Inspector 或节点/运行时数据。 |
| `spd_value` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `display_stats(view_data: ActorStatsViewData)`
- `clear_stats()`
- `_format_stat(value: float, delta: float)`

#### 涉及的其他脚本

- [`scripts/ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)


<a id="script-scripts-ui-components-actor-stats-view-data-gd"></a>
### `scripts/ui/components/actor_stats_view_data.gd`

源文件：[scripts/ui/components/actor_stats_view_data.gd](../scripts/ui/components/actor_stats_view_data.gd)

纯显示模型，隔离运行时 Actor 与 ActorStatsPanel。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `display_name` | 公开、Inspector 或节点/运行时数据。 |
| `portrait` | 公开、Inspector 或节点/运行时数据。 |
| `current_hp` | 公开、Inspector 或节点/运行时数据。 |
| `max_hp` | 公开、Inspector 或节点/运行时数据。 |
| `current_mp` | 公开、Inspector 或节点/运行时数据。 |
| `max_mp` | 公开、Inspector 或节点/运行时数据。 |
| `atk` | 公开、Inspector 或节点/运行时数据。 |
| `def` | 公开、Inspector 或节点/运行时数据。 |
| `spd` | 公开、Inspector 或节点/运行时数据。 |
| `max_hp_delta` | 公开、Inspector 或节点/运行时数据。 |
| `max_mp_delta` | 公开、Inspector 或节点/运行时数据。 |
| `atk_delta` | 公开、Inspector 或节点/运行时数据。 |
| `def_delta` | 公开、Inspector 或节点/运行时数据。 |
| `spd_delta` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。


<a id="script-scripts-ui-components-entry-info-panel-gd"></a>
### `scripts/ui/components/entry_info_panel.gd`

源文件：[scripts/ui/components/entry_info_panel.gd](../scripts/ui/components/entry_info_panel.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `icon_rect` | 公开、Inspector 或节点/运行时数据。 |
| `title_label` | 公开、Inspector 或节点/运行时数据。 |
| `description_label` | 公开、Inspector 或节点/运行时数据。 |
| `details_separator` | 公开、Inspector 或节点/运行时数据。 |
| `details_label` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `display_info(view_data: EntryInfoViewData)`
- `clear_info()`

#### 涉及的其他脚本

- [`scripts/ui/components/entry_info_view_data.gd`](#script-scripts-ui-components-entry-info-view-data-gd)


<a id="script-scripts-ui-components-entry-info-view-data-gd"></a>
### `scripts/ui/components/entry_info_view_data.gd`

源文件：[scripts/ui/components/entry_info_view_data.gd](../scripts/ui/components/entry_info_view_data.gd)

物品/技能信息面板的纯显示模型。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `title` | 公开、Inspector 或节点/运行时数据。 |
| `icon` | 公开、Inspector 或节点/运行时数据。 |
| `description` | 公开、Inspector 或节点/运行时数据。 |
| `detail_lines` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

无方法，仅定义数据字段。

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。


<a id="script-scripts-ui-components-game-message-panel-gd"></a>
### `scripts/ui/components/game_message_panel.gd`

源文件：[scripts/ui/components/game_message_panel.gd](../scripts/ui/components/game_message_panel.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `message_label` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `show_message(message: String)`
- `clear_message()`

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。


<a id="script-scripts-ui-components-inventory-panel-gd"></a>
### `scripts/ui/components/inventory_panel.gd`

源文件：[scripts/ui/components/inventory_panel.gd](../scripts/ui/components/inventory_panel.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `item_rows` | 公开、Inspector 或节点/运行时数据。 |
| `empty_label` | 公开、Inspector 或节点/运行时数据。 |
| `_inventory` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
通过 `bind_*()` 接收运行时数据源，并在重新绑定时断开旧信号。
不直接接收 InputMap 输入。

#### 信号

- `item_selected`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `bind_inventory(inventory: Inventory)`
- `refresh()`
- `_sort_items(left: ItemData, right: ItemData)`
- `_on_entry_selected(entry: Resource)`

#### 涉及的其他脚本

- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)
- [`scripts/ui/components/selectable_list_row.gd`](#script-scripts-ui-components-selectable-list-row-gd)


<a id="script-scripts-ui-components-player-stat-hud-gd"></a>
### `scripts/ui/components/player_stat_hud.gd`

源文件：[scripts/ui/components/player_stat_hud.gd](../scripts/ui/components/player_stat_hud.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `name_label` | 公开、Inspector 或节点/运行时数据。 |
| `hp_value` | 公开、Inspector 或节点/运行时数据。 |
| `hp_bar` | 公开、Inspector 或节点/运行时数据。 |
| `mp_value` | 公开、Inspector 或节点/运行时数据。 |
| `mp_bar` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `display_stats(view_data: ActorStatsViewData)`
- `clear_stats()`
- `_set_bar(bar: ProgressBar, value_label: Label, current_value: float, maximum_value: float)`

#### 涉及的其他脚本

- [`scripts/ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)


<a id="script-scripts-ui-components-selectable-list-row-gd"></a>
### `scripts/ui/components/selectable_list_row.gd`

源文件：[scripts/ui/components/selectable_list_row.gd](../scripts/ui/components/selectable_list_row.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `entry_data` | 公开、Inspector 或节点/运行时数据。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
外部通过 `setup()` 注入依赖并连接信号。
不直接接收 InputMap 输入。

#### 信号

- `entry_selected`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `setup(entry: Resource, entry_text: String, entry_icon: Texture2D, entry_tooltip: String)`
- `_pressed()`

#### 涉及的其他脚本

没有显式脚本类型依赖；可能只依赖 Godot 内建节点/Resource。


<a id="script-scripts-ui-components-skill-panel-gd"></a>
### `scripts/ui/components/skill_panel.gd`

源文件：[scripts/ui/components/skill_panel.gd](../scripts/ui/components/skill_panel.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `skill_rows` | 公开、Inspector 或节点/运行时数据。 |
| `empty_label` | 公开、Inspector 或节点/运行时数据。 |
| `_skills` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
不直接接收 InputMap 输入。

#### 信号

- `skill_selected`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `display_skills(skills: Array[SkillData])`
- `clear_skills()`
- `refresh()`
- `_build_row_text(skill: SkillData)`
- `_sort_skills(left: SkillData, right: SkillData)`
- `_on_entry_selected(entry: Resource)`

#### 涉及的其他脚本

- [`scripts/data/skill_data.gd`](#script-scripts-data-skill-data-gd)
- [`scripts/ui/components/selectable_list_row.gd`](#script-scripts-ui-components-selectable-list-row-gd)


<a id="script-scripts-ui-components-tracked-inventory-hud-gd"></a>
### `scripts/ui/components/tracked_inventory_hud.gd`

源文件：[scripts/ui/components/tracked_inventory_hud.gd](../scripts/ui/components/tracked_inventory_hud.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `item_rows` | 公开、Inspector 或节点/运行时数据。 |
| `_inventory` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
通过 `bind_*()` 接收运行时数据源，并在重新绑定时断开旧信号。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `bind_inventory(inventory: Inventory)`

#### 涉及的其他脚本

- [`scripts/inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)
- [`scripts/ui/components/tracked_item_row.gd`](#script-scripts-ui-components-tracked-item-row-gd)


<a id="script-scripts-ui-components-tracked-item-row-gd"></a>
### `scripts/ui/components/tracked_item_row.gd`

源文件：[scripts/ui/components/tracked_item_row.gd](../scripts/ui/components/tracked_item_row.gd)

该脚本承担其目录对应模块的单一职责，并通过类型、节点引用或信号与外部协作。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `icon_rect` | 公开、Inspector 或节点/运行时数据。 |
| `name_label` | 公开、Inspector 或节点/运行时数据。 |
| `quantity_label` | 公开、Inspector 或节点/运行时数据。 |
| `_inventory` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

存在 `_ready()`：初始化节点引用相关的绑定、数据或初始显示；准确顺序见源文件中的 `_ready()`。
通过 `bind_*()` 接收运行时数据源，并在重新绑定时断开旧信号。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `_ready()`
- `bind_inventory(inventory: Inventory)`
- `refresh()`

#### 涉及的其他脚本

- [`scripts/data/item_data.gd`](#script-scripts-data-item-data-gd)
- [`scripts/inventory/inventory.gd`](#script-scripts-inventory-inventory-gd)


<a id="script-scripts-ui-esc-menu-gd"></a>
### `scripts/ui/esc_menu.gd`

源文件：[scripts/ui/esc_menu.gd](../scripts/ui/esc_menu.gd)

ESC 覆盖菜单：绑定背包与技能，控制 Player 输入。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `inventory_panel` | 公开、Inspector 或节点/运行时数据。 |
| `skill_panel` | 公开、Inspector 或节点/运行时数据。 |
| `menu_root` | 公开、Inspector 或节点/运行时数据。 |
| `_player` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
通过 `bind_*()` 接收运行时数据源，并在重新绑定时断开旧信号。
不直接接收 InputMap 输入。

#### 信号

- `opened`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。
- `closed`：由本脚本在对应状态变化/用户选择时发出；接收方由调用者的 setup、场景连接或下列依赖脚本注册。

#### 主要函数

- `bind_player(player: Player)`
- `refresh_content()`
- `open()`
- `close()`
- `toggle()`
- `is_open()`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/ui/components/inventory_panel.gd`](#script-scripts-ui-components-inventory-panel-gd)
- [`scripts/ui/components/skill_panel.gd`](#script-scripts-ui-components-skill-panel-gd)

#### 场景侧功能

`scenes/ui/esc_menu.tscn`；InventoryPanel、SkillPanel 是真正的子场景实例。


<a id="script-scripts-ui-game-hud-gd"></a>
### `scripts/ui/game_hud.gd`

源文件：[scripts/ui/game_hud.gd](../scripts/ui/game_hud.gd)

常驻 HUD：把 Player 运行时数据转换为视图数据，并显示独立消息。

#### 变量与常量

| 名称 | 作用 |
|---|---|
| `player_stat_hud` | 公开、Inspector 或节点/运行时数据。 |
| `tracked_inventory_hud` | 公开、Inspector 或节点/运行时数据。 |
| `game_message_panel` | 公开、Inspector 或节点/运行时数据。 |
| `_player` | 脚本内部运行时状态/依赖引用。 |

#### `_ready()` / setup 与输入

没有 `_ready()`；由构造默认值、外部 `setup()` / `bind_*()` 或调用方法驱动。
通过 `bind_*()` 接收运行时数据源，并在重新绑定时断开旧信号。
不直接接收 InputMap 输入。

#### 信号

无自定义 signal。

#### 主要函数

- `bind_player(player: Player)`
- `refresh_player_stats()`
- `show_message(message: String)`
- `clear_message()`

#### 涉及的其他脚本

- [`scripts/actors/player.gd`](#script-scripts-actors-player-gd)
- [`scripts/ui/components/actor_stats_view_data.gd`](#script-scripts-ui-components-actor-stats-view-data-gd)
- [`scripts/ui/components/game_message_panel.gd`](#script-scripts-ui-components-game-message-panel-gd)
- [`scripts/ui/components/player_stat_hud.gd`](#script-scripts-ui-components-player-stat-hud-gd)
- [`scripts/ui/components/tracked_inventory_hud.gd`](#script-scripts-ui-components-tracked-inventory-hud-gd)

#### 场景侧功能

`scenes/ui/game_hud.tscn`；常驻属性、跟踪物品、Message 的位置由场景定义。

