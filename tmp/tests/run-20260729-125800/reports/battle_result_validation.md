# Battle Result Validation

### 测试结果

- **通过**：胜利时只显示结果面板、敌人名称、EXP、Gold 和继续提示。
- **通过**：胜利结果等待期间按下空格后关闭战斗，并移除已击败敌人。
- **通过**：战败时只显示战败信息和继续提示。
- **通过**：战败结果等待期间按下回车后关闭战斗。
- **通过**：战败后玩家 HP、MP、背包物品数量和位置恢复至遭遇前。
- **通过**：战败后敌人位置恢复，遭遇标记和碰撞监测重新启用。
- **通过**：将结果计时器临时设为 0.25 秒后，不输入按键也会自动关闭战斗。

### 运行时断言

```text
victory:
result_pending=true
panel=true
title=Victory
EXP=3
Gold=1
battle_closed=true
enemy_removed=true

defeat rollback:
hp=true
mp=true
items=true
player_position=true
enemy_position=true
battle_closed=true
enemy_rearmed=true

timeout:
auto_closed=true
battle_children=0
```

### 截图

- `screenshots/victory_result.png`
- `screenshots/defeat_result.png`
