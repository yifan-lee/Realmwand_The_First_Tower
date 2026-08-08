# 游戏架构规划

## 当前状态

从零重建的第 1—8 块已形成首个可运行闭环：数据、楼层、Player、Enemy、
Pickup、背包/装备、共享 UI、ESC、秒制 ATB 战斗与升级加点均已接入 Main。

当前仍属于早期开发实现，战斗数值、技能 Effect 执行、门/NPC、保存读取和
正式内容配置将在后续迭代中继续扩展。

## 目标场景结构

```text
Main
├── World
│   ├── FloorContainer
│   └── Player
├── Systems
│   ├── FloorManager
│   ├── BattleManager
│   └── LevelUpManager
└── OverlayRoot
    ├── GameHUD
    ├── EscMenu
    ├── BattleUI
    └── LevelUpUI
```

## 目标目录

```text
scenes/
├── main.tscn
├── actors/
│   ├── player.tscn
│   └── enemies/
├── floors/
├── interactables/
├── battle/
└── ui/
    ├── components/
    ├── hud/
    ├── menus/
    └── message/

scripts/
├── main.gd
├── data/
├── actors/
├── floors/
├── interactables/
├── inventory/
├── battle/
├── progression/
└── ui/

resources/
├── actors/
├── items/
├── skills/
└── tilesets/
```

## 已确认的职责

- `FloorManager` 动态加载当前楼层，楼层不直接固定在 Main 中。
- `PlayerData` 保存玩家基础定义；玩家运行时状态保存在 Player 实例。
- `EnemyData` 保存敌人基础定义，并预先配置到具体 Enemy 场景。
- Pickup 保持通用，通过 `ItemData` 同时支持普通物品和装备。
- Stair 使用一个公共场景和脚本，通过 Inspector 选择 Up/Down 外观，
  并配置目标楼层与目标出生点。
- Switch 只保存自身状态并发出信号；具体地图变化由 `floor_n.gd` 处理。
- UI 使用可复用辅助组件；HUD、ESC 菜单、战斗和 Message 使用独立
  CanvasLayer。
- UI 以键盘焦点为主要输入方式；方向键移动焦点，确认键执行，ESC 返回。
- `ActorStatsPanel`、`InventoryPanel`、`SkillPanel`、`EquipmentPanel` 与
  `EntryInfoPanel` 在 Battle、ESC 和后续界面中统一复用。
- ESC 菜单初期只包含背包、技能和 System，不包含 Message 页。
- ESC 使用顶部主页签，背包页再使用装备、消耗品、材料、其他分类页签；
  左侧固定显示属性和装备栏，焦点变化实时显示说明与属性预览。
- Message 使用独立 UI。
- Player 向 Enemy 所在格移动时立即请求战斗，不需要额外交互键。
- BattleManager 使用 RUNNING / WAITING_FOR_PLAYER 状态；Player ATB 满后
  战斗时间、Enemy ATB、冷却和持续效果计时全部冻结，直到玩家确认行动。
- 全局纯数值公式集中在 `scripts/shared/game_formulas.gd`；技能、物品、
  装备和敌人的具体数据仍由各自 `.tres` 定义。
- Main 只初始化和连接顶层系统，不承载具体战斗、楼层、背包或升级逻辑。

## 重建阶段

1. 数据层。
2. Player 与基础 Main。
3. Floor、Stair 和 Switch。
4. Enemy、Pickup、背包和装备。
5. 统一辅助 UI。
6. HUD、ESC 菜单和 Message UI。
7. Battle、升级和 Main 职责拆分。
8. 完整联调。
