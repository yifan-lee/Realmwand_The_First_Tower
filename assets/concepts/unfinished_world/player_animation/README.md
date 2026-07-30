# 未完成之界：主角动作素材

主角延续首版设计：粗黑线火柴人、空白圆形头部、胸口青蓝色碎片，
手持末端发出青光的断裂魔杖。

## 动作与方向

最终图集固定为 `13 列 × 4 行`：

- 行 0：向下。
- 行 1：向左。
- 行 2：向右。
- 行 3：向上。
- 列 0–3：`walk`，四帧循环。
- 列 4–7：`attack`，准备、蓄力、释放、收招。
- 列 8–9：`hurt`，受击、恢复。
- 列 10–12：`interact`，准备、伸手、碎片反馈。

## 输出

- `source/`：ImageGen 生成的纯绿背景动作表。
- `transparent/`：移除绿幕后保留原始分辨率的动作表。
- `frames_original/`：主体不重采样，使用 `400×400` 透明方形画布。
- `frames_256/`：每帧 `256×256`。
- `assets/sprites/player/unfinished_world_player_actions_original.png`：
  原始分辨率图集，每格 `400×400`。
- `assets/sprites/player/unfinished_world_player_actions_256.png`：
  中等分辨率图集，每格 `256×256`。
- `assets/sprites/player/unfinished_world_player_actions_32.png`：
  游戏原型图集，每格 `32×32`。
- `assets/sprites/player/unfinished_world_player_actions.json`：
  动作、方向、帧时长和图集坐标。

在 Godot 中导入时，按所选图集将 `Hframes` 设为 `13`、`Vframes`
设为 `4`。如果使用 `SpriteFrames`，可按 JSON 中每个动作的
`start_column` 与 `frame_count` 建立动画。

重新生成切帧和图集：

```bash
/Users/yifanli/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 \
  tools/build_player_animation_atlas.py \
  --preview-directory tmp/tests/<run>/screenshots
```
