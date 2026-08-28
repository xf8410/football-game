#!/usr/bin/env python3
"""
扩充球员数据库 v7
新增更多转会历史球员
"""
import json
import os

MORE_TRANSFER_PLAYERS = {
    "gvardiol": {
        "name": "约什科·格瓦迪奥尔", "short_name": "格瓦迪奥尔", "nationality": "克罗地亚",
        "positions": ["CB", "LB"], "preferred_foot": "left",
        "base_attributes": {"pace": 78, "shooting": 55, "passing": 70, "dribbling": 72, "defending": 85, "physical": 84},
        "traits": ["iron_wall", "header"],
        "skills": ["iron_wall", "air_dominance", "speed_burst"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_blonde", "hair_color": "#C8B890"},
        "versions": [
            {"club": "dinamo_zagreb", "era": "萨格勒布迪纳摩", "years": "2019-2021", "jersey": 4, "adj": -5},
            {"club": "rb_leipzig", "era": "莱比锡时期", "years": "2021-2023", "jersey": 32, "adj": 0},
            {"club": "man_city", "era": "曼城时期", "years": "2023-至今", "jersey": 24, "adj": 3},
            {"club": "croatia", "era": "国家队", "years": "2021-至今", "jersey": 20, "adj": 2, "is_national": True},
        ],
    },
    "mac_allister": {
        "name": "亚历克西斯·麦卡利斯特", "short_name": "麦卡利斯特", "nationality": "阿根廷",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 78, "passing": 86, "dribbling": 85, "defending": 70, "physical": 72},
        "traits": ["playmaker", "free_kick"],
        "skills": ["vision_pass", "pinpoint_pass", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#D9A87A", "hair_style": "medium_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "boca_juniors", "era": "博卡青年", "years": "2016-2019", "jersey": 8, "adj": -5},
            {"club": "brighton", "era": "布莱顿时期", "years": "2019-2023", "jersey": 10, "adj": 0},
            {"club": "liverpool", "era": "利物浦时期", "years": "2023-至今", "jersey": 10, "adj": 3},
            {"club": "argentina", "era": "国家队", "years": "2019-至今", "jersey": 20, "adj": 2, "is_national": True},
        ],
    },
    "wirtz": {
        "name": "弗洛里安·维尔茨", "short_name": "维尔茨", "nationality": "德国",
        "positions": ["CAM", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 80, "passing": 85, "dribbling": 90, "defending": 50, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "slim", "skin_tone": "#F2C49B", "hair_style": "medium_blonde", "hair_color": "#A89060"},
        "versions": [
            {"club": "leverkusen", "era": "勒沃库森", "years": "2020-至今", "jersey": 10, "adj": 0},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 17, "adj": 1, "is_national": True},
        ],
    },
    "musiala": {
        "name": "贾马尔·穆西亚拉", "short_name": "穆西亚拉", "nationality": "德国",
        "positions": ["CAM", "LW", "RW"], "preferred_foot": "right",
        "base_attributes": {"pace": 82, "shooting": 78, "passing": 82, "dribbling": 92, "defending": 45, "physical": 60},
        "traits": ["dribbling_master", "flair"],
        "skills": ["ghost_dribble", "first_touch", "speed_burst"],
        "appearance": {"height_mult": 1.08, "body_type": "slim", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "chelsea", "era": "切尔西青训", "years": "2018-2019", "jersey": 43, "adj": -10},
            {"club": "bayern_munich", "era": "拜仁时期", "years": "2019-至今", "jersey": 42, "adj": 0},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 12, "adj": 1, "is_national": True},
        ],
    },
    "isak": {
        "name": "亚历山大·伊萨克", "short_name": "伊萨克", "nationality": "瑞典",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 85, "passing": 72, "dribbling": 84, "defending": 35, "physical": 78},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.12, "body_type": "athletic", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "aik", "era": "AIK索尔纳", "years": "2016-2017", "jersey": 11, "adj": -8},
            {"club": "borussia_dortmund", "era": "多特蒙德", "years": "2017-2019", "jersey": 14, "adj": -3},
            {"club": "real_sociedad", "era": "皇家社会", "years": "2019-2022", "jersey": 14, "adj": 0},
            {"club": "newcastle", "era": "纽卡斯尔", "years": "2022-至今", "jersey": 14, "adj": 3},
            {"club": "sweden", "era": "国家队", "years": "2017-至今", "jersey": 11, "adj": 1, "is_national": True},
        ],
    },
    "olmo": {
        "name": "达尼·奥尔莫", "short_name": "奥尔莫", "nationality": "西班牙",
        "positions": ["CAM", "LW", "RW"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 84, "dribbling": 87, "defending": 50, "physical": 70},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "dinamo_zagreb", "era": "萨格勒布迪纳摩", "years": "2014-2020", "jersey": 7, "adj": -5},
            {"club": "rb_leipzig", "era": "莱比锡时期", "years": "2020-2024", "jersey": 7, "adj": 0},
            {"club": "barcelona", "era": "巴萨时期", "years": "2024-至今", "jersey": 20, "adj": 3},
            {"club": "spain", "era": "国家队", "years": "2019-至今", "jersey": 9, "adj": 2, "is_national": True},
        ],
    },
    "szoboszlai": {
        "name": "多米尼克·索博斯洛伊", "short_name": "索博斯洛伊", "nationality": "匈牙利",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 84, "dribbling": 84, "defending": 60, "physical": 75},
        "traits": ["long_shot", "playmaker", "free_kick"],
        "skills": ["power_shot", "vision_pass", "pinpoint_pass"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#9A8050"},
        "versions": [
            {"club": "rb_salzburg", "era": "萨尔茨堡红牛", "years": "2016-2021", "jersey": 17, "adj": -3},
            {"club": "rb_leipzig", "era": "莱比锡时期", "years": "2021-2023", "jersey": 17, "adj": 0},
            {"club": "liverpool", "era": "利物浦时期", "years": "2023-至今", "jersey": 8, "adj": 3},
            {"club": "hungary", "era": "国家队", "years": "2019-至今", "jersey": 10, "adj": 2, "is_national": True},
        ],
    },
    "nunez": {
        "name": "达尔文·努涅斯", "short_name": "努涅斯", "nationality": "乌拉圭",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 90, "shooting": 82, "passing": 65, "dribbling": 78, "defending": 35, "physical": 82},
        "traits": ["speedster", "header"],
        "skills": ["speed_burst", "air_dominance", "power_shot"],
        "appearance": {"height_mult": 1.12, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "penarol", "era": "佩纳罗尔", "years": "2017-2019", "jersey": 9, "adj": -8},
            {"club": "almeria", "era": "阿尔梅里亚", "years": "2019-2020", "jersey": 9, "adj": -3},
            {"club": "benfica", "era": "本菲卡时期", "years": "2020-2022", "jersey": 9, "adj": 0},
            {"club": "liverpool", "era": "利物浦时期", "years": "2022-至今", "jersey": 9, "adj": 2},
            {"club": "uruguay", "era": "国家队", "years": "2019-至今", "jersey": 9, "adj": 1, "is_national": True},
        ],
    },
    "kulusevski": {
        "name": "德扬·库卢塞夫斯基", "short_name": "库卢塞夫斯基", "nationality": "瑞典",
        "positions": ["RW", "CAM"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 75, "passing": 80, "dribbling": 84, "defending": 55, "physical": 78},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#2A1A0A"},
        "versions": [
            {"club": "atalanta", "era": "亚特兰大", "years": "2016-2020", "jersey": 44, "adj": -5},
            {"club": "juventus", "era": "尤文时期", "years": "2020-2023", "jersey": 44, "adj": 0},
            {"club": "tottenham", "era": "热刺时期", "years": "2023-至今", "jersey": 21, "adj": 2},
            {"club": "sweden", "era": "国家队", "years": "2019-至今", "jersey": 10, "adj": 1, "is_national": True},
        ],
    },
    "havertz": {
        "name": "凯·哈弗茨", "short_name": "哈弗茨", "nationality": "德国",
        "positions": ["ST", "CAM", "CF"], "preferred_foot": "left",
        "base_attributes": {"pace": 78, "shooting": 82, "passing": 80, "dribbling": 84, "defending": 50, "physical": 80},
        "traits": ["header", "playmaker"],
        "skills": ["air_dominance", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.15, "body_type": "athletic", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#9A8050"},
        "versions": [
            {"club": "leverkusen", "era": "勒沃库森", "years": "2016-2020", "jersey": 29, "adj": -3},
            {"club": "chelsea", "era": "切尔西时期", "years": "2020-2023", "jersey": 29, "adj": 0},
            {"club": "arsenal", "era": "阿森纳时期", "years": "2023-至今", "jersey": 29, "adj": 3},
            {"club": "germany", "era": "国家队", "years": "2018-至今", "jersey": 7, "adj": 1, "is_national": True},
        ],
    },
}

def generate_players():
    players = {}
    for base_id, base_data in MORE_TRANSFER_PLAYERS.items():
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
    output_path = os.path.join(os.path.dirname(__file__), "..", "data", "more_transfer_players.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"players": players}, f, ensure_ascii=False, indent=2)
    print(f"已生成 {len(players)} 张转会历史球员卡")

if __name__ == "__main__":
    main()
