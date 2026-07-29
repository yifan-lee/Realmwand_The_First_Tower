# 数据驱动地图物件贴图专项验证

日期：2026-07-29

## 结果

通过。

## 验证内容

- 通用 Pickup 场景不再保存某个特定物品的默认数据或占位贴图。
- Floor1 的 BladeLV0 显式引用 `blade_lv0.tres`。
- BladeLV0 的 Sprite2D 贴图与 `item_data.icon` 为同一资源。
- SmallPotion 的 Sprite2D 贴图与 `item_data.icon` 为同一资源。
- `small_potion.tres` 已配置 `hp_tier_1.png` 图标。
- EnemyFirst 的 Sprite2D 贴图与 `enemy_data.portrait` 为同一资源。
- Enemy Sprite2D 取消旧图集分帧，并以 `0.125` 缩放显示 256px 数据贴图，
  最终占用约一个 32px 地图格。
- ItemData 或 EnemyData 资源自身发生变化时，已连接的地图实例会重新同步贴图。
- 停止场景后 Godot 编辑器错误数为 0。

## 证据

- 运行画面：
  `tmp/tests/run-20260729-120314/screenshots/data_driven_world_visuals.png`
- 基础回归：
  `tmp/tests/run-20260729-120314/reports/basic_regression.md`

