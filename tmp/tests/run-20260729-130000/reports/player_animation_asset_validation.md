# 主角动作素材验证

### 测试结果

- **通过**：四张 ImageGen 动作源表均成功移除纯绿背景，输出 RGBA
  透明 PNG。
- **通过**：按下、左、右、上四个方向切出移动 16 帧、攻击 16 帧、
  受击 8 帧、交互 12 帧，共 52 帧。
- **通过**：`frames_original/` 与 `frames_256/` 均包含 52 张非空正方形
  PNG。
- **通过**：原始、256px 和 32px 三种图集均为严格 `13×4` 网格，
  52 个格子全部非空。
- **通过**：三种图集所有格子的透明边缘均未被前景像素触碰，不会在
  Godot 自动切割时混入相邻帧。
- **通过**：32px 放大预览中四方向、攻击释放、红色受击反馈和青色
  交互反馈均可辨认。
- **通过**：项目基础回归 8/8，Godot 导入新素材后主场景正常启动并
  干净停止。

### 证据

- 图集预览：
  `tmp/tests/run-20260729-130000/screenshots/unfinished_world_player_actions_32_preview.png`
- 图集清单：
  `assets/sprites/player/unfinished_world_player_actions.json`
- 基础回归：
  `tmp/tests/run-20260729-213522/reports/basic_regression.md`
