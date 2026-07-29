---
name: godot-mcp-setup
description: 本 session 中首次执行 Godot 相关操作（创建/修改 .tscn、.gd 文件等）时自动触发。检测 Godot MCP Pro 是否可用，不可用时运行安装脚本，失败则硬阻断所有 Godot 开发直到手动恢复。
---

# Godot MCP Pro — 自动检测与安装

> **触发时机**：本 session 中第一次执行 Godot 相关开发任务时（创建/修改 `.tscn`、`.gd`、`.tres` 等文件，或运行 Godot 场景）。
> **不可用 = 拒绝开发，不降级，不回退。**

---

## 一、触发条件

本 Skill 在以下任一情况首次发生时自动触发：

- 创建或修改 `.tscn` 场景文件
- 创建或修改 `.gd` 脚本文件
- 创建或修改 `.tres` 资源文件
- 调用任何 Godot MCP 工具（`play_scene`、`get_scene_tree`、`create_scene` 等）

**仅触发一次**：本 session 中检测通过后不再重复检测。

---

## 二、检测流程

### Step 1 — 快速连通性检查

尝试调用一个轻量 MCP 工具（如 `get_project_info`）：

- **成功** → 跳到 Step 4，记录"已检测通过"，本 session 不再重复检测
- **失败** → 继续 Step 2

### Step 2 — 运行安装脚本

检测当前操作系统，运行与本 SKILL.md 同目录下的 `scripts/` 中的对应脚本：

| 操作系统 | 脚本 |
|----------|------|
| **Windows** | `{SKILL_DIR}/scripts/setup_godot_mcp.ps1` |
| **macOS / Linux** | `{SKILL_DIR}/scripts/setup_godot_mcp.sh` |

> `{SKILL_DIR}` = 本 SKILL.md 文件所在的目录（`.reasonix/skills/godot-mcp-setup` / `.claude/skills/godot-mcp-setup` / `.agents/skills/godot-mcp-setup`，取决于当前客户端）。先 `ls` 确认 SKILL.md 的实际路径，再据此拼接脚本路径。

脚本会自动完成：Node.js 检查 → Server 校验 + 构建 → doctor 验证 → 生成 `.mcp.json`

### Step 3 — 重试连接

脚本执行成功后，再次尝试调用 MCP 工具（`get_project_info`）：

- **成功** → 继续 Step 4
- **失败** → **硬阻断**，输出以下信息并拒绝所有 Godot 操作：

```
❌ Godot MCP Pro 仍然不可用。请确认：

  1. Godot 编辑器已打开
  2. 插件已启用：Project → Project Settings → Plugins → Godot MCP Pro → Enable
  3. 编辑器底部面板显示 "MCP Pro" 且状态为绿色连接点

  如果插件未启用：启用后无需重启 AI 会话
  如果连接点非绿色：重启 AI 会话以重新建立 MCP 连接

  在问题解决之前，我将拒绝执行任何 Godot 相关操作。
```

### Step 4 — 通行

记录 session 状态：MCP 已可用。后续所有 Godot 操作正常执行。

---

## 三、阻断规则

检测未通过（Step 3 失败）时：

- **拒绝**所有 `.tscn` / `.gd` / `.tres` 文件的创建和修改
- **拒绝**所有 Godot MCP 工具调用
- 仅允许告知用户问题原因和修复步骤

阻断持续到用户确认问题已解决，AI 重新触发 Step 1 检测通过为止。

---

## 四、约定路径

| 内容 | 路径（相对于项目根目录） |
|------|-------------------------|
| Godot 插件 | `addons/godot_mcp/`（已提交 Git） |
| Server（付费包） | `resources/godot-mcp-pro-server/`（Git 排除） |
| MCP 配置 | `.mcp.json`（脚本自动生成） |
| 安装脚本 | `{SKILL_DIR}/scripts/setup_godot_mcp.sh` / `.ps1` |

---

## 五、安装脚本参考

脚本位于本 Skill 目录的 `scripts/` 子目录下，两个脚本功能一致：

| 平台 | 脚本 |
|------|------|
| Unix / macOS / Git Bash | `setup_godot_mcp.sh` |
| Windows PowerShell | `setup_godot_mcp.ps1` |

四步流程：Node.js 版本检查 → Server 校验 + 构建 → doctor 验证 → 自动生成 `.mcp.json`
