# 开发规范

## 命名与编码

- 文件和目录使用 `snake_case`。
- Godot 节点使用 `PascalCase`。
- 项目自有文本使用 UTF-8，不带 BOM。

## 场景优先

- 固定节点树、地图、UI 布局、碰撞、基础视觉和 Inspector 参数放在
  `.tscn` 或 `.tres` 中。
- GDScript 只负责运行时输入、规则、状态变化、信号和动态决策。
- 禁止在 `_ready()` 中用代码搭建固定界面或固定场景结构。
- 可复用 Actor、交互物、UI 和视觉效果建立为独立场景。
- `.tscn` 和 `.tres` 必须通过 Godot MCP Pro 创建、修改和检查；在修改后必须主动通过 `git diff` 呈现该文件的文本对比代码块以供检阅。

## 数据与运行时状态

- Player、Enemy、Item、Equipment 和 Skill 的共享定义使用类型化
  Resource。
- 运行时 HP、MP、等级、背包、装备、冷却和楼层状态不得写回共享
  `.tres`。
- `EquipmentData` 继承 `ItemData`，通用 Pickup 接受 `ItemData`。

## 模块边界

- FloorManager 负责楼层生命周期。
- BattleManager 负责战斗生命周期。
- UI 只展示 ViewData 并发出用户选择，不直接拥有玩法状态。
- 模块优先通过信号解耦，禁止依赖绝对场景路径调用其他系统。

## 颜色

- 固定 UI 颜色和字体放入 Theme 或 Inspector。
- 固定世界视觉放入场景或材质。
- GDScript 颜色字面量仅用于运行时动态反馈，并使用
  `Color("#RRGGBBAA")`。

## 测试

- 每次开发改动先运行 `python3 tools/run_basic_regression.py`。
- 基础回归通过后，再进行当前目标的运行时、交互、逻辑或视觉验收。
- 临时证据只写入 `tmp/tests/run-YYYYMMDD-HHMMSS/`。
- 每次开发或验收更新当前 ISO 周一对应的 `docs/progress/YYYY-MM-DD.md`。
