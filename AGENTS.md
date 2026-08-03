## 项目阶段

当前状态：**早期开发阶段** — 架构和设计快速迭代中，所有修改倾向于破坏性重构，不考虑历史兼容。

---

## 技术方向

详细规范见 [docs/dev_standards.md](./docs/dev_standards.md)，此处仅做方向性摘要：

- **数据驱动设计**：角色、技能、物品等核心数据用 `.tres`（Godot Resource）或 JSON 定义；运行时状态不得写回共享 Resource（→ dev_standards.md 六.4）
- **功能模块化**：每个功能模块独立目录，通过 EventBus（信号）解耦
- **命名规范**：文件/文件夹 `snake_case`，节点 `PascalCase`（→ dev_standards.md 一）
- **颜色规范**：分层管理 — Theme / Inspector / ColorPalette / GDScript 动态；脚本中颜色字面量必须用 `Color("#RRGGBBAA")`（→ dev_standards.md 六.5）
- **Git 管理**：`.godot/` 和 `.import/` 加入 `.gitignore`，大型二进制素材考虑 Git LFS（→ dev_standards.md 三）
- **中文编码**：项目自有文件中文统一使用 UTF-8（不含 BOM），第三方代码不受此约束（→ dev_standards.md 二）

---

## 开发规范（AI 必须遵守）

**所有规范细节的完整来源：[docs/dev_standards.md](./docs/dev_standards.md)**。

具体工作流程使用以下 Skills：

- **godot-mcp-setup** — 自动检测 Godot MCP Pro 是否可用，不可用时硬阻断拒绝执行 Godot 开发（首次 Godot 操作时触发）
- **godot-scene** — 场景创建/修改标准流程（通过 MCP 构建节点树、挂载脚本、连接信号）
- **godot-mvp-test** — 早期开发到 MVP 阶段的两段式验收流程（脚本化基础回归 + 当前目标测试）

核心原则：

1. **环境前置条件**：执行任何 Godot 开发任务前，必须先确保 Godot MCP Pro 工具链可用（参见 `godot-mcp-setup` skill）。不可用则拒绝开发，不降级。
2. **场景为根基**：所有功能从场景节点树出发设计，脚本只是节点上的附加行为。每个场景必须在 Godot 编辑器中可完整可视化。（→ dev_standards.md 四）
3. **通过 MCP 操作编辑器**：使用 Godot MCP Pro 创建/修改场景、节点、资源，**禁止直接手写 .tscn / .tres 文件**；但**在通过 MCP 修改任何 `.tscn` / `.tres` 文件后，AI 必须在回复中主动呈现 `git diff` 文本对比代码块**，以便用户检阅和确认。脚本（.gd）可以手写后通过 MCP 挂载。（→ dev_standards.md 五）
4. **可视化调参**：Shader 参数、材质属性在编辑器中可调节，Inspector 中暴露为 `@export` 变量。（→ dev_standards.md 六）
5. **可复用组件场景化**：可复用的动画、UI 组件做成独立场景（.tscn）。（→ dev_standards.md 七）
6. **破坏性重构**：早期开发阶段，不以兼容性为约束。需要改架构时直接改，不写迁移脚本、不做向后兼容层。（→ dev_standards.md 九）

---

## 测试、进度与 Push 门禁

完整流程见 [dev_standards.md 第十~十二章](./docs/dev_standards.md)。快速参考：

1. **两段式验收**：先脚本化基础回归（`python tools/run_basic_regression.py`），通过后才进入当前目标验证。
2. **基础回归失败**：不得继续宣称验收通过。本轮造成则修复，历史/环境问题则记录阻断。
3. **目标相关测试**：视觉类截图/录帧；交互类输入模拟+断言；逻辑类属性断言；数据类验证加载和引用。
4. **临时测试产物**：所有截图、录帧、临时报告只写入 `tmp/tests/run-YYYYMMDD-HHMMSS/` 下的 `screenshots/`、`frames/`、`reports/`。
5. **进度记录**：每次开发或验收后更新 `docs/progress/YYYY-MM-DD.md`（日期为当前 ISO 周的周一），必须包含 `### 更新时间`、`### 更新内容`、`### 测试结果`、`### 证据`。
6. **测试结果**必须包含 `通过`、`失败`、`阻断` 或 `未执行` 之一。
7. **Push 门禁**：`.githooks/pre-push` 自动运行基础回归 + 检查 progress 更新。两者任一失败则拒绝 push。
8. **Codex SessionStart**：仓库内 `.codex/hooks.json` 配置了 `SessionStart` hook，会话启动时自动检测并修复 `git config core.hooksPath .githooks`，同时检查 Python、Node.js 和所需脚本是否可用。
9. **跨机器**：`.codex/` 配置随仓库提交，克隆后无需手动设置 `core.hooksPath`。Codex 出于安全可能要求首次信任项目 hook。
10. **禁止绕过**：不得使用 `git push --no-verify` 绕过项目门禁。

---

## 参考项目

> 在此记录架构或设计上有参考价值的项目。

<!-- 示例：
- **Godot 官方 demo 项目** — Godot 4 项目组织最佳实践
- **crystal-bit/godot-game-template** — Godot 通用项目模板
-->

---

## 目录结构

```
project_root/
├── project.godot
├── .gitignore
├── AGENTS.md                        # 本文档（项目入口 + 导航）
├── .mcp.json                        # Godot MCP Pro 配置（安装脚本生成，不提交）
├── docs/                            # 设计文档
│   ├── todo.md                      # 待办清单
│   ├── dev_standards.md             # 开发规范（完整来源）
│   ├── game_design_document.md      # 游戏设计文档
│   └── progress/                    # 每周开发进度与测试结果
├── assets/                          # 原始素材
│   ├── sprites/                     # 图像素材
│   ├── audio/                       # 音频素材
│   └── fonts/                       # 字体
├── scenes/                          # Godot 场景 (.tscn)
│   └── ui/                          # 共享 UI 场景
├── scripts/                         # GDScript 脚本
│   ├── autoload/                    # Autoload 单例
│   └── shared/                      # 跨模块共享
├── resources/                       # Godot 资源 (.tres)
│   └── data/                        # 数据表
├── tools/                           # 脚本工具
├── addons/                          # 第三方插件
├── tests/                           # 长期维护的测试定义
└── tmp/                             # 本地临时产物（Git 忽略，保留目录结构）
```

---

## 文档导航

- [待办清单](./docs/todo.md)
- [开发规范](./docs/dev_standards.md)
- [游戏设计文档](./docs/game_design_document.md)

---

## Notes

<!-- 后续记录随手笔记、决策理由等 -->
