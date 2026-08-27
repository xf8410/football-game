# 📋 活动配置指南

本指南说明如何为足球游戏创建自定义活动（特殊规则比赛）。

## 活动格式

每个活动按照以下格式定义：

```
活动名称：
活动入口：
比赛人数：
玩家控制哪一方：
胜利条件：
失败条件：
比赛时长：
初始比分：
特殊规则：
AI 行为：
奖励或解锁：
是否支持单人：
是否支持局域网：
界面大概是什么样：
```

## 示例活动

### 1. 快速比赛（默认）

```yaml
活动名称: 快速比赛
活动入口: 主菜单 → 快速比赛
比赛人数: 11v11
玩家控制: 主队
胜利条件: 终场比分领先
失败条件: 终场比分落后
比赛时长: 6分钟（上下半场各3分钟游戏时间）
初始比分: 0:0
特殊规则: 无
AI行为: 正常
奖励: 无
支持单人: 是
支持局域网: 是
```

**代码配置：**
```gdscript
GameState.set_event({
    "name": "快速比赛",
    "type": "quick_match",
    "modifiers": {}
})
```

### 2. 最后五分钟

```yaml
活动名称: 最后五分钟
活动入口: 活动菜单 → 最后五分钟
比赛人数: 5v5
玩家控制: 主队
比赛从第85分钟开始
初始比分: 0:1
胜利条件: 终场前反超
失败条件: 打平或落后
特殊规则: 没有加时赛
AI行为: 客队领先后偏向防守和拖延时间
奖励: 首次获胜解锁困难难度
支持单人: 是
支持局域网: 是
```

**代码配置：**
```gdscript
GameState.set_event({
    "name": "最后五分钟",
    "type": "last_five_minutes",
    "modifiers": {
        "start_time": 85.0,           # 从第85分钟开始
        "initial_score": [0, 1],      # 0:1 落后
        "ai_defensive_mode": true,    # AI全力防守
        "no_extra_time": true,        # 没有加时赛
    }
})

# 解锁奖励
func on_win():
    SaveManager.unlock("difficulties", "hard")
```

### 3. 点球大战

```yaml
活动名称: 点球大战
活动入口: 活动菜单 → 点球大战
比赛人数: 1v1（仅罚球手和门将）
玩家控制: 罚球方
胜利条件: 5轮后进球多者胜
失败条件: 5轮后进球少者负
比赛时长: 无限时
初始比分: 0:0
特殊规则: 每人5轮，平局进入突然死亡法
AI行为: 门将随机扑救方向
奖励: 解锁传奇难度
支持单人: 是
支持局域网: 是
```

**代码配置：**
```gdscript
GameState.set_event({
    "name": "点球大战",
    "type": "penalty_shootout",
    "modifiers": {
        "penalties": true,
        "rounds": 5,
        "sudden_death": true,
    }
})
```

### 4. 多球乱战

```yaml
活动名称: 多球乱战
活动入口: 活动菜单 → 多球乱战
比赛人数: 11v11
玩家控制: 主队
胜利条件: 3分钟内进球最多
失败条件: 进球少于对手
比赛时长: 3分钟
初始比分: 0:0
特殊规则: 场上同时存在3个球
AI行为: 正常
奖励: 解锁特殊球衣
支持单人: 是
支持局域网: 是
```

**代码配置：**
```gdscript
GameState.set_event({
    "name": "多球乱战",
    "type": "multi_ball",
    "modifiers": {
        "multi_ball": true,
        "ball_count": 3,
        "half_duration": 90.0,
    }
})
```

### 5. 限制射门挑战

```yaml
活动名称: 限制射门挑战
活动入口: 活动菜单 → 限制射门挑战
比赛人数: 11v11
玩家控制: 主队
胜利条件: 终场比分领先
失败条件: 终场比分落后或平局
比赛时长: 6分钟
初始比分: 0:0
特殊规则: 每队最多射门5次
AI行为: 正常
奖励: 解锁新阵型
支持单人: 是
支持局域网: 是
```

**代码配置：**
```gdscript
GameState.set_event({
    "name": "限制射门挑战",
    "type": "limited_shots",
    "modifiers": {
        "max_shots": 5,
    }
})
```

## 活动修正参数一览

所有活动修正参数定义在 `game_state.gd` 的 `current_event.modifiers` 中：

| 参数 | 类型 | 说明 |
|------|------|------|
| `force_scorer` | int | 指定某球员（球衣号）必须进球 |
| `ai_no_enter_zones` | Array | AI不能进入的区域 `[{center: Vector3, radius: float}]` |
| `ai_defensive_mode` | bool | AI最后几分钟全力防守 |
| `max_shots` | int | 限制射门次数，-1为不限 |
| `multi_ball` | bool | 多球同时存在 |
| `ball_count` | int | 多球模式的球数量 |
| `extra_time` | bool | 淘汰赛加时 |
| `penalties` | bool | 点球大战 |
| `start_time` | float | 比赛从第几分钟开始 |
| `initial_score` | Array | 初始比分 `[主队分, 客队分]` |
| `no_extra_time` | bool | 没有加时赛 |
| `rounds` | int | 点球轮数 |
| `sudden_death` | bool | 突然死亡法 |

## 如何添加新活动

1. 在 `scripts/game_state.gd` 中添加活动类型枚举
2. 在 `scripts/main_menu.gd` 或新场景中添加活动入口
3. 配置活动修正参数
4. 在 `scripts/match.gd` 中处理特殊规则逻辑
5. 在 `scripts/player_ai.gd` 中处理AI行为修正
6. 测试并调整平衡性

## AI 行为分层说明

每个活动不需要重新写一套AI，而是在基础AI上增加参数：

```
基础AI（球员AI + 球队战术）
        │
        ▼
活动修正层（覆盖/调整基础AI参数）
        │
        ▼
最终AI行为
```

例如「最后五分钟」活动：
- 基础AI：客队正常防守
- 活动修正：`ai_defensive_mode = true`
- 最终行为：客队所有球员退守，减少前压，增加传球拖延时间
