# 楼层切换专项验证

日期：2026-07-29

## 结果

通过。

## 验证内容

- Main 启动时由 FloorManager 加载 Floor1，并将玩家放到 `GameStart`。
- 从 Floor1 的 `Upstairs` 进入 Floor2 的 `FromFloor1Stairs`。
- 玩家到达 Floor2 的 `(0, 32)`，即使落点与 `Downstairs` 重合，也不会立刻返回。
- 落点楼梯保持未启用且记录玩家为受抑制对象。
- 玩家向上离开楼梯后，`Downstairs` 自动重新启用。
- 玩家再次向下进入楼梯后，返回 Floor1 的 `FromFloor2Stairs`。
- 返回 Floor1 后不会立刻再次上楼。
- 切换前移除的 `enemy_01` 仍然不存在。
- 切换前激活并锁定的 `switch_01` 保持激活和锁定。
- FloorManager 同时保留 Floor1 与 Floor2 的运行时状态。
- 测试结束后 Godot 编辑器错误数为 0。

## 证据

- Floor2 到达截图：`screenshots/floor_2_arrival.png`
- 基础回归报告：
  `tmp/tests/run-20260729-110041/reports/basic_regression.md`
