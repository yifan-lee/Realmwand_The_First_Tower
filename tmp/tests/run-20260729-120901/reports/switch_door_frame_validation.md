# Switch / Door 图集帧验证

- 验证时间：2026-07-29 12:12 EDT
- 测试结果：通过

## Switch

- 初始状态：`frame_coords = (0, 3)`
- 激活状态：`frame_coords = (1, 3)`
- 恢复状态：`frame_coords = (0, 3)`
- 独立场景视觉检查通过。

## Door

- 关闭状态：`frame_coords = (0, 2)`、Sprite 可见、碰撞启用。
- 开启状态：`frame_coords = (1, 2)`、Sprite 可见、碰撞禁用。
- 再次关闭后：恢复 `(0, 2)`，碰撞重新启用。
- 独立场景视觉检查通过。

## 编辑器状态

- 测试场景停止后 Godot 编辑器错误数：0

## 截图

- `screenshots/switch_inactive.png`
- `screenshots/switch_active.png`
- `screenshots/door_closed.png`
- `screenshots/door_open.png`
