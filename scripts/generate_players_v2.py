#!/usr/bin/env python3
"""
重新设计球员数据库
关键改动：同一球员在不同俱乐部 = 不同的卡
例如：C罗在皇马、曼联、尤文是3张不同的卡
每张卡绑定：球员基础ID + 俱乐部 + 球衣号码 + 时期
"""
import json
import os

# 球员基础数据（不含俱乐部信息）
PLAYER_BASE = {
    "c_ronaldo": {
        "name": "克里斯蒂亚诺·罗纳尔多", "short_name": "C罗", "nationality": "葡萄牙",
        "positions": ["LW", "ST", "RW"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 94, "passing": 82, "dribbling": 87, "defending": 35, "physical": 80},
        "traits": ["long_shot", "header", "free_kick"],
        "skills": ["speed_burst", "power_shot", "clutch_player"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "slick_back", "hair_color": "#261810"},
    },
    "messi": {
        "name": "利昂内尔·梅西", "short_name": "梅西", "nationality": "阿根廷",
        "positions": ["RW", "CF", "CAM"], "preferred_foot": "left",
        "base_attributes": {"pace": 85, "shooting": 92, "passing": 91, "dribbling": 95, "defending": 35, "physical": 65},
        "traits": ["dribbling_master", "playmaker", "free_kick"],
        "skills": ["ghost_dribble", "vision_pass", "curve_shot"],
        "appearance": {"height_mult": 0.92, "body_type": "stocky", "skin_tone": "#E8B888", "hair_style": "medium_brown", "hair_color": "#5A3D1E"},
    },
    "haaland": {
        "name": "厄林·哈兰德", "short_name": "哈兰德", "nationality": "挪威",
        "positions": ["ST"], "preferred_foot": "left",
        "base_attributes": {"pace": 91, "shooting": 93, "passing": 66, "dribbling": 80, "defending": 45, "physical": 88},
        "traits": ["long_shot", "header", "power_header"],
        "skills": ["speed_burst", "power_shot", "clutch_player"],
        "appearance": {"height_mult": 1.15, "body_type": "muscular", "skin_tone": "#F0C8A0", "hair_style": "short_blonde", "hair_color": "#D9BF80"},
    },
    "mbappe": {
        "name": "基利安·姆巴佩", "short_name": "姆巴佩", "nationality": "法国",
        "positions": ["ST", "LW", "RW"], "preferred_foot": "right",
        "base_attributes": {"pace": 97, "shooting": 90, "passing": 80, "dribbling": 92, "defending": 36, "physical": 78},
        "traits": ["speedster", "dribbling_master", "clinical_finisher"],
        "skills": ["speed_burst", "ghost_dribble", "power_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#8C5A3C", "hair_style": "short_curly", "hair_color": "#1A1208"},
    },
    "bellingham": {
        "name": "裘德·贝林厄姆", "short_name": "贝林厄姆", "nationality": "英格兰",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 80, "shooting": 85, "passing": 86, "dribbling": 87, "defending": 75, "physical": 82},
        "traits": ["box_to_box", "playmaker"],
        "skills": ["endless_runner", "vision_pass", "clutch_player"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#C8A080", "hair_style": "short_brown", "hair_color": "#3A2818"},
    },
    "vinicius": {
        "name": "维尼修斯·儒尼奥尔", "short_name": "维尼修斯", "nationality": "巴西",
        "positions": ["LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 95, "shooting": 83, "passing": 78, "dribbling": 90, "defending": 30, "physical": 70},
        "traits": ["speedster", "dribbling_master", "flair"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#5A3520", "hair_style": "curly", "hair_color": "#0A0805"},
    },
    "de_bruyne": {
        "name": "凯文·德布劳内", "short_name": "德布劳内", "nationality": "比利时",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 70, "shooting": 86, "passing": 93, "dribbling": 86, "defending": 64, "physical": 78},
        "traits": ["playmaker", "long_shot", "free_kick"],
        "skills": ["vision_pass", "pinpoint_pass", "curve_shot"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#F0C8A0", "hair_style": "short_blonde", "hair_color": "#D9A850"},
    },
    "salah": {
        "name": "穆罕默德·萨拉赫", "short_name": "萨拉赫", "nationality": "埃及",
        "positions": ["RW", "ST"], "preferred_foot": "left",
        "base_attributes": {"pace": 93, "shooting": 88, "passing": 81, "dribbling": 88, "defending": 45, "physical": 75},
        "traits": ["speedster", "clinical_finisher", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "power_shot"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#A06840", "hair_style": "short_black", "hair_color": "#1A1208"},
    },
    "kane": {
        "name": "哈里·凯恩", "short_name": "凯恩", "nationality": "英格兰",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 68, "shooting": 93, "passing": 84, "dribbling": 83, "defending": 47, "physical": 83},
        "traits": ["clinical_finisher", "playmaker", "header"],
        "skills": ["power_shot", "vision_pass", "air_dominance"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_blonde", "hair_color": "#B89860"},
    },
    "rodri": {
        "name": "罗德里", "short_name": "罗德里", "nationality": "西班牙",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 62, "shooting": 75, "passing": 85, "dribbling": 78, "defending": 82, "physical": 85},
        "traits": ["iron_wall", "playmaker"],
        "skills": ["iron_wall", "pinpoint_pass", "interceptor"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#3A2818"},
    },
    "foden": {
        "name": "菲尔·福登", "short_name": "福登", "nationality": "英格兰",
        "positions": ["CAM", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 82, "passing": 84, "dribbling": 88, "defending": 55, "physical": 65},
        "traits": ["dribbling_master", "playmaker"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 0.95, "body_type": "slim", "skin_tone": "#F0C8A0", "hair_style": "short_blonde", "hair_color": "#C8A860"},
    },
    "saka": {
        "name": "布卡约·萨卡", "short_name": "萨卡", "nationality": "英格兰",
        "positions": ["RW", "LW"], "preferred_foot": "left",
        "base_attributes": {"pace": 86, "shooting": 80, "passing": 82, "dribbling": 86, "defending": 60, "physical": 70},
        "traits": ["dribbling_master", "crossing"],
        "skills": ["ghost_dribble", "pinpoint_pass", "endless_runner"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#5A3520", "hair_style": "short_black", "hair_color": "#0A0805"},
    },
    "odegaard": {
        "name": "马丁·厄德高", "short_name": "厄德高", "nationality": "挪威",
        "positions": ["CAM", "CM"], "preferred_foot": "left",
        "base_attributes": {"pace": 76, "shooting": 82, "passing": 88, "dribbling": 87, "defending": 55, "physical": 65},
        "traits": ["playmaker", "dribbling_master"],
        "skills": ["vision_pass", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.0, "body_type": "slim", "skin_tone": "#F0C8A0", "hair_style": "short_blonde", "hair_color": "#C8A860"},
    },
    "rice": {
        "name": "德克兰·赖斯", "short_name": "赖斯", "nationality": "英格兰",
        "positions": ["CDM", "CM"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 70, "passing": 82, "dribbling": 78, "defending": 85, "physical": 85},
        "traits": ["iron_wall", "box_to_box"],
        "skills": ["iron_wall", "interceptor", "endless_runner"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#3A2818"},
    },
    "lautaro": {
        "name": "劳塔罗·马丁内斯", "short_name": "劳塔罗", "nationality": "阿根廷",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 82, "shooting": 88, "passing": 75, "dribbling": 84, "defending": 40, "physical": 80},
        "traits": ["clinical_finisher", "header"],
        "skills": ["power_shot", "air_dominance", "clutch_player"],
        "appearance": {"height_mult": 0.98, "body_type": "athletic", "skin_tone": "#C8A080", "hair_style": "short_black", "hair_color": "#1A1208"},
    },
    "leao": {
        "name": "拉斐尔·莱奥", "short_name": "莱奥", "nationality": "葡萄牙",
        "positions": ["LW", "ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 93, "shooting": 80, "passing": 76, "dribbling": 87, "defending": 30, "physical": 78},
        "traits": ["speedster", "dribbling_master"],
        "skills": ["speed_burst", "ghost_dribble", "first_touch"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#8C5A3C", "hair_style": "short_curly", "hair_color": "#0A0805"},
    },
    "kvaratskhelia": {
        "name": "赫维恰·克瓦拉茨赫利亚", "short_name": "K77", "nationality": "格鲁吉亚",
        "positions": ["LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 85, "shooting": 80, "passing": 78, "dribbling": 88, "defending": 35, "physical": 72},
        "traits": ["dribbling_master", "flair"],
        "skills": ["ghost_dribble", "first_touch", "curve_shot"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "medium_brown", "hair_color": "#3A2818"},
    },
    "vandijk": {
        "name": "维尔吉尔·范迪克", "short_name": "范迪克", "nationality": "荷兰",
        "positions": ["CB"], "preferred_foot": "right",
        "base_attributes": {"pace": 78, "shooting": 60, "passing": 74, "dribbling": 72, "defending": 90, "physical": 86},
        "traits": ["iron_wall", "header", "leader"],
        "skills": ["iron_wall", "air_dominance", "wall_defense"],
        "appearance": {"height_mult": 1.12, "body_type": "muscular", "skin_tone": "#D9A87A", "hair_style": "short_blonde", "hair_color": "#D9A850"},
    },
    "ruben_dias": {
        "name": "鲁本·迪亚斯", "short_name": "迪亚斯", "nationality": "葡萄牙",
        "positions": ["CB"], "preferred_foot": "right",
        "base_attributes": {"pace": 72, "shooting": 55, "passing": 72, "dribbling": 70, "defending": 88, "physical": 85},
        "traits": ["iron_wall", "leader"],
        "skills": ["iron_wall", "interceptor", "wall_defense"],
        "appearance": {"height_mult": 1.05, "body_type": "muscular", "skin_tone": "#E8B888", "hair_style": "short_brown", "hair_color": "#3A2818"},
    },
    "courtois": {
        "name": "蒂博·库尔图瓦", "short_name": "库尔图瓦", "nationality": "比利时",
        "positions": ["GK"], "preferred_foot": "left",
        "base_attributes": {"gk_diving": 87, "gk_handling": 86, "gk_kicking": 82, "gk_reflexes": 88, "gk_positioning": 85},
        "traits": ["gk_saver", "gk_1v1", "gk_leader"],
        "skills": ["gk_reflex_save", "gk_1v1_master", "wall_defense"],
        "appearance": {"height_mult": 1.15, "body_type": "muscular", "skin_tone": "#F0C8A0", "hair_style": "short_blonde", "hair_color": "#B89860"},
    },
    "alisson": {
        "name": "阿利松·贝克尔", "short_name": "阿利松", "nationality": "巴西",
        "positions": ["GK"], "preferred_foot": "right",
        "base_attributes": {"gk_diving": 85, "gk_handling": 85, "gk_kicking": 87, "gk_reflexes": 86, "gk_positioning": 86},
        "traits": ["sweeper_keeper", "gk_1v1", "gk_saver"],
        "skills": ["sweeper_keeper", "gk_1v1_master", "gk_reflex_save"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#A06840", "hair_style": "short_curly", "hair_color": "#1A1208"},
    },
    "neuer": {
        "name": "曼努埃尔·诺伊尔", "short_name": "诺伊尔", "nationality": "德国",
        "positions": ["GK"], "preferred_foot": "right",
        "base_attributes": {"gk_diving": 84, "gk_handling": 85, "gk_kicking": 93, "gk_reflexes": 85, "gk_positioning": 87},
        "traits": ["sweeper_keeper", "gk_leader", "gk_distribution"],
        "skills": ["sweeper_keeper", "gk_1v1_master", "gk_reflex_save"],
        "appearance": {"height_mult": 1.12, "body_type": "muscular", "skin_tone": "#F0C8A0", "hair_style": "short_brown", "hair_color": "#3A2818"},
    },
}

# 球员在不同俱乐部的卡牌版本
# 格式: base_id -> [{club, years, jersey_number, rating_modifier, era_name}]
PLAYER_CLUB_VERSIONS = {
    "c_ronaldo": [
        {"club": "sporting_cp", "years": "2002-2003", "jersey": 28, "rating_mod": -8, "era": "里斯本竞技时期"},
        {"club": "man_united", "years": "2003-2009", "jersey": 7, "rating_mod": 0, "era": "曼联一期"},
        {"club": "real_madrid", "years": "2009-2018", "jersey": 7, "rating_mod": 5, "era": "皇马巅峰"},
        {"club": "juventus", "years": "2018-2021", "jersey": 7, "rating_mod": 2, "era": "尤文时期"},
        {"club": "man_united", "years": "2021-2022", "jersey": 7, "rating_mod": -3, "era": "曼联二期"},
        {"club": "al_nassr", "years": "2023-至今", "jersey": 7, "rating_mod": -5, "era": "利雅得胜利"},
    ],
    "messi": [
        {"club": "barcelona", "years": "2004-2021", "jersey": 10, "rating_mod": 5, "era": "巴萨巅峰"},
        {"club": "psg", "years": "2021-2023", "jersey": 30, "rating_mod": -2, "era": "巴黎时期"},
        {"club": "inter_miami", "years": "2023-至今", "jersey": 10, "rating_mod": -5, "era": "迈阿密国际"},
    ],
    "haaland": [
        {"club": "molde", "years": "2017-2018", "jersey": 30, "rating_mod": -10, "era": "莫尔德时期"},
        {"club": "salzburg", "years": "2019-2020", "jersey": 30, "rating_mod": -5, "era": "萨尔茨堡时期"},
        {"club": "dortmund", "years": "2020-2022", "jersey": 9, "rating_mod": 0, "era": "多特时期"},
        {"club": "man_city", "years": "2022-至今", "jersey": 9, "rating_mod": 3, "era": "曼城时期"},
    ],
    "mbappe": [
        {"club": "monaco", "years": "2015-2017", "jersey": 29, "rating_mod": -8, "era": "摩纳哥时期"},
        {"club": "psg", "years": "2017-2024", "jersey": 7, "rating_mod": 2, "era": "巴黎时期"},
        {"club": "real_madrid", "years": "2024-至今", "jersey": 9, "rating_mod": 3, "era": "皇马时期"},
    ],
    "bellingham": [
        {"club": "birmingham", "years": "2019-2020", "jersey": 22, "rating_mod": -10, "era": "伯明翰时期"},
        {"club": "dortmund", "years": "2020-2023", "jersey": 22, "rating_mod": 0, "era": "多特时期"},
        {"club": "real_madrid", "years": "2023-至今", "jersey": 5, "rating_mod": 5, "era": "皇马时期"},
    ],
    "vinicius": [
        {"club": "flamengo", "years": "2017-2018", "jersey": 11, "rating_mod": -8, "era": "弗拉门戈时期"},
        {"club": "real_madrid", "years": "2018-至今", "jersey": 7, "rating_mod": 3, "era": "皇马时期"},
    ],
    "de_bruyne": [
        {"club": "werder_bremen", "years": "2012-2014", "jersey": 22, "rating_mod": -8, "era": "不莱梅时期"},
        {"club": "wolfsburg", "years": "2014-2015", "jersey": 17, "rating_mod": -3, "era": "狼堡时期"},
        {"club": "man_city", "years": "2015-至今", "jersey": 17, "rating_mod": 3, "era": "曼城时期"},
    ],
    "salah": [
        {"club": "roma", "years": "2015-2017", "jersey": 11, "rating_mod": -5, "era": "罗马时期"},
        {"club": "liverpool", "years": "2017-至今", "jersey": 11, "rating_mod": 3, "era": "利物浦时期"},
    ],
    "kane": [
        {"club": "tottenham", "years": "2009-2023", "jersey": 10, "rating_mod": 0, "era": "热刺时期"},
        {"club": "bayern_munich", "years": "2023-至今", "jersey": 9, "rating_mod": 3, "era": "拜仁时期"},
    ],
    "rodri": [
        {"club": "atletico_madrid", "years": "2018-2019", "jersey": 14, "rating_mod": -3, "era": "马竞时期"},
        {"club": "man_city", "years": "2019-至今", "jersey": 16, "rating_mod": 3, "era": "曼城时期"},
    ],
    "foden": [
        {"club": "man_city", "years": "2017-至今", "jersey": 47, "rating_mod": 0, "era": "曼城时期"},
    ],
    "saka": [
        {"club": "arsenal", "years": "2018-至今", "jersey": 7, "rating_mod": 0, "era": "阿森纳时期"},
    ],
    "odegaard": [
        {"club": "real_madrid", "years": "2015-2021", "jersey": 21, "rating_mod": -5, "era": "皇马时期"},
        {"club": "arsenal", "years": "2021-至今", "jersey": 8, "rating_mod": 3, "era": "阿森纳时期"},
    ],
    "rice": [
        {"club": "west_ham", "years": "2017-2023", "jersey": 41, "rating_mod": 0, "era": "西汉姆时期"},
        {"club": "arsenal", "years": "2023-至今", "jersey": 41, "rating_mod": 3, "era": "阿森纳时期"},
    ],
    "lautaro": [
        {"club": "racing_club", "years": "2016-2018", "jersey": 10, "rating_mod": -8, "era": "竞技俱乐部时期"},
        {"club": "inter_milan", "years": "2018-至今", "jersey": 10, "rating_mod": 3, "era": "国米时期"},
    ],
    "leao": [
        {"club": "sporting_cp", "years": "2017-2018", "jersey": 30, "rating_mod": -8, "era": "葡萄牙体育时期"},
        {"club": "ac_milan", "years": "2018-至今", "jersey": 10, "rating_mod": 3, "era": "AC米兰时期"},
    ],
    "kvaratskhelia": [
        {"club": "dinamo_batumi", "years": "2021-2022", "jersey": 77, "rating_mod": -10, "era": "巴统迪纳摩时期"},
        {"club": "napoli", "years": "2022-至今", "jersey": 77, "rating_mod": 3, "era": "那不勒斯时期"},
    ],
    "vandijk": [
        {"club": "celtic", "years": "2013-2015", "jersey": 5, "rating_mod": -8, "era": "凯尔特人时期"},
        {"club": "southampton", "years": "2015-2018", "jersey": 17, "rating_mod": -3, "era": "南安普顿时期"},
        {"club": "liverpool", "years": "2018-至今", "jersey": 4, "rating_mod": 3, "era": "利物浦时期"},
    ],
    "ruben_dias": [
        {"club": "benfica", "years": "2015-2020", "jersey": 4, "rating_mod": -3, "era": "本菲卡时期"},
        {"club": "man_city", "years": "2020-至今", "jersey": 3, "rating_mod": 3, "era": "曼城时期"},
    ],
    "courtois": [
        {"club": "atletico_madrid", "years": "2011-2014", "jersey": 13, "rating_mod": -3, "era": "马竞时期"},
        {"club": "chelsea", "years": "2014-2018", "jersey": 13, "rating_mod": -3, "era": "切尔西时期"},
        {"club": "real_madrid", "years": "2018-至今", "jersey": 1, "rating_mod": 3, "era": "皇马时期"},
    ],
    "alisson": [
        {"club": "roma", "years": "2016-2018", "jersey": 1, "rating_mod": -3, "era": "罗马时期"},
        {"club": "liverpool", "years": "2018-至今", "jersey": 1, "rating_mod": 3, "era": "利物浦时期"},
    ],
    "neuer": [
        {"club": "schalke", "years": "2006-2011", "jersey": 1, "rating_mod": -3, "era": "沙尔克时期"},
        {"club": "bayern_munich", "years": "2011-至今", "jersey": 1, "rating_mod": 3, "era": "拜仁时期"},
    ],
}

def generate_players():
    players = {}
    for base_id, base_data in PLAYER_BASE.items():
        versions = PLAYER_CLUB_VERSIONS.get(base_id, [])
        for i, ver in enumerate(versions):
            # 卡牌ID格式: base_id_club_era_index
            card_id = f"{base_id}_{ver['club']}_{i}"
            
            # 根据时期调整属性
            adjusted_attrs = {}
            for attr, val in base_data["base_attributes"].items():
                adjusted_attrs[attr] = max(40, min(99, val + ver.get("rating_mod", 0)))
            
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
            }
    return players

def main():
    players = generate_players()
    output_path = os.path.join(os.path.dirname(__file__), "..", "data", "players.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"players": players}, f, ensure_ascii=False, indent=2)
    print(f"已生成 {len(players)} 张球员卡到 {output_path}")
    
    # 统计
    base_count = len(PLAYER_BASE)
    total_cards = len(players)
    print(f"基础球员: {base_count} 人")
    print(f"总卡牌数: {total_cards} 张（含不同俱乐部版本）")
    
    # 显示C罗的所有版本
    print("\nC罗的所有卡牌版本:")
    for pid in players:
        if pid.startswith("c_ronaldo_"):
            p = players[pid]
            print(f"  {pid}: {p['era']} #{p['jersey_number']}")

if __name__ == "__main__":
    main()
