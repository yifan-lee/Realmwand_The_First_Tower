# 未完成之界 32px 图集验证

### 自动检查

- 五张图集均为 RGBA PNG。
- 所有图集尺寸均为 `32×32` 的整数倍。
- 每个已登记坐标均包含非透明像素。
- 装备图集顶部右侧八个保留格均完全透明。
- 图集坐标、像素范围和源文件已写入 JSON 清单。

### 视觉检查

- 地形、装备、交互物、物品和怪物在 32px 下均可辨认。
- 没有发现相邻格内容污染。
- 装备属性色与武器类型保持正确。
- 怪物四种属性类型和四个等级梯度保持可辨。

### 测试结果

**通过**

### 证据

- `tmp/tests/run-20260728-222411/screenshots/unfinished_world_atlases_overview.png`
- `assets/tiles/unfinished_world_atlases_32.json`
