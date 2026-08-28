#!/usr/bin/env python3
"""
扩充球员数据库 v4
新增：更多现役球员 + 历史经典球员 + 大使球员
"""
import json
import os

# 历史经典球员（退役传奇）
LEGEND_PLAYERS = {
    "pele": {
        "name": "贝利", "short_name": "贝利", "nationality": "巴西",
        "positions": ["ST", "CF"], "preferred_foot": "right",
        "base_attributes": {"pace": 88, "shooting": 96, "passing": 85, "dribbling": 96, "defending": 40, "physical": 75},
        "traits": ["dribbling_master", "header", "long_shot"],
        "skills": ["ghost_dribble", "power_shot", "clutch_player"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "santos", "era": "桑托斯传奇", "years": "1956-1974", "jersey": 10, "adj": 5, "is_legend": True},
            {"club": "brazil", "era": "国家队传奇", "years": "1957-1971", "jersey": 10, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "maradona": {
        "name": "迭戈·马拉多纳", "short_name": "马拉多纳", "nationality": "阿根廷",
        "positions": ["CAM", "CF"], "preferred_foot": "left",
        "base_attributes": {"pace": 85, "shooting": 89, "passing": 90, "dribbling": 97, "defending": 30, "physical": 70},
        "traits": ["dribbling_master", "playmaker", "free_kick"],
        "skills": ["ghost_dribble", "vision_pass", "curve_shot"],
        "appearance": {"height_mult": 0.95, "body_type": "stocky", "skin_tone": "#D9A87A", "hair_style": "curly_black", "hair_color": "#2A1A0A"},
        "versions": [
            {"club": "napoli", "era": "那不勒斯传奇", "years": "1984-1991", "jersey": 10, "adj": 5, "is_legend": True},
            {"club": "argentina", "era": "国家队传奇", "years": "1977-1994", "jersey": 10, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "zidane": {
        "name": "齐内丁·齐达内", "short_name": "齐达内", "nationality": "法国",
        "positions": ["CAM", "CM"], "preferred_foot": "left",
        "base_attributes": {"pace": 80, "shooting": 85, "passing": 93, "dribbling": 95, "defending": 60, "physical": 80},
        "traits": ["dribbling_master", "playmaker", "long_shot"],
        "skills": ["ghost_dribble", "vision_pass", "first_touch"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#E8B888", "hair_style": "bald", "hair_color": "#000000"},
        "versions": [
            {"club": "juventus", "era": "尤文时期", "years": "1996-2001", "jersey": 21, "adj": 2, "is_legend": True},
            {"club": "real_madrid", "era": "皇马传奇", "years": "2001-2006", "jersey": 5, "adj": 5, "is_legend": True},
            {"club": "france", "era": "国家队传奇", "years": "1994-2006", "jersey": 10, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "ronaldinho": {
        "name": "罗纳尔迪尼奥", "short_name": "小罗", "nationality": "巴西",
        "positions": ["LW", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 87, "shooting": 88, "passing": 90, "dribbling": 97, "defending": 35, "physical": 72},
        "traits": ["dribbling_master", "playmaker", "free_kick"],
        "skills": ["ghost_dribble", "curve_shot", "clutch_player"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "long_curly", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "barcelona", "era": "巴萨巅峰", "years": "2003-2008", "jersey": 10, "adj": 5, "is_legend": True},
            {"club": "brazil", "era": "国家队传奇", "years": "1999-2013", "jersey": 10, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "beckham": {
        "name": "大卫·贝克汉姆", "short_name": "贝克汉姆", "nationality": "英格兰",
        "positions": ["RM", "CAM"], "preferred_foot": "right",
        "base_attributes": {"pace": 78, "shooting": 85, "passing": 92, "dribbling": 82, "defending": 55, "physical": 72},
        "traits": ["crossing", "free_kick", "playmaker"],
        "skills": ["pinpoint_pass", "curve_shot", "vision_pass"],
        "appearance": {"height_mult": 1.0, "body_type": "athletic", "skin_tone": "#F2C49B", "hair_style": "slick_blonde", "hair_color": "#C8A878"},
        "versions": [
            {"club": "man_united", "era": "曼联传奇", "years": "1992-2003", "jersey": 7, "adj": 5, "is_legend": True},
            {"club": "real_madrid", "era": "皇马时期", "years": "2003-2007", "jersey": 23, "adj": 2, "is_legend": True},
            {"club": "england", "era": "国家队传奇", "years": "1996-2009", "jersey": 7, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "ronaldo_r9": {
        "name": "罗纳尔多·纳扎里奥", "short_name": "大罗", "nationality": "巴西",
        "positions": ["ST"], "preferred_foot": "right",
        "base_attributes": {"pace": 93, "shooting": 94, "passing": 80, "dribbling": 96, "defending": 35, "physical": 82},
        "traits": ["speedster", "dribbling_master", "long_shot"],
        "skills": ["speed_burst", "ghost_dribble", "power_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "barcelona", "era": "巴萨时期", "years": "1996-1997", "jersey": 9, "adj": 3, "is_legend": True},
            {"club": "real_madrid", "era": "皇马传奇", "years": "2002-2007", "jersey": 11, "adj": 5, "is_legend": True},
            {"club": "brazil", "era": "国家队传奇", "years": "1994-2011", "jersey": 9, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "maldini": {
        "name": "保罗·马尔蒂尼", "short_name": "马尔蒂尼", "nationality": "意大利",
        "positions": ["CB", "LB"], "preferred_foot": "right",
        "base_attributes": {"pace": 82, "shooting": 50, "passing": 75, "dribbling": 75, "defending": 95, "physical": 85},
        "traits": ["iron_wall", "header", "speedster"],
        "skills": ["iron_wall", "interceptor", "wall_defense"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#F2C49B", "hair_style": "short_black", "hair_color": "#2A1A0A"},
        "versions": [
            {"club": "ac_milan", "era": "AC米兰传奇", "years": "1985-2009", "jersey": 3, "adj": 5, "is_legend": True},
            {"club": "italy", "era": "国家队传奇", "years": "1988-2002", "jersey": 3, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
    "henry": {
        "name": "蒂埃里·亨利", "short_name": "亨利", "nationality": "法国",
        "positions": ["ST", "LW"], "preferred_foot": "right",
        "base_attributes": {"pace": 92, "shooting": 90, "passing": 82, "dribbling": 90, "defending": 40, "physical": 78},
        "traits": ["speedster", "dribbling_master", "long_shot"],
        "skills": ["speed_burst", "ghost_dribble", "curve_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_black", "hair_color": "#1A1A1A"},
        "versions": [
            {"club": "arsenal", "era": "阿森纳传奇", "years": "1999-2007", "jersey": 14, "adj": 5, "is_legend": True},
            {"club": "france", "era": "国家队传奇", "years": "1997-2010", "jersey": 12, "adj": 5, "is_national": True, "is_legend": True},
        ],
    },
}

# 大使球员（特殊版本，加强属性）
AMBASSADOR_PLAYERS = {
    "c_ronaldo_ambassador": {
        "name": "克里斯蒂亚诺·罗纳尔多", "short_name": "C罗(大使)", "nationality": "葡萄牙",
        "positions": ["ST", "LW"], "preferred_foot": "right",
        "attributes": {"pace": 92, "shooting": 98, "passing": 85, "dribbling": 90, "defending": 40, "physical": 85},
        "traits": ["long_shot", "header", "free_kick", "power_header"],
        "skills": ["speed_burst", "power_shot", "clutch_player", "air_dominance"],
        "appearance": {"height_mult": 1.08, "body_type": "athletic", "skin_tone": "#D9A87A", "hair_style": "slick_back", "hair_color": "#261810"},
        "club": "ambassador", "era": "大使版本", "years": "特殊", "jersey_number": 7,
        "base_player_id": "c_ronaldo", "version_index": 99,
        "is_ambassador": True, "is_national": False,
    },
    "messi_ambassador": {
        "name": "利昂内尔·梅西", "short_name": "梅西(大使)", "nationality": "阿根廷",
        "positions": ["RW", "CF"], "preferred_foot": "left",
        "attributes": {"pace": 90, "shooting": 95, "passing": 95, "dribbling": 99, "defending": 40, "physical": 70},
        "traits": ["dribbling_master", "playmaker", "free_kick", "long_shot"],
        "skills": ["ghost_dribble", "vision_pass", "curve_shot", "first_touch"],
        "appearance": {"height_mult": 0.92, "body_type": "stocky", "skin_tone": "#E8B888", "hair_style": "medium_brown", "hair_color": "#5A3D1E"},
        "club": "ambassador", "era": "大使版本", "years": "特殊", "jersey_number": 10,
        "base_player_id": "messi", "version_index": 99,
        "is_ambassador": True, "is_national": False,
    },
    "haaland_ambassador": {
        "name": "厄林·哈兰德", "short_name": "哈兰德(大使)", "nationality": "挪威",
        "positions": ["ST"], "preferred_foot": "left",
        "attributes": {"pace": 95, "shooting": 98, "passing": 70, "dribbling": 85, "defending": 50, "physical": 92},
        "traits": ["long_shot", "header", "power_header", "speedster"],
        "skills": ["speed_burst", "power_shot", "clutch_player", "air_dominance"],
        "appearance": {"height_mult": 1.15, "body_type": "muscular", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#D9C28A"},
        "club": "ambassador", "era": "大使版本", "years": "特殊", "jersey_number": 9,
        "base_player_id": "haaland", "version_index": 99,
        "is_ambassador": True, "is_national": False,
    },
    "mbappe_ambassador": {
        "name": "基利安·姆巴佩", "short_name": "姆巴佩(大使)", "nationality": "法国",
        "positions": ["ST", "LW"], "preferred_foot": "right",
        "attributes": {"pace": 98, "shooting": 92, "passing": 82, "dribbling": 92, "defending": 40, "physical": 80},
        "traits": ["speedster", "dribbling_master", "long_shot"],
        "skills": ["speed_burst", "ghost_dribble", "power_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#8B5A2B", "hair_style": "short_curly", "hair_color": "#1A1A1A"},
        "club": "ambassador", "era": "大使版本", "years": "特殊", "jersey_number": 7,
        "base_player_id": "mbappe", "version_index": 99,
        "is_ambassador": True, "is_national": False,
    },
    "bellingham_ambassador": {
        "name": "裘德·贝林厄姆", "short_name": "贝林(大使)", "nationality": "英格兰",
        "positions": ["CAM", "CM"], "preferred_foot": "right",
        "attributes": {"pace": 85, "shooting": 88, "passing": 90, "dribbling": 90, "defending": 75, "physical": 85},
        "traits": ["box_to_box", "playmaker", "long_shot"],
        "skills": ["endless_runner", "vision_pass", "power_shot"],
        "appearance": {"height_mult": 1.05, "body_type": "athletic", "skin_tone": "#F2C49B", "hair_style": "short_blonde", "hair_color": "#C8A878"},
        "club": "ambassador", "era": "大使版本", "years": "特殊", "jersey_number": 5,
        "base_player_id": "bellingham", "version_index": 99,
        "is_ambassador": True, "is_national": False,
    },
}

def generate_players():
    # 读取现有球员数据
    players_path = os.path.join(os.path.dirname(__file__), "..", "data", "players.json")
    with open(players_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    players = data.get("players", {})

    # 添加历史经典球员
    for base_id, base_data in LEGEND_PLAYERS.items():
        for i, ver in enumerate(base_data["versions"]):
            card_id = "%s_%s_%d" % (base_id, ver["club"], i)
            adj = ver.get("adj", 0)
            adjusted_attrs = {}
            for attr, val in base_data["base_attributes"].items():
                adjusted_attrs[attr] = min(99, val + adj)

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
                "is_legend": ver.get("is_legend", False),
            }

    # 添加大使球员
    for card_id, player_data in AMBASSADOR_PLAYERS.items():
        players[card_id] = player_data

    return players

def main():
    players = generate_players()
    output_path = os.path.join(os.path.dirname(__file__), "..", "data", "players.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({"players": players}, f, ensure_ascii=False, indent=2)

    total = len(players)
    legends = sum(1 for p in players.values() if p.get("is_legend"))
    ambassadors = sum(1 for p in players.values() if p.get("is_ambassador"))
    nationals = sum(1 for p in players.values() if p.get("is_national"))

    print(f"总卡牌数: {total}")
    print(f"  历史经典: {legends} 张")
    print(f"  大使球员: {ambassadors} 张")
    print(f"  国家队: {nationals} 张")
    print(f"  俱乐部: {total - nationals - legends - ambassadors} 张")

if __name__ == "__main__":
    main()
