## season_stats.gd
## 赛季统计系统 (Autoload Singleton)
## 记录和展示赛季数据：球队排名、射手榜、助攻榜、胜平负等
extends Node

# 赛季数据
var season_data: Dictionary = {
	"season_id": "",
	"league_id": "",
	"matches": [],           # 所有比赛记录
	"team_stats": {},        # 球队统计
	"player_stats": {},      # 球员统计（射手榜/助攻榜）
	"start_date": "",
}

## 开始新赛季
func start_season(league_id: String):
	season_data = {
		"season_id": "season_" + str(Time.get_unix_time_from_system()),
		"league_id": league_id,
		"matches": [],
		"team_stats": {},
		"player_stats": {},
		"start_date": Time.get_datetime_string_from_system(),
	}

	# 初始化所有球队统计
	var teams = TeamDatabase.get_clubs_by_league(league_id)
	for tid in teams:
		season_data.team_stats[tid] = _create_team_stat(tid)

## 创建球队统计
func _create_team_stat(team_id: String) -> Dictionary:
	return {
		"team_id": team_id,
		"played": 0, "won": 0, "drawn": 0, "lost": 0,
		"goals_for": 0, "goals_against": 0, "points": 0,
		"clean_sheets": 0, "form": [],  # 近5场战绩
	}

## 记录比赛结果
func record_match(home_id: String, away_id: String, home_goals: int, away_goals: int, scorers: Array = []):
	var match_record = {
		"home": home_id, "away": away_id,
		"home_goals": home_goals, "away_goals": away_goals,
		"scorers": scorers,  # [{player_id, team, minute, type}]
		"timestamp": Time.get_datetime_string_from_system(),
	}
	season_data.matches.append(match_record)

	# 更新球队统计
	_update_team_stat(home_id, home_goals, away_goals)
	_update_team_stat(away_id, away_goals, home_goals)

	# 更新球员统计（射手榜）
	for scorer in scorers:
		_update_player_stat(scorer.player_id, scorer.team, "goal")

## 更新球队统计
func _update_team_stat(team_id: String, goals_for: int, goals_against: int):
	if not season_data.team_stats.has(team_id):
		season_data.team_stats[team_id] = _create_team_stat(team_id)

	var stat = season_data.team_stats[team_id]
	stat.played += 1
	stat.goals_for += goals_for
	stat.goals_against += goals_against

	if goals_for > goals_against:
		stat.won += 1
		stat.points += 3
		stat.form.append("W")
	elif goals_for == goals_against:
		stat.drawn += 1
		stat.points += 1
		stat.form.append("D")
	else:
		stat.lost += 1
		stat.form.append("L")

	# 保持近5场
	if stat.form.size() > 5:
		stat.form = stat.form.slice(stat.form.size() - 5)

	# 零封
	if goals_against == 0:
		stat.clean_sheets += 1

## 更新球员统计
func _update_player_stat(player_id: String, team_id: String, stat_type: String):
	var key = player_id
	if not season_data.player_stats.has(key):
		season_data.player_stats[key] = {
			"player_id": player_id,
			"team_id": team_id,
			"goals": 0, "assists": 0, "appearances": 0,
		}

	match stat_type:
		"goal":
			season_data.player_stats[key].goals += 1
		"assist":
			season_data.player_stats[key].assists += 1
		"appearance":
			season_data.player_stats[key].appearances += 1

## 获取积分榜（排序后）
func get_league_table() -> Array:
	var table = season_data.team_stats.values()
	table.sort_custom(func(a, b):
		if a.points != b.points:
			return a.points > b.points
		var gd_a = a.goals_for - a.goals_against
		var gd_b = b.goals_for - b.goals_against
		if gd_a != gd_b:
			return gd_a > gd_b
		return a.goals_for > b.goals_for
	)
	return table

## 获取射手榜
func get_top_scorers(limit: int = 10) -> Array:
	var scorers = season_data.player_stats.values()
	scorers.sort_custom(func(a, b): return a.goals > b.goals)
	return scorers.slice(0, min(limit, scorers.size()))

## 获取助攻榜
func get_top_assists(limit: int = 10) -> Array:
	var assisters = season_data.player_stats.values()
	assisters.sort_custom(func(a, b): return a.assists > b.assists)
	return assisters.slice(0, min(limit, assisters.size()))

## 获取球队近期战绩
func get_team_form(team_id: String) -> Array:
	if not season_data.team_stats.has(team_id):
		return []
	return season_data.team_stats[team_id].form

## 获取赛季总进球数
func get_total_goals() -> int:
	var total = 0
	for stat in season_data.team_stats.values():
		total += stat.goals_for
	return total

## 获取赛季总比赛数
func get_total_matches() -> int:
	return season_data.matches.size()

## 获取平均进球数
func get_avg_goals_per_match() -> float:
	var total = get_total_matches()
	if total == 0:
		return 0.0
	return float(get_total_goals()) / total

## 保存赛季数据
func save_season():
	var file = FileAccess.open("user://season_stats.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(season_data, "  "))
		file.close()

## 加载赛季数据
func load_season():
	var file = FileAccess.open("user://season_stats.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			season_data = json.data
		file.close()
	return season_data.season_id != ""
