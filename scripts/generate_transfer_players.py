#!/usr/bin/env python3
"""
扩充球员数据库 v6
新增：转会历史版本球员
每个球员在不同俱乐部的时期都是独立的卡牌
"""
import json
import os

# 转会历史球员数据
TRANSFER_PLAYERS = {
    "enzo_fernandez": {
        "name": "恩佐·费尔南德斯", "short_name": "恩佐", "nationality": "阿根廷",
        "positions": ["CM", "CDM"], "preferred_foot": "right",
        "base_attributes": {"pace": 75, "shooting": 78, "passing": 85, "dribbling": 82, "defending": 78, "physical": 80},
        "traits": ["playmaker", "box_to_box"],
        "skills": ["vision_pass", "pinpoint_pass", "endless_runner"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "river_plate", "era": "河床时期", "years": "2019-2022", "jersey": 5, "adj": -5},
            {"club": "benfica", "era": "本菲卡时期", "years": "2022-2023", "jersey": 13, "adj": 0},
            {"club": "chelsea", "era": "切尔西时期", "years": "2023-至今", "jersey": 8, "adj": 2},
            {"club": "argentina", "era": "国家队", "years": "2022-至今", "jersey": 24, "adj": 3, "is_national": True},
        ],
    },
    "caicedo": {
        "name": "莫伊塞斯·凯塞多", "short_name": "凯塞多", "nationality": "厄瓜多尔",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 78, "shooting": 65, "passing": 80, "dribbling": 78, "defending": 85, "physical": 85},
        "traits": ["iron_wall", "box_to_box"],
        "skills": ["iron_wall", "interceptor", "endless_runner"],
        "appearance": {"height_mult": 1.08, "body_type": "muscular", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "independiente_del_valle", "era": "独立山谷时期", "years": "2019-2021", "jersey": 23, "adj": -8},
            {"club": "brighton", "era": "布莱顿时期", "years": "2021-2023", "jersey": 25, "adj": 0},
            {"club": "chelsea", "era": "切尔西时期", "years": "2023-至今", "jersey": 25, "adj": 2},
            {"club": "ecuador", "era": "国家队", "years": "2020-至今", "jersey": 23, "adj": 1, "is_national": True},
        ],
    },
    "mudryk": {
        "name": "米哈伊洛·穆德里克", "short_name": "穆德里克", "nationality": "乌克兰",
        "positions": ["LW", "LM"], "preferred_foot": "left",
        "base_attributes": {"pace": 93, "shooting": 72, "passing": 70, "dribbling": 85, "defending": 35, "physical": 65},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "slim", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#C8B88A"},
        "versions": [
            {"club": "shakhtar_donetsk", "era": "顿涅茨克矿工时期", "years": "2018-2023", "jersey": 10, "adj": -3},
            {"club": "chelsea", "era": "切尔西时期", "years": "2023-至今", "jersey": 15, "adj": 0},
            {"club": "ukraine", "era": "国家队", "years": "2022-至今", "jersey": 15, "adj": 0, "is_national": True},
        ],
    },
    "antony": {
        "name": "安东尼", "short_name": "安东尼", "nationality": "巴西",
        "positions": ["RW"], "preferred_foot": "left",
        "base_attributes": {"pace": 85, "shooting": 75, "passing": 75, "dribbling": 88, "defending": 40, "physical": 65},
        "traits": ["dribbling_master", "flair"],
        "skills": ["ghost_dribble", "first_touch", "curve_shot"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#5A3D2A", "hair_style": "curly_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "sao_paulo", "era": "圣保罗时期", "years": "2018-2020", "jersey": 11, "adj": -5},
            {"club": "ajax", "era": "阿贾克斯时期", "years": "2020-2022", "jersey": 11, "adj": 0},
            {"club": "man_united", "era": "曼联时期", "years": "2022-至今", "jersey": 21, "adj": 2},
            {"club": "brazil", "era": "国家队", "years": "2021-至今", "jersey": 19, "adj": 1, "is_national": True},
        ],
    },
    "joao_felix": {
        "name": "若昂·菲利克斯", "short_name": "菲利克斯", "nationality": "葡萄牙",
        "positions": ["CF", "CAM", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 80, "passing": 80, "dribbling": 88, "defending": 40, "physical": 65},
        "traits": ["dribbling_master", "flair", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.08, "body_type": "slim", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "benfica", "era": "本菲卡时期", "years": "2018-2019", "jersey": 79, "adj": -2},
            {"club": "atletico_madrid", "era": "马竞时期", "years": "2019-至今", "jersey": 7, "adj": 0},
            {"club": "chelsea", "era": "切尔西租借", "years": "2023", "jersey": 11, "adj": -1},
            {"club": "barcelona", "era": "巴萨租借", "years": "2023-2024", "jersey": 14, "adj": -1},
            {"club": "portugal", "era": "国家队", "years": "2019-至今", "jersey": 23, "adj": 1, "is_national": True},
        ],
    },
    "havertz": {
        "name": "凯·哈弗茨", "short_name": "哈弗茨", "nationality": "德国",
        "positions": ["CF", "ST", "CAM"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 80, "dribbling": 84, "defending": 50, "physical": 82},
        "traits": ["header", "playmaker"],
        "skills": ["air_dominance", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.15, "body_type": "slim", "skin_tone": "#F2C49B", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "leverkusen", "era": "勒沃库森时期", "years": "2016-2020", "jersey": 29, "adj": -2},
            {"club": "chelsea", "era": "切尔西时期", "years": "2020-2023", "jersey": 29, "adj": 0},
            {"club": "arsenal", "era": "阿森纳时期", "years": "2023-至今", "jersey": 29, "adj": 2},
            {"club": "germany", "era": "国家队", "years": "2018-至今", "jersey": 7, "adj": 1, "is_national": True},
        ],
    },
    "declan_rice": {
        "name": "德克兰·赖斯", "short_name": "赖斯", "nationality": "英格兰",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 78, "shooting": 70, "passing": 82, "dribbling": 78, "defending": 85, "physical": 88},
        "traits": ["iron_wall", "box_to_box", "leader"],
        "skills": ["iron_wall", "pinpoint_pass", "endless_runner"],
        "appearance": {"height_mult": 1.1, "body_type": "muscular", "skin_tone": "#F2C49B", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "west_ham", "era": "西汉姆时期", "years": "2017-2023", "jersey": 41, "adj": -2},
            {"club": "arsenal", "era": "阿森纳时期", "years": "2023-至今", "jersey": 41, "adj": 3},
            {"club": "england", "era": "国家队", "years": "2019-至今", "jersey": 4, "adj": 2, "is_national": True},
        ],
    },
    "mac_allister": {
        "name": "亚历克西斯·麦卡利斯特", "short_name": "麦卡利斯特", "nationality": "阿根廷",
        "positions": ["CM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 78, "passing": 85, "dribbling": 84, "defending": 70, "physical": 75},
        "traits": ["playmaker", "free_kick"],
        "skills": ["vision_pass", "pinpoint_pass", "curve_shot"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#5A3D1E"},
        "versions": [
            {"club": "boca_juniors", "era": "博卡青年时期", "years": "2016-2019", "jersey": 8, "adj": -5},
            {"club": "brighton", "era": "布莱顿时期", "years": "2019-2023", "jersey": 10, "adj": 0},
            {"club": "liverpool", "era": "利物浦时期", "years": "2023-至今", "jersey": 10, "adj": 3},
            {"club": "argentina", "era": "国家队", "years": "2019-至今", "jersey": 20, "adj": 2, "is_national": True},
        ],
    },
    "szoboszlai": {
        "name": "多米尼克·索博斯洛伊", "short_name": "索博斯洛伊", "nationality": "匈牙利",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 84, "dribbling": 84, "defending": 60, "physical": 75},
        "traits": ["long_shot", "free_kick", "playmaker"],
        "skills": ["power_shot", "vision_pass", "curve_shot"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#C8B88A"},
        "versions": [
            {"club": "salzburg", "era": "萨尔茨堡时期", "years": "2018-2021", "jersey": 18, "adj": -3},
            {"club": "leipzig", "era": "莱比锡时期", "years": "2021-2023", "jersey": 17, "adj": 0},
            {"club": "liverpool", "era": "利物浦时期", "years": "2023-至今", "jersey": 8, "adj": 2},
            {"club": "hungary", "era": "国家队", "years": "2019-至今", "jersey": 10, "adj": 1, "is_national": True},
        ],
    },
    "wirtz": {
        "name": "弗洛里安·维尔茨", "short_name": "维尔茨", "nationality": "德国",
        "positions": ["CAM", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 82, "shooting": 78, "passing": 85, "dribbling": 88, "defending": 45, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "slim", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#D9C28A"},
        "versions": [
            {"club": "leverkusen", "era": "勒沃库森时期", "years": "2020-至今", "jersey": 10, "adj": 0},
            {"club": "germany", "era": "国家队", "years": "2021-至今", "jersey": 17, "adj": 0, "is_national": True},
        ],
    },
    "gvardiol_transfer": {
        "name": "约什科·格瓦迪奥尔", "short_name": "格瓦迪奥尔", "nationality": "克罗地亚",
        "positions": ["CB", "LB"], "preferred_foot": "left",
        "base_attributes": {"pace": 78, "shooting": 55, "passing": 70, "dribbling": 72, "defending": 85, "physical": 84},
        "traits": ["iron_wall", "header"],
        "skills": ["iron_wall", "air_dominance", "speed_burst"],
        "appearance": {"height_mult": 1.1, "body_type": "muscular", "skin_tone": "#F2C49B", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "dinamo_zagreb", "era": "萨格勒布迪纳摩时期", "years": "2019-2021", "jersey": 5, "adj": -5},
            {"club": "leipzig", "era": "莱比锡时期", "years": "2021-2023", "jersey": 32, "adj": 0},
            {"club": "man_city", "era": "曼城时期", "years": "2023-至今", "jersey": 24, "adj": 2},
            {"club": "croatia", "era": "国家队", "years": "2021-至今", "jersey": 20, "adj": 1, "is_national": True},
        ],
    },
    "kvaratskhelia": {
        "name": "赫维恰·克瓦拉茨赫利亚", "short_name": "克瓦拉", "nationality": "格鲁吉亚",
        "positions": ["LW", "LM"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 80, "passing": 78, "dribbling": 90, "defending": 40, "physical": 72},
        "traits": ["dribbling_master", "flair"],
        "skills": ["ghost_dribble", "speed_burst", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "dinamo_batumi", "era": "巴统迪纳摩时期", "years": "2021", "jersey": 77, "adj": -5},
            {"club": "rubin_kazan", "era": "喀山红宝石时期", "years": "2019-2022", "jersey": 9, "adj": -3},
            {"club": "napoli", "era": "那不勒斯时期", "years": "2022-至今", "jersey": 77, "adj": 2},
            {"club": "georgia", "era": "国家队", "years": "2019-至今", "jersey": 7, "adj": 1, "is_national": True},
        ],
    },
    "osimhen": {
        "name": "维克托·奥斯梅恩", "short_name": "奥斯梅恩", "nationality": "尼日利亚",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 90, "shooting": 88, "passing": 65, "dribbling": 80, "defending": 40, "physical": 85},
        "traits": ["speedster", "header", "long_shot"],
        "skills": ["speed_burst", "air_dominance", "power_shot"],
        "appearance": {"height_mult": 1.1, "body_type": "muscular", "skin_tone": "#5A3D2A", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "lille", "era": "里尔时期", "years": "2019-2020", "jersey": 7, "adj": -3},
            {"club": "napoli", "era": "那不勒斯时期", "years": "2020-至今", "jersey": 9, "adj": 2},
            {"club": "nigeria", "era": "国家队", "years": "2017-至今", "jersey": 9, "adj": 1, "is_national": True},
        ],
    },
    "leao_transfer": {
        "name": "拉斐尔·莱奥", "short_name": "莱奥", "nationality": "葡萄牙",
        "positions": ["LW", "ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 93, "shooting": 80, "passing": 75, "dribbling": 88, "defending": 30, "physical": 78},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#5A3D2A", "hair_style": "curly_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "lille", "era": "里尔时期", "years": "2018-2019", "jersey": 9, "adj": -3},
            {"club": "ac_milan", "era": "AC米兰时期", "years": "2019-至今", "jersey": 10, "adj": 2},
            {"club": "portugal", "era": "国家队", "years": "2021-至今", "jersey": 15, "adj": 1, "is_national": True},
        ],
    },
    "kane_transfer": {
        "name": "哈里·凯恩", "short_name": "凯恩", "nationality": "英格兰",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 70, "shooting": 93, "passing": 84, "dribbling": 80, "defending": 45, "physical": 85},
        "traits": ["long_shot", "header", "playmaker"],
        "skills": ["power_shot", "air_dominance", "vision_pass"],
        "appearance": {"height_mult": 1.1, "body_type": "muscular", "skin_tone": "#F2C49B", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "tottenham", "era": "热刺时期", "years": "2009-2023", "jersey": 10, "adj": 0},
            {"club": "bayern_munich", "era": "拜仁时期", "years": "2023-至今", "jersey": 9, "adj": 2},
            {"club": "england", "era": "国家队", "years": "2015-至今", "jersey": 9, "adj": 1, "is_national": True},
        ],
    },
    "bellingham_transfer": {
        "name": "裘德·贝林厄姆", "short_name": "贝林厄姆", "nationality": "英格兰",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 85, "passing": 85, "dribbling": 87, "defending": 75, "physical": 82},
        "traits": ["box_to_box", "playmaker", "leader"],
        "skills": ["vision_pass", "endless_runner", "clutch_player"],
        "appearance": {"height_mult": 1.1, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "short_brown", "hair_color": "#3A2A1A"},
        "versions": [
            {"club": "birmingham", "era": "伯明翰时期", "years": "2019-2020", "jersey": 22, "adj": -8},
            {"club": "dortmund", "era": "多特蒙德时期", "years": "2020-2023", "jersey": 22, "adj": 0},
            {"club": "real_madrid", "era": "皇马时期", "years": "2023-至今", "jersey": 5, "adj": 3},
            {"club": "england", "era": "国家队", "years": "2020-至今", "jersey": 26, "adj": 2, "is_national": True},
        ],
    },
}

def generate_players():
    players = {}
    for base_id, base_data in TRANSFER_PLAYERS.items():
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
    output_path = os.path.join(os.path.dirname(__file__), "..", "data", "transfer_players.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"players": players}, f, ensure_ascii=False, indent=2)
    print(f"已生成 {len(players)} 张转会历史球员卡到 {output_path}")

    # 显示恩佐的所有版本
    print("\n恩佐·费尔南德斯的卡牌版本:")
    for pid in players:
        if pid.startswith("enzo_fernandez_"):
            p = players[pid]
            print(f"  {pid}: {p['era']} #{p['jersey_number']} ({p['years']})")

if __name__ == "__main__":
    main()
