## game_state.gd
## 全局游戏状态管理器 (Autoload Singleton)
## 管理比赛配置、当前活动、AI难度等跨场景状态
extends Node

# ---- 比赛状态枚举 ----
enum MatchPhase {
        KICKOFF,       # 开球
        PLAYING,       # 比赛中
        BALL_OUT,      # 球出界
        GOAL,          # 进球后重置
        HALFTIME,      # 半场休息
        FULLTIME,      # 比赛结束
        PAUSED         # 暂停
}

# ---- AI 难度等级 ----
enum AIDifficulty {
        EASY,      # 简单：反应慢、传球失误多、不逼抢
        NORMAL,    # 普通：正常反应、偶尔逼抢
        HARD,      # 困难：快速反应、积极逼抢、战术多变
        LEGEND     # 传奇：极快反应、完美站位、高压逼抢
}

# ---- 球队枚举 ----
enum TeamSide {
        HOME,   # 主队（玩家默认控制）
        AWAY    # 客队
}

# ---- 当前比赛配置 ----
var current_match_config: Dictionary = {
        "home_team_name": "红队",
        "away_team_name": "蓝队",
        "home_color": Color(0.9, 0.15, 0.15),
        "away_color": Color(0.15, 0.3, 0.9),
        "formation": "4-4-2",
        "difficulty": AIDifficulty.NORMAL,
        "half_duration": 180.0,     # 每半场游戏内秒数（3分钟=180秒，全场6分钟）
        "player_controls": TeamSide.HOME,
        "initial_score": [0, 0],
}

# ---- 当前活动配置 ----
var current_event: Dictionary = {
        "name": "快速比赛",
        "type": "quick_match",
        # 活动修正参数（参考三层AI架构中的"活动修正"层）
        "modifiers": {
                "force_scorer": null,        # 指定某球员必须进球
                "ai_no_enter_zones": [],     # AI不能进入的区域
                "ai_defensive_mode": false,  # AI最后几分钟全力防守
                "max_shots": -1,             # 限制射门次数，-1为不限
                "multi_ball": false,         # 多球同时存在
                "extra_time": false,         # 淘汰赛加时
                "penalties": false,          # 点球大战
        }
}

# ---- 球场尺寸（米，标准 FIFA 尺寸）----
const FIELD_LENGTH: float = 105.0   # 球场长度
const FIELD_WIDTH: float = 68.0     # 球场宽度
const GOAL_WIDTH: float = 7.32      # 球门宽度
const GOAL_HEIGHT: float = 2.44     # 球门高度
const PENALTY_AREA_DEPTH: float = 16.5
const PENALTY_AREA_WIDTH: float = 40.3

# ---- 阵型定义 ----
# 坐标系：球场中心为原点，主队球门在 -Z 方向，客队球门在 +Z 方向
# X = 左右（-34 到 +34），Z = 前后（-52.5 到 +52.5）
const FORMATIONS: Dictionary = {
        "4-4-2": [
                # [角色, X, Z]  角色说明：GK=门将, CB=中后卫, LB/RB=边后卫, CM=中场, LM/RM=边前卫, ST=前锋
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0],
                ["CB", -8.0, -35.0],
                ["CB", 8.0, -35.0],
                ["RB", 22.0, -32.0],
                ["LM", -22.0, -12.0],
                ["CM", -8.0, -15.0],
                ["CM", 8.0, -15.0],
                ["RM", 22.0, -12.0],
                ["ST", -8.0, 8.0],
                ["ST", 8.0, 8.0],
        ],
        "4-3-3": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0],
                ["CB", -8.0, -35.0],
                ["CB", 8.0, -35.0],
                ["RB", 22.0, -32.0],
                ["CM", -12.0, -15.0],
                ["CM", 0.0, -18.0],
                ["CM", 12.0, -15.0],
                ["LW", -18.0, 10.0],
                ["ST", 0.0, 12.0],
                ["RW", 18.0, 10.0],
        ],
        "3-5-2": [
                ["GK", 0.0, -48.0],
                ["CB", -15.0, -35.0],
                ["CB", 0.0, -37.0],
                ["CB", 15.0, -35.0],
                ["LM", -28.0, -10.0],
                ["CM", -12.0, -15.0],
                ["CM", 0.0, -18.0],
                ["CM", 12.0, -15.0],
                ["RM", 28.0, -10.0],
                ["ST", -8.0, 8.0],
                ["ST", 8.0, 8.0],
        ],
        "4-2-3-1": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0],
                ["CB", -8.0, -35.0],
                ["CB", 8.0, -35.0],
                ["RB", 22.0, -32.0],
                ["CDM", -10.0, -22.0],
                ["CDM", 10.0, -22.0],
                ["LW", -18.0, 5.0],
                ["CAM", 0.0, 0.0],
                ["RW", 18.0, 5.0],
                ["ST", 0.0, 15.0],
        ],
        "5-3-2": [
                ["GK", 0.0, -48.0],
                ["LB", -25.0, -30.0],
                ["CB", -12.0, -35.0],
                ["CB", 0.0, -37.0],
                ["CB", 12.0, -35.0],
                ["RB", 25.0, -30.0],
                ["CM", -15.0, -12.0],
                ["CM", 0.0, -15.0],
                ["CM", 15.0, -12.0],
                ["ST", -8.0, 8.0],
                ["ST", 8.0, 8.0],
        ],
        "4-1-4-1": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0],
                ["CB", -8.0, -35.0],
                ["CB", 8.0, -35.0],
                ["RB", 22.0, -32.0],
                ["CDM", 0.0, -22.0],
                ["LM", -20.0, -5.0],
                ["CM", -7.0, -8.0],
                ["CM", 7.0, -8.0],
                ["RM", 20.0, -5.0],
                ["ST", 0.0, 12.0],
        ],
        "4-4-1-1": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["LM", -22.0, -12.0], ["CM", -8.0, -15.0], ["CM", 8.0, -15.0], ["RM", 22.0, -12.0],
                ["CF", 0.0, 5.0], ["ST", 0.0, 15.0],
        ],
        "4-3-2-1": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CM", -12.0, -18.0], ["CM", 0.0, -20.0], ["CM", 12.0, -18.0],
                ["CAM", -10.0, 2.0], ["CAM", 10.0, 2.0],
                ["ST", 0.0, 14.0],
        ],
        "4-3-1-2": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CM", -12.0, -18.0], ["CM", 0.0, -20.0], ["CM", 12.0, -18.0],
                ["CAM", 0.0, 0.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "4-2-2-2": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CDM", -10.0, -22.0], ["CDM", 10.0, -22.0],
                ["CAM", -15.0, -5.0], ["CAM", 15.0, -5.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "4-1-3-2": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CDM", 0.0, -22.0],
                ["CM", -15.0, -8.0], ["CM", 0.0, -10.0], ["CM", 15.0, -8.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "3-4-3": [
                ["GK", 0.0, -48.0],
                ["CB", -15.0, -35.0], ["CB", 0.0, -37.0], ["CB", 15.0, -35.0],
                ["LM", -25.0, -12.0], ["CM", -8.0, -15.0], ["CM", 8.0, -15.0], ["RM", 25.0, -12.0],
                ["LW", -18.0, 10.0], ["ST", 0.0, 14.0], ["RW", 18.0, 10.0],
        ],
        "3-4-1-2": [
                ["GK", 0.0, -48.0],
                ["CB", -15.0, -35.0], ["CB", 0.0, -37.0], ["CB", 15.0, -35.0],
                ["LM", -25.0, -12.0], ["CM", -8.0, -15.0], ["CM", 8.0, -15.0], ["RM", 25.0, -12.0],
                ["CAM", 0.0, 0.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "3-4-2-1": [
                ["GK", 0.0, -48.0],
                ["CB", -15.0, -35.0], ["CB", 0.0, -37.0], ["CB", 15.0, -35.0],
                ["LM", -25.0, -12.0], ["CM", -8.0, -15.0], ["CM", 8.0, -15.0], ["RM", 25.0, -12.0],
                ["CAM", -10.0, 2.0], ["CAM", 10.0, 2.0],
                ["ST", 0.0, 14.0],
        ],
        "3-1-4-2": [
                ["GK", 0.0, -48.0],
                ["CB", -15.0, -35.0], ["CB", 0.0, -37.0], ["CB", 15.0, -35.0],
                ["CDM", 0.0, -22.0],
                ["LM", -22.0, -5.0], ["CM", -8.0, -8.0], ["CM", 8.0, -8.0], ["RM", 22.0, -5.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "5-4-1": [
                ["GK", 0.0, -48.0],
                ["LB", -25.0, -30.0], ["CB", -12.0, -35.0], ["CB", 0.0, -37.0], ["CB", 12.0, -35.0], ["RB", 25.0, -30.0],
                ["LM", -20.0, -8.0], ["CM", -7.0, -12.0], ["CM", 7.0, -12.0], ["RM", 20.0, -8.0],
                ["ST", 0.0, 12.0],
        ],
        "5-2-1-2": [
                ["GK", 0.0, -48.0],
                ["LB", -25.0, -30.0], ["CB", -12.0, -35.0], ["CB", 0.0, -37.0], ["CB", 12.0, -35.0], ["RB", 25.0, -30.0],
                ["CM", -10.0, -15.0], ["CM", 10.0, -15.0],
                ["CAM", 0.0, 0.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "5-2-3": [
                ["GK", 0.0, -48.0],
                ["LB", -25.0, -30.0], ["CB", -12.0, -35.0], ["CB", 0.0, -37.0], ["CB", 12.0, -35.0], ["RB", 25.0, -30.0],
                ["CM", -10.0, -15.0], ["CM", 10.0, -15.0],
                ["LW", -18.0, 10.0], ["ST", 0.0, 14.0], ["RW", 18.0, 10.0],
        ],
        "4-5-1": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["LM", -25.0, -8.0], ["CM", -15.0, -12.0], ["CM", -5.0, -15.0], ["CM", 5.0, -15.0], ["RM", 25.0, -8.0],
                ["ST", 0.0, 12.0],
        ],
        "4-1-2-1-2": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CDM", 0.0, -22.0],
                ["CM", -12.0, -12.0], ["CM", 12.0, -12.0],
                ["CAM", 0.0, 0.0],
                ["ST", -8.0, 12.0], ["ST", 8.0, 12.0],
        ],
        "4-1-2-3": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CDM", 0.0, -22.0],
                ["CM", -12.0, -12.0], ["CM", 12.0, -12.0],
                ["LW", -18.0, 8.0], ["ST", 0.0, 12.0], ["RW", 18.0, 8.0],
        ],
        "2-3-5": [
                ["GK", 0.0, -48.0],
                ["CB", -10.0, -35.0], ["CB", 10.0, -35.0],
                ["LM", -22.0, -15.0], ["CM", 0.0, -18.0], ["RM", 22.0, -15.0],
                ["LW", -25.0, 8.0], ["ST", -10.0, 12.0], ["ST", 0.0, 14.0], ["ST", 10.0, 12.0], ["RW", 25.0, 8.0],
        ],
        "4-2-4": [
                ["GK", 0.0, -48.0],
                ["LB", -22.0, -32.0], ["CB", -8.0, -35.0], ["CB", 8.0, -35.0], ["RB", 22.0, -32.0],
                ["CM", -12.0, -15.0], ["CM", 12.0, -15.0],
                ["LW", -20.0, 8.0], ["ST", -7.0, 14.0], ["ST", 7.0, 14.0], ["RW", 20.0, 8.0],
        ],
        "3-5-1-1": [
                ["GK", 0.0, -48.0],
                ["CB", -15.0, -35.0], ["CB", 0.0, -37.0], ["CB", 15.0, -35.0],
                ["LM", -28.0, -10.0], ["CM", -12.0, -15.0], ["CDM", 0.0, -22.0], ["CM", 12.0, -15.0], ["RM", 28.0, -10.0],
                ["CAM", 0.0, 2.0],
                ["ST", 0.0, 14.0],
        ],
}

# ---- AI 难度参数表 ----
const AI_PARAMS: Dictionary = {
        AIDifficulty.EASY: {
                "reaction_time": 0.6,       # AI反应时间（秒）
                "pass_accuracy": 0.65,      # 传球准确率
                "shot_accuracy": 0.45,      # 射门准确率
                "chase_speed_mult": 0.85,   # 追球速度倍率
                "press_intensity": 0.3,     # 逼抢强度
                "tackle_success": 0.5,      # 抢断成功率
                "formation_discipline": 0.5,# 阵型纪律
        },
        AIDifficulty.NORMAL: {
                "reaction_time": 0.35,
                "pass_accuracy": 0.80,
                "shot_accuracy": 0.65,
                "chase_speed_mult": 0.95,
                "press_intensity": 0.6,
                "tackle_success": 0.65,
                "formation_discipline": 0.7,
        },
        AIDifficulty.HARD: {
                "reaction_time": 0.18,
                "pass_accuracy": 0.90,
                "shot_accuracy": 0.78,
                "chase_speed_mult": 1.0,
                "press_intensity": 0.85,
                "tackle_success": 0.78,
                "formation_discipline": 0.85,
        },
        AIDifficulty.LEGEND: {
                "reaction_time": 0.08,
                "pass_accuracy": 0.96,
                "shot_accuracy": 0.88,
                "chase_speed_mult": 1.05,
                "press_intensity": 1.0,
                "tackle_success": 0.88,
                "formation_discipline": 0.95,
        },
}

# ---- 球员基础属性 ----
const BASE_PLAYER_STATS: Dictionary = {
        "speed": 7.0,          # 最大移动速度（米/秒）
        "acceleration": 25.0,  # 加速度
        "pass_power": 18.0,    # 传球力度
        "shot_power": 25.0,    # 射门力度
        "stamina": 100.0,      # 体力
        "stamina_drain": 2.0,  # 冲刺时体力消耗/秒
        "stamina_recover": 5.0,# 非冲刺时体力恢复/秒
        "control_radius": 1.5, # 控球半径
        "tackle_radius": 2.0,  # 抢断半径
}

## 获取当前AI难度参数
func get_ai_params() -> Dictionary:
        return AI_PARAMS.get(current_match_config.difficulty, AI_PARAMS[AIDifficulty.NORMAL])

## 设置比赛配置
func set_match_config(config: Dictionary) -> void:
        for key in config:
                current_match_config[key] = config[key]

## 设置当前活动
func set_event(event: Dictionary) -> void:
        current_event = event
        # 应用活动修正到比赛配置
        if event.has("modifiers"):
                var mods = event["modifiers"]
                if mods.has("ai_defensive_mode") and mods["ai_defensive_mode"]:
                        current_match_config.difficulty = AIDifficulty.HARD

## 获取阵型坐标
func get_formation(formation_name: String) -> Array:
        return FORMATIONS.get(formation_name, FORMATIONS["4-4-2"])

## 难度枚举转字符串
func difficulty_to_string(d: int) -> String:
        match d:
                AIDifficulty.EASY: return "简单"
                AIDifficulty.NORMAL: return "普通"
                AIDifficulty.HARD: return "困难"
                AIDifficulty.LEGEND: return "传奇"
                _: return "普通"

## 字符串转难度枚举
func string_to_difficulty(s: String) -> int:
        match s.to_lower():
                "easy": return AIDifficulty.EASY
                "normal": return AIDifficulty.NORMAL
                "hard": return AIDifficulty.HARD
                "legend": return AIDifficulty.LEGEND
                _: return AIDifficulty.NORMAL
