# 游戏架构规划

## 当前状态

当前为从零重建基线。只有最小 `main.tscn` 和开发目录骨架。

第 1 块及后续功能默认由项目作者亲自实现；AI 只提供逐步教学、检查和
诊断，除非作者明确要求 AI 代为修改。

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
└── GameOverlay
    ├── HudLayer
    ├── MenuLayer
    ├── BattleLayer
    └── MessageLayer
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
- ESC 菜单初期只包含背包、技能和 System，不包含 Message 页。
- Message 使用独立 UI。
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
