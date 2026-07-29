# 开关图集切换专项验证

日期：2026-07-29

## 结果

通过。

## 图集坐标核对

- 图集：`res://assets/tiles/unfinished_world_tiles_32.png`
- 图片尺寸：`160×128`
- 单格尺寸：`32×32`
- 网格尺寸：`5×4`
- `mechanism_off`：`Vector2i(2, 3)`
- `mechanism_on`：`Vector2i(3, 3)`

用户提供的 `(0,4)`、`(1,4)` 超出该图集的有效 Y 坐标范围，因此采用
图集中实际的关闭、开启机关图块。

## 验证内容

- `switch.tscn` 的 Sprite2D 使用目标图集。
- Sprite2D 配置为 5 个横向帧、4 个纵向帧、1 倍缩放。
- 未激活状态显示 `(2,3)`。
- Player 的 InteractionRay 实际命中 Floor2 的 Switch。
- 第一次发送 `interact` 后，`is_active == true` 且帧坐标为 `(3,3)`。
- 第二次发送 `interact` 后，`is_active == false` 且帧坐标恢复为 `(2,3)`。
- 停止场景后 Godot 编辑器错误数为 0。

## 证据

- 未激活截图：`tmp/tests/run-20260729-113800/screenshots/switch_inactive.png`
- 激活截图：`tmp/tests/run-20260729-113800/screenshots/switch_active.png`
- 基础回归：
  `tmp/tests/run-20260729-113736/reports/basic_regression.md`

