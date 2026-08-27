#!/usr/bin/env python3
"""
扩充联赛和球队数据库
新增：葡超、荷甲、土超、美职联、沙特联、中超、阿根廷联赛、巴西联赛
"""
import json
import os

ADDITIONAL_LEAGUES = {
    "primeira_liga": {"name": "葡萄牙超级联赛", "short_name": "葡超", "country": "葡萄牙", "tier": 1, "team_count": 6, "color": "#006600"},
    "eredivisie": {"name": "荷兰甲级联赛", "short_name": "荷甲", "country": "荷兰", "tier": 1, "team_count": 5, "color": "#FF6600"},
    "super_lig": {"name": "土耳其超级联赛", "short_name": "土超", "country": "土耳其", "tier": 1, "team_count": 4, "color": "#E30A17"},
    "mls": {"name": "美国职业大联盟", "short_name": "美职联", "country": "美国", "tier": 1, "team_count": 4, "color": "#3D195B"},
    "saudi_pro_league": {"name": "沙特职业联赛", "short_name": "沙特联", "country": "沙特", "tier": 1, "team_count": 4, "color": "#006C35"},
    "csl": {"name": "中国超级联赛", "short_name": "中超", "country": "中国", "tier": 1, "team_count": 6, "color": "#DE2910"},
    "argentine_league": {"name": "阿根廷甲级联赛", "short_name": "阿甲", "country": "阿根廷", "tier": 1, "team_count": 4, "color": "#75AADB"},
    "brasileirao": {"name": "巴西甲级联赛", "short_name": "巴甲", "country": "巴西", "tier": 1, "team_count": 4, "color": "#009C3B"},
}

ADDITIONAL_TEAMS = {
    # 葡超
    "benfica": {"name": "本菲卡", "short_name": "本菲卡", "league": "primeira_liga", "city": "里斯本", "country": "葡萄牙", "stadium": "光明球场", "primary_color": "#E30613", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 84, "players": []},
    "porto": {"name": "波尔图", "short_name": "波尔图", "league": "primeira_liga", "city": "波尔图", "country": "葡萄牙", "stadium": "巨龙球场", "primary_color": "#004890", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 82, "players": []},
    "sporting_cp": {"name": "里斯本竞技", "short_name": "葡体", "league": "primeira_liga", "city": "里斯本", "country": "葡萄牙", "stadium": "若泽·阿尔瓦拉德球场", "primary_color": "#008057", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 83, "players": []},
    "braga": {"name": "布拉加", "short_name": "布拉加", "league": "primeira_liga", "city": "布拉加", "country": "葡萄牙", "stadium": "布拉加市政球场", "primary_color": "#B11300", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 78, "players": []},
    "vitoria_sc": {"name": "吉马良斯", "short_name": "吉马良斯", "league": "primeira_liga", "city": "吉马良斯", "country": "葡萄牙", "stadium": "D·阿方索·恩里克斯球场", "primary_color": "#FFFFFF", "secondary_color": "#000000", "formation": "4-4-2", "rating": 76, "players": []},
    "boavista": {"name": "博阿维斯塔", "short_name": "博阿维斯塔", "league": "primeira_liga", "city": "波尔图", "country": "葡萄牙", "stadium": "贝萨球场", "primary_color": "#000000", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 74, "players": []},

    # 荷甲
    "ajax": {"name": "阿贾克斯", "short_name": "阿贾克斯", "league": "eredivisie", "city": "阿姆斯特丹", "country": "荷兰", "stadium": "克鲁伊夫竞技场", "primary_color": "#D2122E", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 82, "players": []},
    "psv": {"name": "埃因霍温", "short_name": "埃因霍温", "league": "eredivisie", "city": "埃因霍温", "country": "荷兰", "stadium": "飞利浦球场", "primary_color": "#ED1C24", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 83, "players": []},
    "feyenoord": {"name": "费耶诺德", "short_name": "费耶诺德", "league": "eredivisie", "city": "鹿特丹", "country": "荷兰", "stadium": "德库伊普球场", "primary_color": "#E2001A", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 81, "players": []},
    "az_alkmaar": {"name": "阿尔克马尔", "short_name": "AZ", "league": "eredivisie", "city": "阿尔克马尔", "country": "荷兰", "stadium": "AFAS球场", "primary_color": "#E30613", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 78, "players": []},
    "twente": {"name": "特温特", "short_name": "特温特", "league": "eredivisie", "city": "恩斯赫德", "country": "荷兰", "stadium": "德库尔佩尔球场", "primary_color": "#E30613", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 77, "players": []},

    # 土超
    "galatasaray": {"name": "加拉塔萨雷", "short_name": "加拉塔萨雷", "league": "super_lig", "city": "伊斯坦布尔", "country": "土耳其", "stadium": "土耳其电信球场", "primary_color": "#FFB300", "secondary_color": "#E30613", "formation": "4-3-3", "rating": 82, "players": []},
    "fenerbahce": {"name": "费内巴切", "short_name": "费内巴切", "league": "super_lig", "city": "伊斯坦布尔", "country": "土耳其", "stadium": "萨拉科格鲁球场", "primary_color": "#1A237E", "secondary_color": "#FFEB3B", "formation": "4-3-3", "rating": 82, "players": []},
    "besiktas": {"name": "贝西克塔斯", "short_name": "贝西克塔斯", "league": "super_lig", "city": "伊斯坦布尔", "country": "土耳其", "stadium": "沃达丰公园球场", "primary_color": "#000000", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 80, "players": []},
    "trabzonspor": {"name": "特拉布宗体育", "short_name": "特拉布宗", "league": "super_lig", "city": "特拉布宗", "country": "土耳其", "stadium": "帕帕多普洛斯球场", "primary_color": "#7A0000", "secondary_color": "#87CEEB", "formation": "4-4-2", "rating": 78, "players": []},

    # 美职联
    "inter_miami": {"name": "迈阿密国际", "short_name": "迈阿密", "league": "mls", "city": "迈阿密", "country": "美国", "stadium": "DRV PNK球场", "primary_color": "#F7B5CD", "secondary_color": "#000000", "formation": "4-3-3", "rating": 78, "players": []},
    "la_fc": {"name": "洛杉矶FC", "short_name": "LAFC", "league": "mls", "city": "洛杉矶", "country": "美国", "stadium": "加州银行球场", "primary_color": "#000000", "secondary_color": "#C4B456", "formation": "4-3-3", "rating": 80, "players": []},
    "la_galaxy": {"name": "洛杉矶银河", "short_name": "银河", "league": "mls", "city": "洛杉矶", "country": "美国", "stadium": "尊严健康体育公园", "primary_color": "#00245D", "secondary_color": "#FECF09", "formation": "4-3-3", "rating": 77, "players": []},
    "nycfc": {"name": "纽约城FC", "short_name": "纽约城", "league": "mls", "city": "纽约", "country": "美国", "stadium": "洋基球场", "primary_color": "#6CADDF", "secondary_color": "#002B5C", "formation": "4-3-3", "rating": 76, "players": []},

    # 沙特联
    "al_nassr": {"name": "利雅得胜利", "short_name": "利雅得胜利", "league": "saudi_pro_league", "city": "利雅得", "country": "沙特", "stadium": "马尔佐克王子球场", "primary_color": "#FFD700", "secondary_color": "#0066CC", "formation": "4-3-3", "rating": 82, "players": []},
    "al_hilal": {"name": "利雅得新月", "short_name": "利雅得新月", "league": "saudi_pro_league", "city": "利雅得", "country": "沙特", "stadium": "法赫德国王国际球场", "primary_color": "#0066CC", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 83, "players": []},
    "al_ahli": {"name": "吉达联合", "short_name": "吉达联合", "league": "saudi_pro_league", "city": "吉达", "country": "沙特", "stadium": "阿卜杜拉国王体育城", "primary_color": "#008000", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 81, "players": []},
    "al_ittihad": {"name": "吉达国民", "short_name": "吉达国民", "league": "saudi_pro_league", "city": "吉达", "country": "沙特", "stadium": "费萨尔王子球场", "primary_color": "#FFCC00", "secondary_color": "#000000", "formation": "4-4-2", "rating": 82, "players": []},

    # 中超
    "shanghai_port": {"name": "上海海港", "short_name": "海港", "league": "csl", "city": "上海", "country": "中国", "stadium": "浦东足球场", "primary_color": "#E60012", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 75, "players": []},
    "shanghai_shenhua": {"name": "上海申花", "short_name": "申花", "league": "csl", "city": "上海", "country": "中国", "stadium": "虹口足球场", "primary_color": "#0033A0", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 73, "players": []},
    "beijing_guoan": {"name": "北京国安", "short_name": "国安", "league": "csl", "city": "北京", "country": "中国", "stadium": "工人体育场", "primary_color": "#006600", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 74, "players": []},
    "shandong_taishan": {"name": "山东泰山", "short_name": "泰山", "league": "csl", "city": "济南", "country": "中国", "stadium": "济南奥体中心", "primary_color": "#FF6600", "secondary_color": "#000000", "formation": "4-4-2", "rating": 74, "players": []},
    "guangzhou_fc": {"name": "广州队", "short_name": "广州", "league": "csl", "city": "广州", "country": "中国", "stadium": "天河体育中心", "primary_color": "#E60012", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 72, "players": []},
    "wuhan_three_towns": {"name": "武汉三镇", "short_name": "三镇", "league": "csl", "city": "武汉", "country": "中国", "stadium": "武汉体育中心", "primary_color": "#FFD700", "secondary_color": "#E60012", "formation": "4-4-2", "rating": 73, "players": []},

    # 阿甲
    "river_plate": {"name": "河床", "short_name": "河床", "league": "argentine_league", "city": "布宜诺斯艾利斯", "country": "阿根廷", "stadium": "纪念碑球场", "primary_color": "#E30613", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 80, "players": []},
    "boca_juniors": {"name": "博卡青年", "short_name": "博卡", "league": "argentine_league", "city": "布宜诺斯艾利斯", "country": "阿根廷", "stadium": "糖果盒球场", "primary_color": "#0033A0", "secondary_color": "#FFD700", "formation": "4-3-3", "rating": 80, "players": []},
    "racing_club": {"name": "竞技俱乐部", "short_name": "竞技", "league": "argentine_league", "city": "阿韦利亚内达", "country": "阿根廷", "stadium": "胡安·多明戈·庇隆总统球场", "primary_color": "#0033A0", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 77, "players": []},
    "independent": {"name": "独立队", "short_name": "独立", "league": "argentine_league", "city": "阿韦利亚内达", "country": "阿根廷", "stadium": "美洲解放者球场", "primary_color": "#E30613", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 76, "players": []},

    # 巴甲
    "flamengo": {"name": "弗拉门戈", "short_name": "弗拉门戈", "league": "brasileirao", "city": "里约热内卢", "country": "巴西", "stadium": "马拉卡纳球场", "primary_color": "#E30613", "secondary_color": "#000000", "formation": "4-3-3", "rating": 82, "players": []},
    "palmeiras": {"name": "帕尔梅拉斯", "short_name": "帕尔梅拉斯", "league": "brasileirao", "city": "圣保罗", "country": "巴西", "stadium": "帕尔凯安塔蒂卡球场", "primary_color": "#006400", "secondary_color": "#FFFFFF", "formation": "4-3-3", "rating": 82, "players": []},
    "corinthians": {"name": "科林蒂安", "short_name": "科林蒂安", "league": "brasileirao", "city": "圣保罗", "country": "巴西", "stadium": "新化学竞技场", "primary_color": "#000000", "secondary_color": "#FFFFFF", "formation": "4-4-2", "rating": 79, "players": []},
    "sao_paulo": {"name": "圣保罗", "short_name": "圣保罗", "league": "brasileirao", "city": "圣保罗", "country": "巴西", "stadium": "莫伦比球场", "primary_color": "#E30613", "secondary_color": "#000000", "formation": "4-4-2", "rating": 79, "players": []},
}

def main():
    # 读取现有联赛数据
    leagues_path = os.path.join(os.path.dirname(__file__), "..", "data", "leagues.json")
    with open(leagues_path, "r", encoding="utf-8") as f:
        leagues_data = json.load(f)

    # 添加新联赛
    for lid, league in ADDITIONAL_LEAGUES.items():
        leagues_data["leagues"][lid] = league

    with open(leagues_path, "w", encoding="utf-8") as f:
        json.dump(leagues_data, f, ensure_ascii=False, indent=2)
    print(f"已添加 {len(ADDITIONAL_LEAGUES)} 个新联赛")

    # 读取现有球队数据
    teams_path = os.path.join(os.path.dirname(__file__), "..", "data", "teams.json")
    with open(teams_path, "r", encoding="utf-8") as f:
        teams_data = json.load(f)

    # 添加新球队
    for tid, team in ADDITIONAL_TEAMS.items():
        teams_data["clubs"][tid] = team

    with open(teams_path, "w", encoding="utf-8") as f:
        json.dump(teams_data, f, ensure_ascii=False, indent=2)
    print(f"已添加 {len(ADDITIONAL_TEAMS)} 支新球队")

    print(f"\n总计: {len(leagues_data['leagues'])} 个联赛, {len(teams_data['clubs'])} 支俱乐部")

if __name__ == "__main__":
    main()
