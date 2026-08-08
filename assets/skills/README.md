# 技能图标素材

共 100 张高分辨率独立 PNG，统一使用 `343×343` 透明画布。

## 分类

- `physical/`：32 张物理攻击图标。
- `magic/`：48 张法术攻击图标。
- `support/`：20 张辅助法术图标。
- `source/`：ImageGen 生成的六张原始技能表。
- `transparent/`：移除分离背景后的原始分辨率技能表。
- `skills_manifest.json`：类别、技能族、等级、文件路径和源坐标。

## 等级

文件名统一使用 `<技能族>_tier_<等级>.png`。

- `tier_1`：基础。
- `tier_2`：强化。
- `tier_3`：精英。
- `tier_4`：传奇。

## 辅助法术颜色

- ATK：红色。
- DEF：黄色 / 金色。
- SPD：蓝色。
- HP：绿色。
- MP：紫色 / 青色。

## 重新切分

```bash
python3 tools/build_skill_icons.py
```
