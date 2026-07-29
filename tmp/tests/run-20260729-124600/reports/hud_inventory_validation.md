# HUD 与追踪物品验证

### 测试结果

- **通过**：启动界面使用 `CombatantStatusPanel` 显示玩家头像、HP、MP、
  ATK、DEF 和 SPD。
- **通过**：空背包显示 `No tracked items`，布局位于角色状态面板下方。
- **通过**：运行时加入 2 个 `show_count_in_hud = true` 的
  `Small Potion` 和 1 个未开启该属性的 `Blade LV0` 后，背包总数为 3，
  追踪列表只有 1 行。
- **通过**：屏幕断言匹配 `Small Potion` 与 `×2`。
- **通过**：消耗一个 `Small Potion` 后，屏幕计数立即更新为 `×1`。

### 证据

- 基础回归：`tmp/tests/run-20260729-125121/reports/basic_regression.md`
- 初始 HUD：
  `tmp/tests/run-20260729-124410/screenshots/main_scene.png`
- 消耗后 HUD：
  `tmp/tests/run-20260729-124600/screenshots/tracked_item_after_consume.png`
- 运行时查询：`tracked_rows=1 inventory=3`
