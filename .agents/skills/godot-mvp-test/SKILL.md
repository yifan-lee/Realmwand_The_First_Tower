---
name: godot-mvp-test
description: Godot early-development-to-MVP validation workflow. Use when an AI agent finishes or reviews any Godot project change and must run project-level basic regression first, then validate the current user goal with MCP-driven runtime, visual, interaction, logic, or data checks, update progress records, and respect push gates.
---

# Godot MVP Test

Use this skill after any Godot project change, before reporting completion or preparing a push.

## Required Order

1. Ensure `godot-mcp-setup` has passed before any Godot editor, scene, script, resource, or runtime validation.
2. Run the project-level basic regression script:
   ```bash
   python tools/run_basic_regression.py
   ```
3. If basic regression fails, stop current-goal validation. Fix failures caused by this session and rerun. If the failure appears historical or environmental, report it as blocked.
4. If basic regression passes, validate the current user goal with the smallest reliable checks that prove the requested behavior.
5. Update the current weekly progress file under `docs/progress/` with update content, test result, and evidence paths.

## Basic Regression

Do not maintain a regression checklist document. The source of truth is `tools/run_basic_regression.py`.

The first version covers:

- `BR-001` Godot MCP Pro is reachable through project info.
- `BR-002` Project metadata is readable: project name, Godot version, main scene.
- `BR-003` The editor reports zero errors before play.
- `BR-004` The main scene starts.
- `BR-005` A running-game screenshot is captured.
- `BR-006` The runtime scene tree is readable.
- `BR-007` MCP autoloads exist: `MCPGameInspector`, `MCPInputService`, `MCPScreenshot`.
- `BR-008` The scene stops cleanly and leaves zero editor errors.

The script writes temporary evidence to `tmp/tests/run-YYYYMMDD-HHMMSS/`. Treat a nonzero exit code as a hard failure.

## Current Goal Validation

Classify the user goal and actual changes, then select checks:

- Visual changes: UI layout, scene composition, sprites, camera, shader, material, animation, particles, or other visible output require screenshots or frame capture.
- Interaction changes: simulate actions, keys, mouse clicks, or UI button clicks; assert the expected node, UI, or state result.
- Logic changes: assert runtime node properties, autoload state, signal effects, or scripted results.
- Data changes: verify resource or JSON loading, required fields, resource paths, and relevant runtime state.
- Infrastructure changes: verify the script, hook, config, or documentation behavior directly.

For visual checks, first self-check capability:

- If the agent can capture and inspect images, it must inspect the screenshot or frames and fix visible mismatches before passing.
- If the agent can capture but cannot inspect images, it must save evidence and report `视觉验收未完成`; it must not mark visual validation as passed.
- If screenshots cannot be captured, treat the visual validation as failed or blocked.

## Temporary Files

Write all test run artifacts to `tmp/tests/`, never to stable `tests/` paths.

Use this structure:

- `tmp/tests/run-YYYYMMDD-HHMMSS/screenshots/`
- `tmp/tests/run-YYYYMMDD-HHMMSS/frames/`
- `tmp/tests/run-YYYYMMDD-HHMMSS/reports/`

The `tmp/` tree is ignored by Git except `.gitkeep` placeholders.

## Progress Record

After validation, update the weekly progress file:

- Path: `docs/progress/YYYY-MM-DD.md`
- The date is the ISO-week Monday for the current local date.
- Each entry must include:
  - `### 更新时间`
  - `### 更新内容`
  - `### 测试结果`
  - `### 证据`
- `### 测试结果` must include one of: `通过`, `失败`, `阻断`, `未执行`.
- If tests are not run, use `未执行` and state why.

## Push Gate

Before push, `.githooks/pre-push` automatically runs basic regression and then checks progress updates.

Push is refused if:

- Basic regression fails.
- The pushed commits do not update `docs/progress/*.md`.
- The progress update lacks `### 测试结果`.
- The progress update lacks one of `通过`, `失败`, `阻断`, `未执行`.

Do not use `--no-verify` to bypass this gate.
