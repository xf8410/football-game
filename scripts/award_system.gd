## award_system.gd
## 奖项系统 (Autoload Singleton)
## 与成就不同：奖项是基于比赛表现颁发的荣誉
##
## 奖项类型：
##   1. 个人奖项：金球奖、金靴奖、金手套奖、最佳新人、助攻王
##   2. 团队奖项：联赛冠军、杯赛冠军、世界杯冠军（大力神杯）
##   3. 赛事奖项：欧冠最佳射手、世界杯金球等
extends Node

signal award_earned(award_id: String, player_id: String, season: String)
signal trophy_displayed(award_id: String)

# 奖项定义
const AWARDS = {
	# ---- 个人年度奖项 ----
	"ballon_dor": {
		"name": "金球奖",
		"description": "年度最佳球员",
		"category": "individual_annual",
		"icon": "🥇",
		"color": "#FFD700",
		"prestige": 100,
	},
	"golden_boot": {
		"name": "金靴奖",
		"description": "年度最佳射手",
		"category": "individual_annual",
		"icon": "👟",
		"color": "#FFD700",
		"prestige": 90,
	},
	"fifa_best": {
		"name": "世界足球先生",
		"description": "FIFA年度最佳球员",
		"category": "individual_annual",
		"icon": "🌍",
		"color": "#0066CC",
		"prestige": 95,
	},
	"yashin_trophy": {
		"name": "雅辛奖",
		"description": "年度最佳门将",
		"category": "individual_annual",
		"icon": "🧤",
		"color": "#FFD700",
		"prestige": 80,
	},
	"kopa_trophy": {
		"name": "科帕奖",
		"description": "年度最佳年轻球员（U21）",
		"category": "individual_annual",
		"icon": "🌟",
		"color": "#00AAFF",
		"prestige": 75,
	},
	"playmaker_of_year": {
		"name": "年度助攻王",
		"description": "年度助攻最多球员",
		"category": "individual_annual",
		"icon": "🎯",
		"color": "#00FF00",
		"prestige": 85,
	},

	# ---- 世界杯奖项 ----
	"world_cup_trophy": {
		"name": "大力神杯",
		"description": "世界杯冠军",
		"category": "team_world_cup",
		"icon": "🏆",
		"color": "#FFD700",
		"prestige": 200,
	},
	"world_cup_golden_ball": {
		"name": "世界杯金球奖",
		"description": "世界杯最佳球员",
		"category": "world_cup",
		"icon": "🥇",
		"color": "#FFD700",
		"prestige": 150,
	},
	"world_cup_golden_boot": {
		"name": "世界杯金靴奖",
		"description": "世界杯最佳射手",
		"category": "world_cup",
		"icon": "👟",
		"color": "#FFD700",
		"prestige": 140,
	},
	"world_cup_golden_glove": {
		"name": "世界杯金手套奖",
		"description": "世界杯最佳门将",
		"category": "world_cup",
		"icon": "🧤",
		"color": "#FFD700",
		"prestige": 130,
	},
	"world_cup_best_young": {
		"name": "世界杯最佳新人",
		"description": "世界杯最佳年轻球员",
		"category": "world_cup",
		"icon": "🌟",
		"color": "#00AAFF",
		"prestige": 120,
	},

	# ---- 欧冠奖项 ----
	"ucl_trophy": {
		"name": "欧冠奖杯",
		"description": "欧洲冠军联赛冠军",
		"category": "team_club",
		"icon": "🏆",
		"color": "#FFFFFF",
		"prestige": 180,
	},
	"ucl_top_scorer": {
		"name": "欧冠最佳射手",
		"description": "欧冠进球最多球员",
		"category": "ucl",
		"icon": "👟",
		"color": "#FFFFFF",
		"prestige": 110,
	},
	"ucl_best_player": {
		"name": "欧冠最佳球员",
		"description": "欧冠赛季最佳",
		"category": "ucl",
		"icon": "🥇",
		"color": "#FFFFFF",
		"prestige": 115,
	},

	# ---- 欧联奖项 ----
	"uel_trophy": {
		"name": "欧联奖杯",
		"description": "欧罗巴联赛冠军",
		"category": "team_club",
		"icon": "🏆",
		"color": "#FF6600",
		"prestige": 120,
	},
	"uel_top_scorer": {
		"name": "欧联最佳射手",
		"description": "欧联进球最多球员",
		"category": "uel",
		"icon": "👟",
		"color": "#FF6600",
		"prestige": 80,
	},

	# ---- 联赛奖项 ----
	"league_champion": {
		"name": "联赛冠军",
		"description": "国内联赛冠军",
		"category": "team_club",
		"icon": "🏆",
		"color": "#FFD700",
		"prestige": 100,
	},
	"league_top_scorer": {
		"name": "联赛金靴",
		"description": "联赛最佳射手",
		"category": "league",
		"icon": "👟",
		"color": "#FFD700",
		"prestige": 85,
	},
	"league_best_player": {
		"name": "联赛最佳球员",
		"description": "联赛赛季MVP",
		"category": "league",
		"icon": "🥇",
		"color": "#FFD700",
		"prestige": 90,
	},
	"league_best_gk": {
		"name": "联赛金手套",
		"description": "联赛最佳门将",
		"category": "league",
		"icon": "🧤",
		"color": "#FFD700",
		"prestige": 75,
	},

	# ---- 国内杯赛 ----
	"domestic_cup": {
		"name": "国内杯赛冠军",
		"description": "国内杯赛冠军",
		"category": "team_club",
		"icon": "🏆",
		"color": "#C0C0C0",
		"prestige": 70,
	},
}

# 玩家获得的奖项记录
var earned_awards: Array = []  # [{award_id, player_id, team_id, season, year, description}]

const SAVE_FILE = "user://awards.json"

func _ready():
	load_awards()

## 颁发奖项
func grant_award(award_id: String, player_id: String, team_id: String, season: String, description: String = ""):
	if not AWARDS.has(award_id):
		print("[Award] 未知奖项: " + award_id)
		return

	var record = {
		"award_id": award_id,
		"award_name": AWARDS[award_id].name,
		"player_id": player_id,
		"player_name": PlayerDatabase.get_player_name(player_id) if not player_id.is_empty() else "",
		"team_id": team_id,
		"team_name": TeamDatabase.get_team_name(team_id) if not team_id.is_empty() else "",
		"season": season,
		"year": Time.get_datetime_string_from_system().split(" ")[0],
		"description": description,
		"timestamp": Time.get_unix_time_from_system(),
	}

	earned_awards.append(record)
	save_awards()
	award_earned.emit(award_id, player_id, season)

	var award_name = AWARDS[award_id].name
	var player_name = record.player_name
	var team_name = record.team_name
	print("[Award] 🏆 %s 颁发给: %s (%s) - %s" % [award_name, player_name, team_name, season])

## 根据赛季表现自动颁发奖项
func process_season_awards(season_data: Dictionary):
	var season_id = season_data.get("season_id", "unknown")
	var league_id = season_data.get("league_id", "")

	# 联赛冠军
	var standings = season_data.get("standings", [])
	if standings.size() > 0:
		var champion = standings[0].team_id
		grant_award("league_champion", "", champion, season_id, "联赛冠军")

	# 联赛金靴
	var top_scorer = season_data.get("top_scorer", {})
	if not top_scorer.is_empty():
		grant_award("league_top_scorer", top_scorer.player_id, top_scorer.team_id, season_id, "联赛金靴")

	# 联赛最佳门将（失球最少）
	if standings.size() > 0:
		var best_gk_team = standings[0].team_id
		var min_goals_against = INF
		for s in standings:
			if s.goals_against < min_goals_against:
				min_goals_against = s.goals_against
				best_gk_team = s.team_id
		grant_award("league_best_gk", "", best_gk_team, season_id, "联赛金手套")

## 颁发世界杯奖项
func process_world_cup_awards(champion: String, top_scorer: Dictionary, best_player: String, best_gk: String, best_young: String):
	var season = "world_cup_" + str(Time.get_unix_time_from_system())

	# 大力神杯
	grant_award("world_cup_trophy", "", champion, season, "世界杯冠军")

	# 世界杯金球
	if not best_player.is_empty():
		grant_award("world_cup_golden_ball", best_player, champion, season, "世界杯金球奖")

	# 世界杯金靴
	if not top_scorer.is_empty():
		grant_award("world_cup_golden_boot", top_scorer.player_id, top_scorer.team_id, season, "世界杯金靴奖")

	# 世界杯金手套
	if not best_gk.is_empty():
		grant_award("world_cup_golden_glove", best_gk, "", season, "世界杯金手套奖")

	# 世界杯最佳新人
	if not best_young.is_empty():
		grant_award("world_cup_best_young", best_young, "", season, "世界杯最佳新人")

## 颁发欧冠奖项
func process_ucl_awards(champion: String, top_scorer: Dictionary, best_player: String):
	var season = "ucl_" + str(Time.get_unix_time_from_system())
	grant_award("ucl_trophy", "", champion, season, "欧冠冠军")
	if not top_scorer.is_empty():
		grant_award("ucl_top_scorer", top_scorer.player_id, top_scorer.team_id, season, "欧冠最佳射手")
	if not best_player.is_empty():
		grant_award("ucl_best_player", best_player, champion, season, "欧冠最佳球员")

## 获取所有奖项定义
func get_all_awards() -> Dictionary:
	return AWARDS

## 获取已获得的奖项
func get_earned_awards() -> Array:
	return earned_awards

## 获取指定球员的奖项
func get_player_awards(player_id: String) -> Array:
	var result = []
	for award in earned_awards:
		if award.player_id == player_id:
			result.append(award)
	return result

## 获取指定球队的奖项
func get_team_awards(team_id: String) -> Array:
	var result = []
	for award in earned_awards:
		if award.team_id == team_id:
			result.append(award)
	return result

## 获取奖项数量
func get_award_count(award_id: String) -> int:
	var count = 0
	for award in earned_awards:
		if award.award_id == award_id:
			count += 1
	return count

## 获取总奖项数
func get_total_awards() -> int:
	return earned_awards.size()

## 按分类获取奖项
func get_awards_by_category(category: String) -> Array:
	var result = []
	for aid in AWARDS:
		if AWARDS[aid].category == category or AWARDS[aid].category.find(category) >= 0:
			result.append(aid)
	return result

## 保存奖项
func save_awards():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(earned_awards, "  "))
		file.close()

## 加载奖项
func load_awards():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			earned_awards = json.data
		file.close()
	print("[Award] 已加载 %d 个奖项" % earned_awards.size())
