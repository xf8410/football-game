#!/usr/bin/env python3
"""
扩充球员数据库 v5
新增更多现役球员
"""
import json
import os

# 新增现役球员
NEW_PLAYERS = {
    "valverde": {
        "name": "费德里科·巴尔韦德", "short_name": "巴尔韦德", "nationality": "乌拉圭",
        "positions": ["CM", "RM"], "preferred_foot": "right",
        "base_attributes": {"pace": 85, "shooting": 82, "passing": 84, "dribbling": 84, "defending": 75, "physical": 85},
        "traits": ["box_to_box", "long_shot"],
        "skills": ["endless_runner", "power_shot", "speed_burst"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "real_madrid", "era": "皇马时期", "years": "2018-至今", "jersey": 15, "adj": 0},
            {"club": "uruguay", "era": "国家队", "years": "2017-至今", "jersey": 15, "adj": 0, "is_national": True},
        ],
    },
    "vinicius": {
        "name": "维尼修斯·儒尼奥尔", "short_name": "维尼修斯", "nationality": "巴西",
        "positions": ["LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 95, "shooting": 80, "passing": 78, "dribbling": 92, "defending": 25, "physical": 70},
        "traits": ["dribbling_master", "speedster"],
        "skills": ["ghost_dribble", "speed_burst", "first_touch"],
        "appearance": {"height_mult": 1.08, "body_type": "slim", "skin_tone": "#5A3D2A", "hair_style": "curly_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "real_madrid", "era": "皇马时期", "years": "2018-至今", "jersey": 7, "adj": 2},
            {"club": "brazil", "era": "国家队", "years": "2019-至今", "jersey": 7, "adj": 1, "is_national": True},
        ],
    },
    "rodrygo": {
        "name": "罗德里戈·戈斯", "short_name": "罗德里戈", "nationality": "巴西",
        "positions": ["RW", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 80, "passing": 78, "dribbling": 87, "defending": 30, "physical": 65},
        "traits": ["dribbling_master", "clutch_player"],
        "skills": ["ghost_dribble", "first_touch", "clutch_player"],
        "appearance": {"height_mult": 1.05, "body_type": "slim", "skin_tone": "#5A3D2A", "hair_style": "curly_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "real_madrid", "era": "皇马时期", "years": "2019-至今", "jersey": 11, "adj": 0},
            {"club": "brazil", "era": "国家队", "years": "2019-至今", "jersey": 11, "adj": 0, "is_national": True},
        ],
    },
    "tchouameni": {
        "name": "奥雷利安·楚阿梅尼", "short_name": "楚阿梅尼", "nationality": "法国",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 75, "shooting": 70, "passing": 82, "dribbling": 78, "defending": 85, "physical": 88},
        "traits": ["iron_wall", "header"],
        "skills": ["iron_wall", "interceptor", "air_dominance"],
        "appearance": {"height_mult": 1.1, "body_type": "muscular", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "real_madrid", "era": "皇马时期", "years": "2022-至今", "jersey": 14, "adj": 0},
            {"club": "france", "era": "国家队", "years": "2021-至今", "jersey": 14, "adj": 0, "is_national": True},
        ],
    },
    "camavinga": {
        "name": "爱德华多·卡马文加", "short_name": "卡马文加", "nationality": "法国",
        "positions": ["CM", "LB"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 68, "passing": 80, "dribbling": 85, "defending": 78, "physical": 80},
        "traits": ["dribbling_master", "box_to_box"],
        "skills": ["ghost_dribble", "endless_runner", "first_touch"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "real_madrid", "era": "皇马时期", "years": "2021-至今", "jersey": 6, "adj": 0},
            {"club": "france", "era": "国家队", "years": "2020-至今", "jersey": 6, "adj": 0, "is_national": True},
        ],
    },
    "gavi": {
        "name": "帕布洛·加维", "short_name": "加维", "nationality": "西班牙",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 75, "shooting": 72, "passing": 85, "dribbling": 86, "defending": 70, "physical": 65},
        "traits": ["playmaker", "box_to_box"],
        "skills": ["vision_pass", "endless_runner", "first_touch"],
        "appearance": {"height_mult": 0.98, "body_type": "slim", "skin_tone": "#E8B888", "hair_style": "medium_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "barcelona", "era": "巴萨时期", "years": "2021-至今", "jersey": 6, "adj": 0},
            {"club": "spain", "era": "国家队", "years": "2021-至今", "jersey": 6, "adj": 0, "is_national": True},
        ],
    },
    "olise": {
        "name": "迈克尔·奥利赛", "short_name": "奥利赛", "nationality": "法国",
        "positions": ["RW", "CAM"], "preferred_foot": "left",
        "base_attributes": {"pace": 82, "shooting": 80, "passing": 85, "dribbling": 88, "defending": 45, "physical": 70},
        "traits": ["dribbling_master", "playmaker", "crossing"],
        "skills": ["ghost_dribble", "vision_pass", "curve_shot"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "bayern_munich", "era": "拜仁时期", "years": "2024-至今", "jersey": 17, "adj": 2},
            {"club": "france", "era": "国家队", "years": "2024-至今", "jersey": 17, "adj": 1, "is_national": True},
        ],
    },
    "palmer": {
        "name": "科尔·帕尔默", "short_name": "帕尔默", "nationality": "英格兰",
        "positions": ["CAM", "RW"], "preferred_foot": "left",
        "base_attributes": {"pace": 78, "shooting": 85, "passing": 84, "dribbling": 86, "defending": 50, "physical": 68},
        "traits": ["playmaker", "long_shot", "free_kick"],
        "skills": ["vision_pass", "power_shot", "curve_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "short_blonde", "hair_color": "#8B7355"},
        "versions": [
            {"club": "chelsea", "era": "切尔西时期", "years": "2023-至今", "jersey": 20, "adj": 2},
            {"club": "england", "era": "国家队", "years": "2023-至今", "jersey": 20, "adj": 1, "is_national": True},
        ],
    },
    "saka": {
        "name": "布卡约·萨卡", "short_name": "萨卡", "nationality": "英格兰",
        "positions": ["RW", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 86, "shooting": 80, "passing": 82, "dribbling": 88, "defending": 55, "physical": 70},
        "traits": ["dribbling_master", "crossing"],
        "skills": ["ghost_dribble", "pinpoint_pass", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "arsenal", "era": "阿森纳时期", "years": "2018-至今", "jersey": 7, "adj": 0},
            {"club": "england", "era": "国家队", "years": "2020-至今", "jersey": 7, "adj": 0, "is_national": True},
        ],
    },
    "foden": {
        "name": "菲尔·福登", "short_name": "福登", "nationality": "英格兰",
        "positions": ["CAM", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 84, "dribbling": 88, "defending": 55, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "short_blonde", "hair_color": "#8B7355"},
        "versions": [
            {"club": "man_city", "era": "曼城时期", "years": "2017-至今", "jersey": 47, "adj": 0},
            {"club": "england", "era": "国家队", "years": "2020-至今", "jersey": 47, "adj": 0, "is_national": True},
        ],
    },
    "wirtz": {
        "name": "弗洛里安·维尔茨", "short_name": "维尔茨", "nationality": "德国",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 82, "shooting": 80, "passing": 86, "dribbling": 90, "defending": 50, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "slim", "skin_tone": "#D9A87A", "hair_style": "medium_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "leverkusen", "era": "勒沃库森时期", "years": "2020-至今", "jersey": 10, "adj": 2},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 10, "adj": 1, "is_national": True},
        ],
    },
    "musiala": {
        "name": "贾马尔·穆西亚拉", "short_name": "穆西亚拉", "nationality": "德国",
        "positions": ["CAM", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 85, "shooting": 78, "passing": 82, "dribbling": 92, "defending": 45, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.08, "body_type": "slim", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "bayern_munich", "era": "拜仁时期", "years": "2020-至今", "jersey": 42, "adj": 0},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 42, "adj": 0, "is_national": True},
        ],
    },
    "lautaro": {
        "name": "劳塔罗·马丁内斯", "short_name": "劳塔罗", "nationality": "阿根廷",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 85, "shooting": 88, "passing": 75, "dribbling": 85, "defending": 40, "physical": 80},
        "traits": ["header", "clutch_player"],
        "skills": ["air_dominance", "clutch_player", "power_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "inter_milan", "era": "国米时期", "years": "2018-至今", "jersey": 10, "adj": 0},
            {"club": "argentina", "era": "国家队", "years": "2018-至今", "jersey": 22, "adj": 0, "is_national": True},
        ],
    },
    "leao": {
        "name": "拉斐尔·莱奥", "short_name": "莱奥", "nationality": "葡萄牙",
        "positions": ["LW", "ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 93, "shooting": 80, "passing": 78, "dribbling": 88, "defending": 30, "physical": 78},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.12, "body_type": "athletic", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "ac_milan", "era": "AC米兰时期", "years": "2019-至今", "jersey": 10, "adj": 0},
            {"club": "portugal", "era": "国家队", "years": "2021-至今", "jersey": 10, "adj": 0, "is_national": True},
        ],
    },
    "kvaratskhelia": {
        "name": "赫维恰·克瓦拉茨赫利亚", "short_name": "K77", "nationality": "格鲁吉亚",
        "positions": ["LW", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 80, "passing": 80, "dribbling": 90, "defending": 35, "physical": 72},
        "traits": ["dribbling_master", "flair"],
        "skills": ["ghost_dribble", "curve_shot", "first_touch"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "medium_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "napoli", "era": "那不勒斯时期", "years": "2022-至今", "jersey": 77, "adj": 0},
            {"club": "georgia", "era": "国家队", "years": "2019-至今", "jersey": 77, "adj": 0, "is_national": True},
        ],
    },
    "odegaard": {
        "name": "马丁·厄德高", "short_name": "厄德高", "nationality": "挪威",
        "positions": ["CAM", "CM"], "preferred_foot": "left",
        "base_attributes": {"pace": 75, "shooting": 78, "passing": 88, "dribbling": 87, "defending": 55, "physical": 65},
        "traits": ["playmaker", "dribbling_master"],
        "skills": ["vision_pass", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "slim", "skin_tone": "#D9A87A", "hair_style": "medium_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "real_madrid", "era": "皇马时期", "years": "2015-2021", "jersey": 21, "adj": -5},
            {"club": "arsenal", "era": "阿森纳时期", "years": "2021-至今", "jersey": 8, "adj": 3},
            {"club": "norway", "era": "国家队", "years": "2014-至今", "jersey": 8, "adj": 2, "is_national": True},
        ],
    },
}

def generate_players():
    # 读取现有球员
    input_path = os.path.join(os.path.dirname(__file__), "..", "data", "players.json")
    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    players = data.get("players", {})

    # 添加新球员
    for base_id, base_data in NEW_PLAYERS.items():
        for i, ver in enumerate(base_data["versions"]):
            card_id = "%s_%s_%d" % (base_id, ver["club"], i)
            adj = ver.get("adj", 0)
            adjusted_attrs = {}
            for attr, val in base_data["base_attributes"].items():
                adjusted_attrs[attr] = max(1, min(99, val + adj))

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
    print(f"总卡牌数: {len(players)}")

if __name__ == "__main__":
    main()
