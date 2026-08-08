# 项目代码介绍


## main

### main.tscn

- World 节点：包含了玩家、层级结构（如 Layer_1）等游戏世界相关的内容。
    - FloorContainer：负责地图的加载
    - Player：玩家
- Systems 节点：
    - FloorManager：负责楼层切换
    - BattleManager：战斗管理
    - LevelUpManager：升级管理
- OverlayRoot 节点：包含了 UI 相关的元素。
    - GameHUD：游戏主界面 UI
    - EscMenu：暂停菜单
    - BattleUI：战斗界面 UI
    - LevelUpUI：升级界面 UI


### main.gd

#### _init

- 加载 World/Player<span style="color: red;">注意</span>
- 加载 OverlayRoot/GameHUD<span style="color: red;">注意</span>
- 加载 OverlayRoot/EscMenu<span style="color: red;">注意</span>
- 加载 OverlayRoot/BattleUI<span style="color: red;">注意</span>
- 加载 OverlayRoot/LevelUpUI<span style="color: red;">注意</span>
- 加载 Systems/BattleManager<span style="color: red;">注意</span>
- 加载 Systems/LevelUpManager<span style="color: red;">注意</span>


#### _ready

- 用game_hud.bind_player把Player绑定到game_hud<span style="color: red;">注意</span>
- 用esc_menu.bind_player把Player绑定到esc_menu<span style="color: red;">注意</span>
- 用battle_manager.setup建和参数player，battle_ui设立battle_manager<span style="color: red;">注意</span>
- 用level_up_manager.setup建和参数player，level_up_ui设立level_up_manager<span style="color: red;">注意</span>
- 监听battle_manager.battle_finished信号，并且执行_on_battle_finished

#### _unhandled_input

如果按键是eas就打开菜单


#### other

_on_battle_finished：显示战斗结束了



## Player

### Player.tscn

- CharacterBody2D：绑定player.gd
    - AnimatedSprite2D
    - CollisionShape2D
    - InteractionRay
    - Camera2D
    - Inventory：绑定inventory.gd<span style="color: red;">注意</span>
    - Equipment：绑定quipment_loadout.gd<span style="color: red;">注意</span>

### Player.gd

#### _init

- 发出信号 movement_finished
- 发出信号 stats_changed
- 发出信号 level_up_available
- 增加PlayerData变量
- 增加grid_size参数
- 增加move_duration参数
- 加载 AnimatedSprite2D
- 加载 InteractionRay
- 加载 Inventory
- 加载 Equipment


#### _ready


##### _initialize_runtime_state

获得在tscn界面填写的PlayerData，并且初始化player的一些参数。

其中初始话装备的时候会调用inventory.add_item(starting_item)来检查物品也没有超出数量。<span style="color: red;">注意</span>


##### _apply_data_visuals

获取player的sprite_frames，并且调用_play_directional_animation播放起始动画


##### _update_interaction_ray

根据当前的facing_direction，更新探针方向

#### _unhandled_input

如果输入是inter

#### Other

##### _play_directional_animation(action)

根据action和_get_direction_suffix得到的移动方向字符串来播放动画



##### _get_direction_suffix

根据当前的facing_direction，获得移动方向的字符串



## Data

### ActorData

玩家和敌人的母类，拥有以下属性：
- id
- display_name
- description
- max_hp
- max_mp
- max_fp
- fp_recovery_spd
- atk
- def
- spd
- portrait


### PlayerData

继承ActorData，额外拥有以下属性
- sprite_frames
- starting_level
- starting_experience
- starting_gold
- starting_items
- starting_skills