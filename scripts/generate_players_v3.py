#!/usr/bin/env python3
"""
扩充球员数据库 v3
新增：国家队球员卡（世界杯版本）
同一球员在俱乐部和国家队是不同的卡
"""
import json
import os

# 球员基础数据
PLAYER_BASE = {
    # ---- 挪威 ----
    "haaland": {
        "name": "厄林·哈兰德", "short_name": "哈兰德", "nationality": "挪威",
        "positions": ["ST"], "preferred_foot": "left",
        "base_attributes": {"pace": 91, "shooting": 93, "passing": 66, "dribbling": 80, "defending": 45, "physical": 88},
        "traits": ["long_shot", "header", "power_header"],
        "skills": ["speed_burst", "power_shot", "clutch_player"],
        "appearance": {"height_mult": 1.15, "body_type": "muscular", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#D9C28A"},
        "versions": [
            {"club": "molde", "era": "莫尔德时期", "years": "2017-2018", "jersey": 19, "adj": -8},
            {"club": "salzburg", "era": "萨尔茨堡时期", "years": "2019-2020", "jersey": 9, "adj": -3},
            {"club": "dortmund", "era": "多特蒙德时期", "years": "2020-2022", "jersey": 9, "adj": 0},
            {"club": "man_city", "era": "曼城巅峰", "years": "2022-至今", "jersey": 9, "adj": 3},
            {"club": "norway", "era": "国家队", "years": "2019-至今", "jersey": 9, "adj": 2, "is_national": True},
        ],
    },
    "odegaard": {
        "name": "马丁·厄德高", "short_name": "厄德高", "nationality": "挪威",
        "positions": ["CAM", "CM"], "preferred_foot": "left",
        "base_attributes": {"pace": 75, "shooting": 78, "passing": 88, "dribbling": 87, "defending": 55, "physical": 65},
        "traits": ["playmaker", "dribbling_master", "free_kick"],
        "skills": ["vision_pass", "ghost_dribble", "pinpoint_pass"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#F0C8A0", "hair_style": "medium_blonde", "hair_color": "#C4A878"},
        "versions": [
            {"club": "real_madrid", "era": "皇马早期", "years": "2015-2020", "jersey": 21, "adj": -5},
            {"club": "arsenal", "era": "阿森纳核心", "years": "2021-至今", "jersey": 8, "adj": 2},
            {"club": "norway", "era": "国家队队长", "years": "2014-至今", "jersey": 10, "adj": 3, "is_national": True},
        ],
    },
    # ---- 英格兰 ----
    "kane": {
        "name": "哈里·凯恩", "short_name": "凯恩", "nationality": "英格兰",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 70, "shooting": 93, "passing": 84, "dribbling": 83, "defending": 47, "physical": 83},
        "traits": ["long_shot", "header", "playmaker"],
        "skills": ["power_shot", "vision_pass", "clutch_player"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_dark", "hair_color": "#3A2818"},
        "versions": [
            {"club": "tottenham", "era": "热刺传奇", "years": "2009-2023", "jersey": 10, "adj": 0},
            {"club": "bayern_munich", "era": "拜仁时期", "years": "2023-至今", "jersey": 9, "adj": 2},
            {"club": "england", "era": "国家队队长", "years": "2015-至今", "jersey": 9, "adj": 3, "is_national": True},
        ],
    },
    "bellingham": {
        "name": "裘德·贝林厄姆", "short_name": "贝林", "nationality": "英格兰",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 85, "passing": 86, "dribbling": 87, "defending": 75, "physical": 84},
        "traits": ["box_to_box", "playmaker", "header"],
        "skills": ["ghost_movement", "vision_pass", "clutch_player"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#D8A878", "hair_style": "short_dark", "hair_color": "#2A1810"},
        "versions": [
            {"club": "dortmund", "era": "多特蒙德时期", "years": "2020-2023", "jersey": 22, "adj": -2},
            {"club": "real_madrid", "era": "皇马核心", "years": "2023-至今", "jersey": 5, "adj": 3},
            {"club": "england", "era": "国家队", "years": "2020-至今", "jersey": 10, "adj": 2, "is_national": True},
        ],
    },
    "rice": {
        "name": "德克兰·赖斯", "short_name": "赖斯", "nationality": "英格兰",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 75, "passing": 82, "dribbling": 78, "defending": 85, "physical": 85},
        "traits": ["iron_wall", "playmaker"],
        "skills": ["iron_wall", "interceptor", "pinpoint_pass"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#E0B080", "hair_style": "short_dark", "hair_color": "#1A1008"},
        "versions": [
            {"club": "west_ham", "era": "西汉姆联时期", "years": "2017-2023", "jersey": 41, "adj": -2},
            {"club": "arsenal", "era": "阿森纳核心", "years": "2023-至今", "jersey": 41, "adj": 3},
            {"club": "england", "era": "国家队", "years": "2019-至今", "jersey": 4, "adj": 2, "is_national": True},
        ],
    },
    "saka": {
        "name": "布卡约·萨卡", "short_name": "萨卡", "nationality": "英格兰",
        "positions": ["RW", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 86, "shooting": 80, "passing": 82, "dribbling": 87, "defending": 55, "physical": 70},
        "traits": ["dribbling_master", "speedster"],
        "skills": ["ghost_dribble", "speed_burst", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#5A3828", "hair_style": "short_dark", "hair_color": "#0A0808"},
        "versions": [
            {"club": "arsenal", "era": "阿森纳青训", "years": "2018-至今", "jersey": 7, "adj": 2},
            {"club": "england", "era": "国家队", "years": "2020-至今", "jersey": 17, "adj": 1, "is_national": True},
        ],
    },
    "foden": {
        "name": "菲尔·福登", "short_name": "福登", "nationality": "英格兰",
        "positions": ["CAM", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 84, "dribbling": 88, "defending": 55, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 0.95, "body_type": "slim", "skin_tone": "#E8B888", "hair_style": "short_blonde", "hair_color": "#C8A878"},
        "versions": [
            {"club": "man_city", "era": "曼城青训", "years": "2017-至今", "jersey": 47, "adj": 2},
            {"club": "england", "era": "国家队", "years": "2020-至今", "jersey": 11, "adj": 1, "is_national": True},
        ],
    },
    # ---- 法国 ----
    "mbappe": {
        "name": "基利安·姆巴佩", "short_name": "姆巴佩", "nationality": "法国",
        "positions": ["ST", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 97, "shooting": 90, "passing": 80, "dribbling": 92, "defending": 36, "physical": 78},
        "traits": ["speedster", "dribbling_master", "long_shot"],
        "skills": ["speed_burst", "ghost_dribble", "clutch_player"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#6A4830", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "monaco", "era": "摩纳哥天才", "years": "2015-2017", "jersey": 29, "adj": -5},
            {"club": "psg", "era": "巴黎巅峰", "years": "2017-2024", "jersey": 7, "adj": 2},
            {"club": "real_madrid", "era": "皇马时期", "years": "2024-至今", "jersey": 9, "adj": 3},
            {"club": "france", "era": "国家队", "years": "2017-至今", "jersey": 10, "adj": 4, "is_national": True},
        ],
    },
    "dembele": {
        "name": "乌斯曼·登贝莱", "short_name": "登贝莱", "nationality": "法国",
        "positions": ["RW", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 90, "shooting": 78, "passing": 80, "dribbling": 90, "defending": 40, "physical": 65},
        "traits": ["dribbling_master", "speedster"],
        "skills": ["ghost_dribble", "speed_burst", "curve_shot"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#5A3828", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "dortmund", "era": "多特蒙德时期", "years": "2016-2017", "jersey": 7, "adj": -2},
            {"club": "barcelona", "era": "巴萨时期", "years": "2017-2024", "jersey": 7, "adj": 1},
            {"club": "psg", "era": "巴黎时期", "years": "2024-至今", "jersey": 10, "adj": 2},
            {"club": "france", "era": "国家队", "years": "2016-至今", "jersey": 11, "adj": 2, "is_national": True},
        ],
    },
    "olise": {
        "name": "迈克尔·奥利赛", "short_name": "奥利赛", "nationality": "法国",
        "positions": ["RW", "CAM"], "preferred_foot": "left",
        "base_attributes": {"pace": 82, "shooting": 80, "passing": 84, "dribbling": 88, "defending": 50, "physical": 70},
        "traits": ["dribbling_master", "playmaker", "free_kick"],
        "skills": ["ghost_dribble", "vision_pass", "curve_shot"],
        "appearance": {"height_mult": 1.03, "body_type": "athletic", "skin_tone": "#7A5838", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "crystal_palace", "era": "水晶宫时期", "years": "2021-2024", "jersey": 7, "adj": -1},
            {"club": "bayern_munich", "era": "拜仁时期", "years": "2024-至今", "jersey": 17, "adj": 2},
            {"club": "france", "era": "国家队", "years": "2024-至今", "jersey": 14, "adj": 2, "is_national": True},
        ],
    },
    "saliba": {
        "name": "威廉·萨利巴", "short_name": "萨利巴", "nationality": "法国",
        "positions": ["CB"], "preferred_foot": "right",
        "base_attributes": {"pace": 85, "shooting": 50, "passing": 72, "dribbling": 72, "defending": 86, "physical": 85},
        "traits": ["iron_wall", "speedster"],
        "skills": ["iron_wall", "speed_burst", "interceptor"],
        "appearance": {"height_mult": 1.12, "body_type": "muscular", "skin_tone": "#5A3828", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "arsenal", "era": "阿森纳核心", "years": "2022-至今", "jersey": 2, "adj": 2},
            {"club": "france", "era": "国家队", "years": "2022-至今", "jersey": 17, "adj": 1, "is_national": True},
        ],
    },
    # ---- 西班牙 ----
    "yamal": {
        "name": "拉明·亚马尔", "short_name": "亚马尔", "nationality": "西班牙",
        "positions": ["RW"], "preferred_foot": "left",
        "base_attributes": {"pace": 87, "shooting": 78, "passing": 82, "dribbling": 90, "defending": 40, "physical": 60},
        "traits": ["dribbling_master", "speedster", "playmaker"],
        "skills": ["ghost_dribble", "speed_burst", "vision_pass"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#A87858", "hair_style": "curly_dark", "hair_color": "#0A0808"},
        "versions": [
            {"club": "barcelona", "era": "巴萨天才", "years": "2023-至今", "jersey": 19, "adj": 2},
            {"club": "spain", "era": "国家队", "years": "2023-至今", "jersey": 17, "adj": 2, "is_national": True},
        ],
    },
    "rodri": {
        "name": "罗德里", "short_name": "罗德里", "nationality": "西班牙",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 62, "shooting": 75, "passing": 85, "dribbling": 78, "defending": 82, "physical": 85},
        "traits": ["iron_wall", "playmaker"],
        "skills": ["iron_wall", "pinpoint_pass", "interceptor"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#D8A878", "hair_style": "short_dark", "hair_color": "#2A1810"},
        "versions": [
            {"club": "atletico_madrid", "era": "马竞青训", "years": "2015-2018", "jersey": 16, "adj": -5},
            {"club": "man_city", "era": "曼城核心", "years": "2019-至今", "jersey": 16, "adj": 3},
            {"club": "spain", "era": "国家队", "years": "2018-至今", "jersey": 16, "adj": 2, "is_national": True},
        ],
    },
    "pedri": {
        "name": "佩德里", "short_name": "佩德里", "nationality": "西班牙",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 75, "passing": 86, "dribbling": 87, "defending": 60, "physical": 65},
        "traits": ["playmaker", "dribbling_master"],
        "skills": ["vision_pass", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 0.98, "body_type": "slim", "skin_tone": "#D8A878", "hair_style": "medium_dark", "hair_color": "#2A1810"},
        "versions": [
            {"club": "barcelona", "era": "巴萨核心", "years": "2020-至今", "jersey": 8, "adj": 2},
            {"club": "spain", "era": "国家队", "years": "2021-至今", "jersey": 20, "adj": 2, "is_national": True},
        ],
    },
    "gavi": {
        "name": "加维", "short_name": "加维", "nationality": "西班牙",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 75, "shooting": 72, "passing": 82, "dribbling": 85, "defending": 65, "physical": 68},
        "traits": ["box_to_box", "dribbling_master"],
        "skills": ["endless_runner", "ghost_dribble", "interceptor"],
        "appearance": {"height_mult": 0.95, "body_type": "slim", "skin_tone": "#D8A878", "hair_style": "medium_dark", "hair_color": "#3A2818"},
        "versions": [
            {"club": "barcelona", "era": "巴萨青训", "years": "2021-至今", "jersey": 6, "adj": 1},
            {"club": "spain", "era": "国家队", "years": "2021-至今", "jersey": 9, "adj": 1, "is_national": True},
        ],
    },
    "williams": {
        "name": "尼科·威廉姆斯", "short_name": "尼科", "nationality": "西班牙",
        "positions": ["LW", "RW"], "preferred_foot": "right",
        "base_attributes": {"pace": 92, "shooting": 76, "passing": 78, "dribbling": 86, "defending": 45, "physical": 72},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "endless_runner"],
        "appearance": {"height_mult": 1.02, "body_type": "athletic", "skin_tone": "#4A3020", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "athletic_bilbao", "era": "毕尔巴鄂竞技", "years": "2021-至今", "jersey": 10, "adj": 1},
            {"club": "spain", "era": "国家队", "years": "2022-至今", "jersey": 17, "adj": 1, "is_national": True},
        ],
    },
    # ---- 巴西 ----
    "vinicius": {
        "name": "维尼修斯·儒尼奥尔", "short_name": "维尼修斯", "nationality": "巴西",
        "positions": ["LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 94, "shooting": 82, "passing": 78, "dribbling": 90, "defending": 30, "physical": 70},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#4A3020", "hair_style": "curly_dark", "hair_color": "#0A0808"},
        "versions": [
            {"club": "flamengo", "era": "弗拉门戈青训", "years": "2017-2018", "jersey": 11, "adj": -5},
            {"club": "real_madrid", "era": "皇马核心", "years": "2018-至今", "jersey": 7, "adj": 3},
            {"club": "brazil", "era": "国家队", "years": "2019-至今", "jersey": 7, "adj": 2, "is_national": True},
        ],
    },
    "rodrigo": {
        "name": "罗德里戈", "short_name": "罗德里戈", "nationality": "巴西",
        "positions": ["RW", "ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 80, "passing": 76, "dribbling": 85, "defending": 40, "physical": 68},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "clutch_player"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#5A3828", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "santos", "era": "桑托斯青训", "years": "2017-2019", "jersey": 11, "adj": -4},
            {"club": "real_madrid", "era": "皇马时期", "years": "2019-至今", "jersey": 11, "adj": 2},
            {"club": "brazil", "era": "国家队", "years": "2019-至今", "jersey": 21, "adj": 1, "is_national": True},
        ],
    },
    # ---- 阿根廷 ----
    "messi": {
        "name": "利昂内尔·梅西", "short_name": "梅西", "nationality": "阿根廷",
        "positions": ["RW", "CF", "CAM"], "preferred_foot": "left",
        "base_attributes": {"pace": 85, "shooting": 92, "passing": 91, "dribbling": 95, "defending": 35, "physical": 65},
        "traits": ["dribbling_master", "playmaker", "free_kick"],
        "skills": ["ghost_dribble", "vision_pass", "curve_shot"],
        "appearance": {"height_mult": 0.92, "body_type": "stocky", "skin_tone": "#E8B888", "hair_style": "medium_brown", "hair_color": "#3A2818"},
        "versions": [
            {"club": "barcelona", "era": "巴萨传奇", "years": "2004-2021", "jersey": 10, "adj": 3},
            {"club": "psg", "era": "巴黎时期", "years": "2021-2023", "jersey": 30, "adj": -1},
            {"club": "inter_miami", "era": "迈阿密国际", "years": "2023-至今", "jersey": 10, "adj": 0},
            {"club": "argentina", "era": "国家队冠军", "years": "2005-至今", "jersey": 10, "adj": 4, "is_national": True},
        ],
    },
    # ---- 葡萄牙 ----
    "c_ronaldo": {
        "name": "克里斯蒂亚诺·罗纳尔多", "short_name": "C罗", "nationality": "葡萄牙",
        "positions": ["LW", "ST", "RW"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 94, "passing": 82, "dribbling": 87, "defending": 35, "physical": 80},
        "traits": ["long_shot", "header", "free_kick"],
        "skills": ["speed_burst", "power_shot", "clutch_player"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "slick_back", "hair_color": "#261810"},
        "versions": [
            {"club": "sporting_cp", "era": "里斯本竞技时期", "years": "2002-2003", "jersey": 28, "adj": -8},
            {"club": "man_united", "era": "曼联一期", "years": "2003-2009", "jersey": 7, "adj": 2},
            {"club": "real_madrid", "era": "皇马巅峰", "years": "2009-2018", "jersey": 7, "adj": 5},
            {"club": "juventus", "era": "尤文时期", "years": "2018-2021", "jersey": 7, "adj": 1},
            {"club": "man_united", "era": "曼联二期", "years": "2021-2022", "jersey": 7, "adj": -2},
            {"club": "al_nassr", "era": "利雅得胜利", "years": "2023-至今", "jersey": 7, "adj": -3},
            {"club": "portugal", "era": "国家队传奇", "years": "2003-至今", "jersey": 7, "adj": 3, "is_national": True},
        ],
    },
    "bruno_fernandes": {
        "name": "布鲁诺·费尔南德斯", "short_name": "B费", "nationality": "葡萄牙",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 85, "passing": 89, "dribbling": 82, "defending": 60, "physical": 75},
        "traits": ["playmaker", "long_shot", "free_kick"],
        "skills": ["vision_pass", "power_shot", "pinpoint_pass"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#D8A878", "hair_style": "short_dark", "hair_color": "#1A1008"},
        "versions": [
            {"club": "sporting_cp", "era": "葡萄牙体育", "years": "2017-2020", "jersey": 8, "adj": -2},
            {"club": "man_united", "era": "曼联核心", "years": "2020-至今", "jersey": 8, "adj": 2},
            {"club": "portugal", "era": "国家队", "years": "2017-至今", "jersey": 8, "adj": 2, "is_national": True},
        ],
    },
    # ---- 德国 ----
    "musiala": {
        "name": "贾马尔·穆西亚拉", "short_name": "穆西亚拉", "nationality": "德国",
        "positions": ["CAM", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 82, "shooting": 78, "passing": 82, "dribbling": 90, "defending": 50, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#6A4830", "hair_style": "short_curly", "hair_color": "#0A0808"},
        "versions": [
            {"club": "bayern_munich", "era": "拜仁核心", "years": "2020-至今", "jersey": 42, "adj": 2},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 10, "adj": 2, "is_national": True},
        ],
    },
    "wirtz": {
        "name": "弗洛里安·维尔茨", "short_name": "维尔茨", "nationality": "德国",
        "positions": ["CAM", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 78, "passing": 84, "dribbling": 88, "defending": 50, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#E0B080", "hair_style": "medium_blonde", "hair_color": "#A88858"},
        "versions": [
            {"club": "leverkusen", "era": "勒沃库森核心", "years": "2020-至今", "jersey": 10, "adj": 2},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 17, "adj": 1, "is_national": True},
        ],
    },
    # ---- 意大利 ----
    "barella": {
        "name": "尼科洛·巴雷拉", "short_name": "巴雷拉", "nationality": "意大利",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 78, "shooting": 78, "passing": 84, "dribbling": 85, "defending": 72, "physical": 78},
        "traits": ["box_to_box", "playmaker"],
        "skills": ["endless_runner", "vision_pass", "interceptor"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#E0B080", "hair_style": "short_dark", "hair_color": "#2A1810"},
        "versions": [
            {"club": "inter_milan", "era": "国米核心", "years": "2020-至今", "jersey": 23, "adj": 2},
            {"club": "italy", "era": "国家队", "years": "2018-至今", "jersey": 18, "adj": 1, "is_national": True},
        ],
    },
    "chiesa": {
        "name": "费德里科·基耶萨", "short_name": "基耶萨", "nationality": "意大利",
        "positions": ["RW", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 86, "shooting": 78, "passing": 76, "dribbling": 84, "defending": 50, "physical": 72},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "endless_runner"],
        "appearance": {"height_mult": 1.02, "body_type": "athletic", "skin_tone": "#E0B080", "hair_style": "medium_dark", "hair_color": "#2A1810"},
        "versions": [
            {"club": "juventus", "era": "尤文时期", "years": "2020-2024", "jersey": 7, "adj": 0},
            {"club": "liverpool", "era": "利物浦时期", "years": "2024-至今", "jersey": 14, "adj": 1},
            {"club": "italy", "era": "国家队", "years": "2018-至今", "jersey": 14, "adj": 1, "is_national": True},
        ],
    },
}

def generate_players():
    players = {}
    for base_id, base_data in PLAYER_BASE.items():
        for i, ver in enumerate(base_data["versions"]):
            card_id = "%s_%s_%d" % (base_id, ver["club"], i)
            # 调整属性
            adjusted_attrs = {}
            for attr, val in base_data["base_attributes"].items():
                adjusted_attrs[attr] = max(40, min(99, val + ver.get("adj", 0)))
            
            players[card_id] = {
                "name": base_data["name"],
                "short_name": base_data["short_name"],
                "nationality": base_data["nationality"],
                "positions": base_data["positions"],
                "preferred_foot": base_data["preferred_foot"],
                "attributes": adjusted_attrs,
                "traits": base_data["traits"],
                "skills": base_data["skills"],
                "appearance": base_data["appearance"],
                "club": ver["club"],
                "era": ver["era"],
                "years": ver["years"],
                "jersey_number": ver["jersey"],
                "base_player_id": base_id,
                "version_index": i,
                "is_national": ver.get("is_national", False),
            }
    return players

def main():
    players = generate_players()
    output_path = os.path.join(os.path.dirname(__file__), "..", "data", "players.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"players": players}, f, ensure_ascii=False, indent=2)
    
    base_count = len(PLAYER_BASE)
    total_cards = len(players)
    national_cards = sum(1 for p in players.values() if p.get("is_national"))
    
    print(f"基础球员: {base_count} 人")
    print(f"总卡牌数: {total_cards} 张")
    print(f"国家队卡牌: {national_cards} 张")
    print(f"俱乐部卡牌: {total_cards - national_cards} 张")
    
    # 按国籍统计
    by_nation = {}
    for p in players.values():
        nat = p["nationality"]
        by_nation[nat] = by_nation.get(nat, 0) + 1
    print("\n按国籍统计:")
    for nat in sorted(by_nation, key=lambda x: -by_nation[x]):
        print(f"  {nat}: {by_nation[nat]}张")

if __name__ == "__main__":
    main()
